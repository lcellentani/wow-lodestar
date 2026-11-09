"""Draw the threat pin textures (notes/spec-5.4-threat-markers.md, and the two-size pins in
notes/label-style-exploration-2026-11-08.md, "Current choice").

Every file is white with the shape in the alpha channel, tinted in game with SetVertexColor
(P46). New files need a client restart; changed ones reload on /reload.

Shared by both pin sizes (the shapes scale cleanly from 64 pixels down to 30 or 22):

  threat-disc.tga               64x64   filled disc: the edge (fit color) and the dark plate
  threat-skull.tga              64x64   flat skull: the fit-colored symbol
  threat-tab.tga                64x32   today's tab, stretched to 24x18 (kept until the new
                                        pins replace it)

One set per pin size (small map, maximized map), drawn one texture pixel per screen pixel,
because a sliced texture draws its margins at their own size (P57):

  threat-tab-<size>.tga         16x16   rounded rectangle for the range tab, the edge and the
                                        dark plate; slice margins TAB_SLICE on all four sides
  threat-shadow-disc-<size>.tga 64x64   the disc's soft shadow, drawn at 64x64 on the disc's
                                        center, moved SHADOW_DROP pixels down
  threat-shadow-tab-<size>.tga  64x64   the tab's soft shadow; drawn SHADOW_PAD pixels wider
                                        than the tab on each side and 64 high, centered on the
                                        tab and moved SHADOW_DROP down; slice margins
                                        (SHADOW_SLICE, 16, SHADOW_SLICE, 16)

The shadows carry their opacity (SHADOW_ALPHA) in the alpha channel: tint them black.

With --preview=<file.png>, it also renders both pins as the template would compose them
(shadows, edges, plates 1 edge smaller, skull, tab at a sample range width) in three fit
colors on parchment, at --scale pixels per screen pixel. The range is a FontString in game,
so the preview leaves the tab empty.

Usage: python scripts/make_marker_art.py <outdir> [--preview=<file.png>] [--scale=6]
"""
import math
import struct
import sys
import zlib

SS = 4  # supersamples per axis for anti-aliased edges

# Pin layout in screen pixels. "small" is today's Pins.xml pin; "large" is the maximized
# map's (disc 30, skull 20, 3-pixel edge, range 16 pt with 5 pixels above and below).
# tab_h is the tab's outer height: font + 2 * room + 2 * edge. sample_w is the outer tab
# width for a range like "18-34", only for the preview (the game sizes it from the text).
SIZES = {
    "small": dict(disc=22, edge=2, skull=14, tab_h=18, tab_r=3.5, sample_w=36),
    "large": dict(disc=30, edge=3, skull=20, tab_h=32, tab_r=5.0, sample_w=68),
}
TAB_OVERLAP = 1   # the tab's top overlaps the disc by 1 pixel
TAB_TEX = 16      # sliced tab texture, 16x16

SHADOW_BLUR = 5.0                            # Gaussian sigma in pixels (the mockup's "5 px")
SHADOW_PAD = math.ceil(2.6 * SHADOW_BLUR)    # 13: blur reach kept around a shape
SHADOW_DROP = 0.3 * SHADOW_BLUR              # 1.5 pixels down, as in the mockup
SHADOW_ALPHA = 0.75
SHADOW_TEX = 64

PLATE = (0.1, 0.08, 0.05)
PARCHMENT = (0.80, 0.66, 0.40)
SHADOW = (0.0, 0.0, 0.0)
# Roughly what GetQuestDifficultyColor returns: red, yellow, green.
FITS = [(1.0, 0.1, 0.1), (1.0, 1.0, 0.0), (0.25, 0.75, 0.25)]


def tab_slice(size):
    """Slice margin of the size's tab texture: its corner radius, rounded up."""
    return math.ceil(SIZES[size]["tab_r"])


def shadow_slice(size):
    """Side slice margin of the tab shadow: the blur reach plus the corner."""
    return SHADOW_PAD + tab_slice(size)


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


