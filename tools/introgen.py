#!/usr/bin/env python3
"""Generate gb/src/intro_gfx.h: the tiles of the intro screen (cat logo,
"Chat-GBC" title, menu frame and cursor) as 8x8 2bpp Game Boy tiles plus the
tile maps of the logo and the title. The logo is drawn from a few geometric
shapes, the title and the frame are pixel art below.

The data is a header included by gb/src/intro.c only, so that it always sits
in the same ROM bank as the code that draws it (bankpack assigns banks per
object file). Pure standard library; writes a preview PNG when a path is given.

Run:  python3 tools/introgen.py [preview.png]
"""
import math
import os
import struct
import sys
import zlib

# ---- logo: 112x64 pixels (14x8 tiles), colours 0 (lightest) .. 3 (darkest) ----
LOGO_W, LOGO_H = 112, 64


def dist_seg(px, py, ax, ay, bx, by):
    """distance from (px,py) to the segment a-b"""
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    L = vx * vx + vy * vy
    t = 0.0 if L == 0 else max(0.0, min(1.0, (wx * vx + wy * vy) / L))
    dx, dy = px - (ax + t * vx), py - (ay + t * vy)
    return math.hypot(dx, dy)


def in_ellipse(px, py, cx, cy, rx, ry):
    return ((px - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1.0


def draw_logo():
    img = [[0] * LOGO_W for _ in range(LOGO_H)]

    def paint(color, test):
        for y in range(LOGO_H):
            for x in range(LOGO_W):
                if test(x + 0.5, y + 0.5):
                    img[y][x] = color

    cx, cy = 56.0, 38.0                       # centre of the body
    # rays: rounded strokes radiating from the centre, colour 2
    rays = []
    for i in range(12):
        ang = math.radians(-90 + i * 30 + 15)
        if math.sin(ang) > 0.85:              # no rays behind the paws
            continue
        r0, r1 = 30.0, 60.0
        # keep the rounded end 3 px inside the canvas
        for r in range(int(r1), int(r0), -1):
            ex, ey = cx + r * math.cos(ang), cy + r * math.sin(ang)
            if 3 <= ex <= LOGO_W - 3 and 3 <= ey <= LOGO_H - 3:
                r1 = float(r)
                break
        rays.append((cx + r0 * math.cos(ang), cy + r0 * math.sin(ang),
                     cx + r1 * math.cos(ang), cy + r1 * math.sin(ang)))
    paint(2, lambda x, y: any(dist_seg(x, y, *r) < 2.6 for r in rays))

    # tail: an S curve from the top of the body up to the top edge, outline 3 fill 1
    tail = [(cx + 3, 22), (cx + 6, 16), (cx + 6, 10), (cx + 3, 5.5), (cx - 2, 4.5), (cx - 6, 7)]
    tail_segs = list(zip(tail[:-1], tail[1:]))
    paint(3, lambda x, y: any(dist_seg(x, y, a[0], a[1], b[0], b[1]) < 3.6 for a, b in tail_segs))
    paint(1, lambda x, y: any(dist_seg(x, y, a[0], a[1], b[0], b[1]) < 2.2 for a, b in tail_segs))

    # ears: two triangles, outline 3, dithered inside
    def tri(px, py, a, b, c):
        def sign(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
        d1, d2, d3 = sign((px, py), a, b), sign((px, py), b, c), sign((px, py), c, a)
        return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))
    ears = [((36, 24), (37, 9), (49, 19)), ((76, 24), (75, 9), (63, 19))]
    for e in ears:
        paint(3, lambda x, y, e=e: tri(x, y, *e))
    inner = [((39, 22), (39, 13), (46, 19)), ((73, 22), (73, 13), (66, 19))]
    for e in inner:
        paint(1, lambda x, y, e=e: tri(x, y, *e) and (int(x) + int(y)) % 2 == 0)
        paint(2, lambda x, y, e=e: tri(x, y, *e) and (int(x) + int(y)) % 2 == 1)

    # body: a fat ellipse, outline 3, upper half dithered fur, lower half (the butt) light
    body = (cx, cy, 24.0, 22.0)
    paint(3, lambda x, y: in_ellipse(x, y, *body))
    paint(1, lambda x, y: in_ellipse(x, y, cx, cy, 22.0, 20.0))
    paint(2, lambda x, y: in_ellipse(x, y, cx, cy, 22.0, 20.0) and y < 30 and (int(x) + int(y)) % 2 == 1)
    # the butt: a lighter rounded patch
    paint(0, lambda x, y: in_ellipse(x, y, cx, cy + 6, 15.0, 13.0))
    # the "x"
    paint(3, lambda x, y: (abs((x - cx) - (y - (cy - 2))) < 0.75 or abs((x - cx) + (y - (cy - 2))) < 0.75)
          and abs(x - cx) < 2.5 and abs(y - (cy - 2)) < 2.5)
    # inner legs: a Y shaped shadow below the x
    paint(3, lambda x, y: dist_seg(x, y, cx, cy + 4, cx, cy + 12) < 1.2)
    paint(3, lambda x, y: dist_seg(x, y, cx, cy + 12, cx - 6, cy + 19) < 1.2
          or dist_seg(x, y, cx, cy + 12, cx + 6, cy + 19) < 1.2)
    # paws: two rounded pads with three toe beans each
    for px in (cx - 12, cx + 12):
        paint(3, lambda x, y, px=px: in_ellipse(x, y, px, 56.5, 7.5, 6.5))
        paint(0, lambda x, y, px=px: in_ellipse(x, y, px, 56.5, 5.5, 4.6))
        for tx, ty in ((px - 3.5, 55), (px, 53.5), (px + 3.5, 55)):
            paint(3, lambda x, y, tx=tx, ty=ty: abs(x - tx) < 1 and abs(y - ty) < 1)
        paint(3, lambda x, y, px=px: in_ellipse(x, y, px, 58, 1.8, 1.4))
    return img


# ---- title: "Chat-GBC", 16 rows x 128 columns of pixel art (# = colour 3) ----
TITLE = """
................................................................................................................................
.........###........####..........................................................###...................................###.....
.....###########....####..............................####....................############....############..........###########.
...#############....####.............................#####..................##############.....#############......#############.
..#######....###....####.............................#####.................#######.....###....#####....#####.....#######....###.
..#####.............####.######......##########....###########............######..............#####.....####.....#####..........
.#####..............############.....###########...###########............#####...............#####....#####....#####...........
.#####..............#############....##.....#####...##########............#####...............#############.....#####...........
.#####..............#####...#####............####....#####................####.....#######....#############.....#####...........
.#####..............####.....####.....###########....#####......#######...####.....########...##############....#####...........
.#####..............####.....####....############....#####......#######...#####.......#####...#####.....#####...#####...........
.######.............####.....####...#####....####....#####................#####.......#####...#####.....#####...######..........
..######.......#....####.....####...####....#####....#####.................#####......#####...#####.....#####....######.......#.
...#############....####.....####...#####..######.....#######...............###############....##############.....#############.
....############....####.....####...#############.....########...............#############....##############.......############.
......#########.....####.....####.....#####..####.......######.................#########.......###########...........########...
""".strip("\n").split("\n")

# ---- menu frame (double line, rounded corners) and cursor, one 8x8 tile each ----
FRAME = {
    "tl": ["........", "...#####", "..#.....", ".#..####", ".#.#....", "#..#....", "#..#....", "#..#...."],
    "t":  ["........", "########", "........", "########", "........", "........", "........", "........"],
    "tr": ["........", "#####...", ".....#..", "####..#.", "....#.#.", "....#..#", "....#..#", "....#..#"],
    "l":  ["#..#....", "#..#....", "#..#....", "#..#....", "#..#....", "#..#....", "#..#....", "#..#...."],
    "r":  ["....#..#", "....#..#", "....#..#", "....#..#", "....#..#", "....#..#", "....#..#", "....#..#"],
    "bl": ["#..#....", "#..#....", "#..#....", ".#..####", ".#......", "..#.....", "...#####", "........"],
    "b":  ["........", "........", "........", "########", "........", "########", "........", "........"],
    "br": ["....#..#", "....#..#", "....#..#", "####..#.", "......#.", ".....#..", "#####...", "........"],
    "cur": ["........", "..#.....", "..##....", "..###...", "..####..", "..###...", "..##....", "..#....."],
}
FRAME_ORDER = ["tl", "t", "tr", "l", "r", "bl", "b", "br", "cur"]


def tile_from_pixels(get, x0, y0):
    """8x8 2bpp tile: two bitplanes per row, colour = plane0 | plane1 << 1"""
    out = []
    for y in range(8):
        lo = hi = 0
        for x in range(8):
            c = get(x0 + x, y0 + y)
            if c & 1:
                lo |= 0x80 >> x
            if c & 2:
                hi |= 0x80 >> x
        out += [lo, hi]
    return out


def write_png(path, img, scale=4):
    pal = [(155, 188, 15), (139, 172, 15), (48, 98, 48), (15, 56, 15)]
    h, w = len(img), len(img[0])
    raw = b""
    for y in range(h):
        row = b"\x00"
        for x in range(w):
            row += bytes(pal[img[y][x]]) * scale
        raw += row * scale

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w * scale, h * scale, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    logo = draw_logo()
    assert all(len(r) == 128 for r in TITLE) and len(TITLE) == 16, "TITLE must be 16 rows of 128 columns"

    # unique tiles only; an empty tile is drawn with font tile 0 (space) and
    # marked 0xFF in the maps. Map entries are offsets from the first intro tile.
    uniq, index = [], {}

    def add(tile):
        key = bytes(tile)
        if not any(key):
            return 0xFF
        if key not in index:
            index[key] = len(uniq)
            uniq.append(tile)
        return index[key]

    logo_map = [add(tile_from_pixels(lambda x, y: logo[y][x], tx * 8, ty * 8))
                for ty in range(LOGO_H // 8) for tx in range(LOGO_W // 8)]
    title_map = [add(tile_from_pixels(lambda x, y: 3 if TITLE[y][x] == "#" else 0, tx * 8, ty * 8))
                 for ty in range(2) for tx in range(16)]
    frame_idx = [add(tile_from_pixels(lambda x, y, rows=FRAME[name]: 3 if rows[y][x] == "#" else 0, 0, 0))
                 for name in FRAME_ORDER]
    tiles = [b for t in uniq for b in t]
    n = len(uniq)

    with open(os.path.join(root, "gb/src/intro_gfx.h"), "w") as f:
        f.write("/* Generated by tools/introgen.py - do not edit. Include from gb/src/intro.c only. */\n")
        f.write("#ifndef INTRO_GFX_H\n#define INTRO_GFX_H\n#include <stdint.h>\n\n")
        f.write(f"#define LOGO_TW {LOGO_W // 8}\n#define LOGO_TH {LOGO_H // 8}\n")
        f.write("#define TITLE_TW 16\n#define TITLE_TH 2\n")
        f.write(f"#define INTRO_NTILES {n}\n#define INTRO_EMPTY 0xFF   /* map entry: draw font tile 0 */\n")
        for i, name in enumerate(FRAME_ORDER):
            f.write(f"#define FRAME_{name.upper()} {frame_idx[i]}\n")
        f.write(f"\nstatic const uint8_t intro_tiles[{len(tiles)}] = {{\n")
        for i in range(0, len(tiles), 16):
            f.write("    " + ", ".join(f"0x{b:02X}" for b in tiles[i:i + 16]) + ",\n")
        f.write("};\n\n")
        for name, m, w in (("logo_map", logo_map, LOGO_W // 8), ("title_map", title_map, 16)):
            f.write(f"static const uint8_t {name}[{len(m)}] = {{\n")
            for i in range(0, len(m), w):
                f.write("    " + ", ".join(f"0x{b:02X}" for b in m[i:i + w]) + ",\n")
            f.write("};\n\n")
        f.write("#endif\n")
    print(f"intro: {n} unique tiles ({len(tiles)} bytes) for logo {len(logo_map)} + title {len(title_map)} + frame {len(frame_idx)} cells")

    if len(sys.argv) > 1:
        # preview of the whole screen: logo, title, frame
        scr = [[0] * 160 for _ in range(144)]
        for y in range(LOGO_H):
            for x in range(LOGO_W):
                scr[y][24 + x] = logo[y][x]
        for y in range(16):
            for x in range(128):
                if TITLE[y][x] == "#":
                    scr[72 + y][16 + x] = 3
        def blit(name, tx, ty):
            for y in range(8):
                for x in range(8):
                    if FRAME[name][y][x] == "#":
                        scr[ty * 8 + y][tx * 8 + x] = 3
        blit("tl", 1, 12); blit("tr", 18, 12); blit("bl", 1, 16); blit("br", 18, 16)
        for tx in range(2, 18):
            blit("t", tx, 12); blit("b", tx, 16)
        for ty in range(13, 16):
            blit("l", 1, ty); blit("r", 18, ty)
        blit("cur", 3, 13)
        write_png(sys.argv[1], scr)
        print("preview:", sys.argv[1])


if __name__ == "__main__":
    main()
