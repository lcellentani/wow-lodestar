"""Draw the threat marker textures (notes/spec-5.4-threat-markers.md).

Writes three white .tga files with the shape in the alpha channel, tinted in game with
SetVertexColor (P46):

  threat-disc.tga   64x64  filled disc: the outline (threat color) and the dark plate
  threat-tab.tga    64x32  filled rounded rectangle: the same for the level tab
  threat-skull.tga  64x64  flat skull: the threat-colored symbol

With --preview=<file.png>, it also renders the marker as the pin template composes it
(edge, dark plate 2 pixels smaller, skull, tab) in five threat colors on parchment, at
--scale pixels per screen pixel, to check the look outside the game. The level number is
a FontString in game, so the preview leaves the tab empty.

Usage: python scripts/make_marker_art.py <outdir> [--preview=<file.png>] [--scale=6]
"""
import math
import struct
import sys
import zlib

SS = 4  # supersamples per axis for anti-aliased edges

# Pin layout in screen pixels, as in the spec's Pins.xml table.
DISC = 20
EDGE = 1          # outline width: the dark plate is 1 pixel smaller each way
SKULL = 14
TAB_W, TAB_H = 22, 16
TAB_OVERLAP = 1

PLATE = (0.1, 0.08, 0.05)
PARCHMENT = (0.80, 0.66, 0.40)
# Roughly what GetQuestDifficultyColor returns: red, orange, yellow, green, grey.
THREATS = [(1.0, 0.1, 0.1), (1.0, 0.5, 0.25), (1.0, 1.0, 0.0), (0.25, 0.75, 0.25), (0.5, 0.5, 0.5)]


# Shapes in unit coordinates: x and y from 0 to 1, y pointing down. Each returns True inside.

def disc(x, y):
    return (x - 0.5) ** 2 + (y - 0.5) ** 2 <= 0.5 ** 2


def rounded_rect(x, y, w, h, r):
    """Inside a w x h rectangle (in pixels of the target) with corner radius r."""
    px, py = x * w, y * h
    cx = min(max(px, r), w - r)
    cy = min(max(py, r), h - r)
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r


def tab(x, y):
    return rounded_rect(x, y, 64, 32, 9)


def skull(x, y):
    # The skull chosen in the 2026-11-07 mockups: a dome with straight sides, cheekbones
    # angling in to a square jaw, large low eyes, three teeth, no nose. Drawn in the
    # mockup's units (x -8..8, y -9..7), scaled to fill the texture with a small margin.
    sx = (x * 64 - 32) / 3.6
    sy = (y * 64 - 32) / 3.6 - 1
    ax = abs(sx)
    if sy <= -1:
        inside = sx ** 2 + (sy + 1) ** 2 <= 8 ** 2      # dome
    elif sy <= 2:
        inside = ax <= 8                                 # straight sides
    elif sy <= 4:
        inside = ax <= 8 - (sy - 2) * 1.5                # cheekbones, 8 in to 5
    else:
        inside = sy <= 7 and ax <= 5                     # jaw
    if not inside:
        return False
    eyes = (ax - 3.2) ** 2 + (sy + 0.5) ** 2 <= 2.2 ** 2
    teeth = 4.5 <= sy and min(abs(sx + 2.5), ax, abs(sx - 2.5)) <= 0.55
    return not (eyes or teeth)


def coverage(shape, w, h):
    rows = []
    for j in range(h):
        line = []
        for i in range(w):
            n = 0
            for sj in range(SS):
                for si in range(SS):
                    if shape((i + (si + 0.5) / SS) / w, (j + (sj + 0.5) / SS) / h):
                        n += 1
            line.append(n / (SS * SS))
        rows.append(line)
    return rows


def write_tga(path, alpha):
    h, w = len(alpha), len(alpha[0])
    # 32-bit uncompressed, top-left origin (descriptor 0x28), as Media/probe-white.tga.
    data = bytearray([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                      w & 255, w >> 8, h & 255, h >> 8, 32, 0x28])
    for line in alpha:
        for a in line:
            data += bytes([255, 255, 255, round(a * 255)])
    open(path, "wb").write(data)


def write_png(path, pixels):
    h, w = len(pixels), len(pixels[0])
    raw = bytearray()
    for line in pixels:
        raw.append(0)
        for r, g, b in line:
            raw += bytes([round(r * 255), round(g * 255), round(b * 255)])

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


def paint(canvas, shape, left, top, w, h, color, scale):
    """Blend a shape, placed in screen pixels, onto the canvas at scale pixels per screen pixel."""
    x0, y0 = round(left * scale), round(top * scale)
    pw, ph = round(w * scale), round(h * scale)
    for j, line in enumerate(coverage(shape, pw, ph)):
        for i, a in enumerate(line):
            if a > 0:
                r, g, b = canvas[y0 + j][x0 + i]
                canvas[y0 + j][x0 + i] = (r + (color[0] - r) * a, g + (color[1] - g) * a, b + (color[2] - b) * a)


def preview(path, scale):
    cell_w, cell_h = DISC + 12, DISC + TAB_H + 10
    width, height = cell_w * len(THREATS), cell_h
    canvas = [[PARCHMENT] * round(width * scale) for _ in range(round(height * scale))]
    for k, color in enumerate(THREATS):
        cx, top = k * cell_w + cell_w / 2, 4
        left = cx - DISC / 2
        tab_left, tab_top = cx - TAB_W / 2, top + DISC - TAB_OVERLAP
        paint(canvas, disc, left, top, DISC, DISC, color, scale)
        paint(canvas, tab, tab_left, tab_top, TAB_W, TAB_H, color, scale)
        paint(canvas, disc, left + EDGE, top + EDGE, DISC - 2 * EDGE, DISC - 2 * EDGE, PLATE, scale)
        paint(canvas, tab, tab_left + EDGE, tab_top + EDGE, TAB_W - 2 * EDGE, TAB_H - 2 * EDGE, PLATE, scale)
        paint(canvas, skull, cx - SKULL / 2, top + (DISC - SKULL) / 2, SKULL, SKULL, color, scale)
    write_png(path, canvas)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
    if len(args) != 1:
        sys.exit(__doc__)
    outdir = args[0]
    write_tga(f"{outdir}/threat-disc.tga", coverage(disc, 64, 64))
    write_tga(f"{outdir}/threat-tab.tga", coverage(tab, 64, 32))
    write_tga(f"{outdir}/threat-skull.tga", coverage(skull, 64, 64))
    print("wrote threat-disc, threat-tab, threat-skull to", outdir)
    if "preview" in opts:
        preview(opts["preview"], float(opts.get("scale", 6)))
        print("preview", opts["preview"])


if __name__ == "__main__":
    main()