def blur(alpha, sigma):
    """Separable Gaussian blur; outside the image counts as empty."""
    reach = math.ceil(3 * sigma)
    kernel = [math.exp(-(k * k) / (2 * sigma * sigma)) for k in range(-reach, reach + 1)]
    total = sum(kernel)
    kernel = [k / total for k in kernel]
    h, w = len(alpha), len(alpha[0])

    def run(get, n, length):
        return [sum(kernel[k + reach] * get(n, i + k) for k in range(-reach, reach + 1)
                    if 0 <= i + k < length) for i in range(length)]

    rows = [run(lambda j, i: alpha[j][i], j, w) for j in range(h)]
    cols = [run(lambda i, j: rows[j][i], i, h) for i in range(w)]
    return [[cols[i][j] for i in range(w)] for j in range(h)]


def placed(shape, left, top, w, h, tex):
    """A shape of w x h pixels at (left, top) inside a tex x tex texture, as a unit shape."""
    return lambda x, y: (0 <= x * tex - left <= w and 0 <= y * tex - top <= h
                         and shape((x * tex - left) / w, (y * tex - top) / h))


def tab_art(size):
    r = SIZES[size]["tab_r"]
    return coverage(lambda x, y: rounded_rect(x, y, TAB_TEX, TAB_TEX, r), TAB_TEX, TAB_TEX)


def shadow_disc_art(size):
    d = SIZES[size]["disc"]
    off = (SHADOW_TEX - d) / 2
    sil = coverage(placed(disc, off, off, d, d, SHADOW_TEX), SHADOW_TEX, SHADOW_TEX)
    return [[a * SHADOW_ALPHA for a in line] for line in blur(sil, SHADOW_BLUR)]


def shadow_tab_art(size):
    s = SIZES[size]
    w, h = SHADOW_TEX - 2 * SHADOW_PAD, s["tab_h"]
    top = (SHADOW_TEX - h) / 2
    shape = placed(lambda x, y: rounded_rect(x, y, w, h, s["tab_r"]), SHADOW_PAD, top, w, h, SHADOW_TEX)
    sil = coverage(shape, SHADOW_TEX, SHADOW_TEX)
    return [[a * SHADOW_ALPHA for a in line] for line in blur(sil, SHADOW_BLUR)]


def write_tga(path, alpha):
    h, w = len(alpha), len(alpha[0])
    # 32-bit uncompressed, top-left origin (descriptor 0x28), as Media/probe-white.tga.
    data = bytearray([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                      w & 255, w >> 8, h & 255, h >> 8, 32, 0x28])
    for line in alpha:
        for a in line:
            data += bytes([255, 255, 255, round(min(max(a, 0), 1) * 255)])
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


# Preview: blend shapes or textures onto a canvas at scale pixels per screen pixel.

def blend(canvas, j, i, color, a):
    if a > 0 and 0 <= j < len(canvas) and 0 <= i < len(canvas[0]):
        r, g, b = canvas[j][i]
        canvas[j][i] = (r + (color[0] - r) * a, g + (color[1] - g) * a, b + (color[2] - b) * a)


def paint(canvas, shape, left, top, w, h, color, scale):
    """Blend a shape, placed in screen pixels."""
    x0, y0 = round(left * scale), round(top * scale)
    pw, ph = round(w * scale), round(h * scale)
    for j, line in enumerate(coverage(shape, pw, ph)):
        for i, a in enumerate(line):
            blend(canvas, y0 + j, x0 + i, color, a)


def slice_map(d, size, tex, margin):
    """Texture coordinate for d pixels into a sliced span of size pixels (margins 1:1)."""
    if d < margin:
        return d
    if d > size - margin:
        return tex - (size - d)
    return margin + (d - margin) * (tex - 2 * margin) / max(size - 2 * margin, 1e-9)


def sample(alpha, u, v):
    """Bilinear alpha at texture pixel coordinates (pixel centers at +0.5)."""
    h, w = len(alpha), len(alpha[0])
    u, v = min(max(u - 0.5, 0), w - 1), min(max(v - 0.5, 0), h - 1)
    i, j = min(int(u), w - 2), min(int(v), h - 2)
    fu, fv = u - i, v - j
    top = alpha[j][i] * (1 - fu) + alpha[j][i + 1] * fu
    bottom = alpha[j + 1][i] * (1 - fu) + alpha[j + 1][i + 1] * fu
    return top * (1 - fv) + bottom * fv


