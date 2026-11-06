"""Build zone masks for ThreatOverlay from the grid sampled in game (notes/spec-5.1-grid-mask-slice.md).

Reads LodestarDB.grid from the SavedVariables file: one string per grid row, made of
"mapID:count" runs from west to east, 0 meaning no map. Writes one white .tga per zone with
the shape in the alpha channel, and prints each zone's rectangle as fractions of the map.

Usage: python scripts/make_masks.py <Lodestar.lua> <outdir> [mapID[+mergedID...] ...]
With no zones, it only reports the cells per map. "1429+1453" adds the second map's cells
to the first, for a city inside its zone.
"""
import math
import re
import sys

SIZE = 128     # texture side in pixels, a power of two
PAD = 2        # empty grid cells kept around the zone, so the soft edge is not cut off
BLUR = 6       # box blur radius in pixels, smooths the 8-pixel steps of the hover lookup (P50)
SOFT = 0.12    # width of the edge around the 0.5 contour, in blurred coverage


def read_grid(path):
    text = open(path, encoding="utf-8").read()
    start = text.index('["grid"]')
    block = text[start:text.index("}", start)]
    rows = []
    for line in re.findall(r'"([^"]*)"', block)[1:] if block.startswith('["grid"]') else []:
        cells = []
        for run in line.split():
            map_id, count = run.split(":")
            cells += [int(map_id)] * int(count)
        rows.append(cells)
    return rows


def blur_axis(img, radius, horizontal):
    h, w = len(img), len(img[0])
    out = [[0.0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            total = n = 0
            for d in range(-radius, radius + 1):
                xx, yy = (x + d, y) if horizontal else (x, y + d)
                if 0 <= xx < w and 0 <= yy < h:
                    total += img[yy][xx]
                    n += 1
            out[y][x] = total / n
    return out


def smoothstep(v):
    t = min(1.0, max(0.0, (v - (0.5 - SOFT)) / (2 * SOFT)))
    return t * t * (3 - 2 * t)


def build_mask(rows, ids):
    n = len(rows)
    hits = [(x, y) for y in range(n) for x in range(len(rows[y])) if rows[y][x] in ids]
    x0 = max(0, min(p[0] for p in hits) - PAD)
    x1 = min(n - 1, max(p[0] for p in hits) + PAD)
    y0 = max(0, min(p[1] for p in hits) - PAD)
    y1 = min(n - 1, max(p[1] for p in hits) + PAD)
    w, h = x1 - x0 + 1, y1 - y0 + 1

    def cell(x, y):
        x = min(w - 1, max(0, x))
        y = min(h - 1, max(0, y))
        return 1.0 if rows[y0 + y][x0 + x] in ids else 0.0

    img = []
    for py in range(SIZE):
        fy = (py + 0.5) / SIZE * h - 0.5
        iy = math.floor(fy)
        ty = fy - iy
        line = []
        for px in range(SIZE):
            fx = (px + 0.5) / SIZE * w - 0.5
            ix = math.floor(fx)
            tx = fx - ix
            top = cell(ix, iy) * (1 - tx) + cell(ix + 1, iy) * tx
            bottom = cell(ix, iy + 1) * (1 - tx) + cell(ix + 1, iy + 1) * tx
            line.append(top * (1 - ty) + bottom * ty)
        img.append(line)
    img = blur_axis(blur_axis(img, BLUR, True), BLUR, False)
    alpha = [[smoothstep(v) for v in line] for line in img]
    rect = (x0 / n, y0 / n, w / n, h / n)
    return alpha, rect


def write_tga(path, alpha):
    h, w = len(alpha), len(alpha[0])
    header = bytes([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    w & 255, w >> 8, h & 255, h >> 8, 32, 0x28])
    data = bytearray(header)
    for line in alpha:
        for a in line:
            data += bytes([255, 255, 255, round(a * 255)])
    open(path, "wb").write(data)


def main():
    rows = read_grid(sys.argv[1])
    counts = {}
    for line in rows:
        for map_id in line:
            counts[map_id] = counts.get(map_id, 0) + 1
    print("rows", len(rows), "widths", sorted({len(r) for r in rows}))
    for map_id, count in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(map_id, count)
    for spec in sys.argv[3:]:
        ids = {int(part) for part in spec.split("+")}
        name = spec.split("+")[0]
        alpha, rect = build_mask(rows, ids)
        write_tga(f"{sys.argv[2]}/mask-{name}.tga", alpha)
        print(f"mask-{name}: x={rect[0]:.5f} y={rect[1]:.5f} w={rect[2]:.5f} h={rect[3]:.5f}")


if __name__ == "__main__":
    main()
