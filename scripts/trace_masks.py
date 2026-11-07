"""Trace zone masks from screenshots of Blizzard's highlight art (notes/spec-5.2-traced-mask-slice.md).

Each screenshot shows one zone's art inside a magenta frame. The script finds the frame, takes the
art's brightness inside it, turns that into a white .tga with the shape in the alpha channel, and
prints the zone's rectangle on the map from LodestarDB.art in the SavedVariables file.

The output derives from Blizzard's art, so it goes to the git-ignored Media/traced/ only.

Usage: python scripts/trace_masks.py <Lodestar.lua> <outdir> <mapID>=<screenshot.png> ...
"""
import re
import struct
import sys
import zlib

SIZE = 128      # texture side in pixels, a power of two
EDGE = 0.5      # contour, as a fraction of the brightest pixel
SOFT = 0.15     # width of the soft edge around the contour


def read_png(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat = 8, b""
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            w, h, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", body)
            assert depth == 8 and color in (2, 6) and interlace == 0, "needs 8-bit RGB(A), not interlaced"
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    bpp = 3 if color == 2 else 4
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        filt, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if filt == 1:
                line[x] = (line[x] + a) & 255
            elif filt == 2:
                line[x] = (line[x] + b) & 255
            elif filt == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif filt == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append([tuple(line[x:x + 3]) for x in range(0, stride, bpp)])
        prev = line
    return rows


def is_magenta(p):
    r, g, b = p
    return r > 200 and b > 200 and g < 80


def art_box(img):
    """Inner edges of the magenta frame: the art fills exactly that box."""
    h, w = len(img), len(img[0])
    ys = [y for y in range(h) if sum(is_magenta(p) for p in img[y]) > w // 4]
    xs = [x for x in range(w) if sum(is_magenta(img[y][x]) for y in range(h)) > h // 4]
    top, bottom, left, right = min(ys), max(ys), min(xs), max(xs)
    cy, cx = (top + bottom) // 2, (left + right) // 2
    x0 = left
    while is_magenta(img[cy][x0]):
        x0 += 1
    x1 = right
    while is_magenta(img[cy][x1]):
        x1 -= 1
    y0 = top
    while is_magenta(img[y0][cx]):
        y0 += 1
    y1 = bottom
    while is_magenta(img[y1][cx]):
        y1 -= 1
    return x0 + 1, y0 + 1, x1 - 1, y1 - 1   # one pixel in, away from the blended edge


def mask_from(img, box):
    x0, y0, x1, y1 = box
    light = [[max(img[y][x]) for x in range(x0, x1 + 1)] for y in range(y0, y1 + 1)]
    peak = max(max(line) for line in light) or 1
    h, w = len(light), len(light[0])
    out = []
    for py in range(SIZE):
        fy = min(h - 1.001, (py + 0.5) / SIZE * h - 0.5)
        iy, ty = int(max(0, fy)), max(0, fy) - int(max(0, fy))
        line = []
        for px in range(SIZE):
            fx = min(w - 1.001, (px + 0.5) / SIZE * w - 0.5)
            ix, tx = int(max(0, fx)), max(0, fx) - int(max(0, fx))
            v = (light[iy][ix] * (1 - tx) + light[iy][ix + 1] * tx) * (1 - ty) + \
                (light[iy + 1][ix] * (1 - tx) + light[iy + 1][ix + 1] * tx) * ty
            t = min(1.0, max(0.0, (v / peak - (EDGE - SOFT)) / (2 * SOFT)))
            line.append(t * t * (3 - 2 * t))
        out.append(line)
    return out, peak


def write_tga(path, alpha):
    h, w = len(alpha), len(alpha[0])
    data = bytearray([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, w & 255, w >> 8, h & 255, h >> 8, 32, 0x28])
    for line in alpha:
        for a in line:
            data += bytes([255, 255, 255, round(a * 255)])
    open(path, "wb").write(data)


def read_rects(path):
    text = open(path, encoding="utf-8").read()
    block = text[text.index('["art"]'):]
    rects = {}
    for map_id, body in re.findall(r"\[(\d+)\] = \{([^}]*)\}", block):
        nums = [float(n) for n in re.findall(r"-?\d+\.?\d*(?:e-?\d+)?", body)]
        rects[int(map_id)] = nums[:4]
    return rects


def main():
    rects = read_rects(sys.argv[1])
    for spec in sys.argv[3:]:
        map_id, png = spec.split("=", 1)
        map_id = int(map_id)
        img = read_png(png)
        box = art_box(img)
        alpha, peak = mask_from(img, box)
        write_tga(f"{sys.argv[2]}/mask-{map_id}.tga", alpha)
        w, h, x, y = rects[map_id]
        print(f"mask-{map_id}: box {box} peak {peak} -> x={x:.5f} y={y:.5f} w={w:.5f} h={h:.5f}")


if __name__ == "__main__":
    main()