def paint_texture(canvas, alpha, left, top, w, h, color, scale, mx=0, my=0):
    """Blend a texture drawn w x h at (left, top), sliced with margins mx (sides) and my."""
    th, tw = len(alpha), len(alpha[0])
    x0, y0 = round(left * scale), round(top * scale)
    for j in range(round(h * scale)):
        dy = (j + 0.5) / scale
        v = slice_map(dy, h, th, my) if my else dy * th / h
        for i in range(round(w * scale)):
            dx = (i + 0.5) / scale
            u = slice_map(dx, w, tw, mx) if mx else dx * tw / w
            blend(canvas, y0 + j, x0 + i, color, sample(alpha, u, v))


def draw_pin(canvas, size, cx, top, color, scale, art):
    s = SIZES[size]
    d, e, tw, th = s["disc"], s["edge"], s["sample_w"], s["tab_h"]
    left, tab_left, tab_top = cx - d / 2, cx - tw / 2, top + d - TAB_OVERLAP
    m = tab_slice(size)
    # Shadows: two pieces, the disc's and the tab's, as the game would layer them.
    paint_texture(canvas, art["shadow-disc"], cx - SHADOW_TEX / 2, top + d / 2 - SHADOW_TEX / 2 + SHADOW_DROP,
                  SHADOW_TEX, SHADOW_TEX, SHADOW, scale)
    paint_texture(canvas, art["shadow-tab"], tab_left - SHADOW_PAD, tab_top + th / 2 - SHADOW_TEX / 2 + SHADOW_DROP,
                  tw + 2 * SHADOW_PAD, SHADOW_TEX, SHADOW, scale, shadow_slice(size), 16)
    # Edges, then plates one edge smaller, then the skull, as the template's layers.
    paint(canvas, disc, left, top, d, d, color, scale)
    paint_texture(canvas, art["tab"], tab_left, tab_top, tw, th, color, scale, m, m)
    paint(canvas, disc, left + e, top + e, d - 2 * e, d - 2 * e, PLATE, scale)
    paint_texture(canvas, art["tab"], tab_left + e, tab_top + e, tw - 2 * e, th - 2 * e, PLATE, scale, m, m)
    sk = s["skull"]
    paint(canvas, skull, cx - sk / 2, top + (d - sk) / 2, sk, sk, color, scale)


def preview(path, scale, arts):
    row_h = {size: SIZES[size]["disc"] + SIZES[size]["tab_h"] + 2 * SHADOW_PAD for size in SIZES}
    cell_w = max(s["sample_w"] for s in SIZES.values()) + 2 * SHADOW_PAD
    width, height = cell_w * len(FITS), sum(row_h.values())
    canvas = [[PARCHMENT] * round(width * scale) for _ in range(round(height * scale))]
    y = 0
    for size in SIZES:
        for k, color in enumerate(FITS):
            draw_pin(canvas, size, k * cell_w + cell_w / 2, y + SHADOW_PAD, color, scale, arts[size])
        y += row_h[size]
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
    arts = {}
    for size in SIZES:
        arts[size] = {"tab": tab_art(size), "shadow-disc": shadow_disc_art(size), "shadow-tab": shadow_tab_art(size)}
        for name, alpha in arts[size].items():
            write_tga(f"{outdir}/threat-{name}-{size}.tga", alpha)
        print(f"{size}: tab slice {tab_slice(size)}, shadow-tab slice ({shadow_slice(size)}, 16, "
              f"{shadow_slice(size)}, 16), shadow pad {SHADOW_PAD}, drop {SHADOW_DROP}")
    print("wrote threat-disc, threat-tab, threat-skull and the small/large sets to", outdir)
    if "preview" in opts:
        preview(opts["preview"], float(opts.get("scale", 6)), arts)
        print("preview", opts["preview"])


if __name__ == "__main__":
    main()
