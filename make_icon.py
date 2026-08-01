#!/usr/bin/env python3
"""Bold single-emblem app icon for Ô Ăn Quan: one oversized "quan" stone (the large
mandarin stone from the game's two end cells) dominant in the frame, with a curved trail
of smaller "dân" stones arcing toward it — evoking the actual "rải" (sowing) action of
dropping stones one by one around the board, rather than a static decorative ring. Every
stone (big and small) gets the same radial highlight-upper-left shading plus a soft drop
shadow for real dimensionality, on a warm wood-brown gradient evoking a wooden board.
"""

import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), "#2a1a0a")
draw = ImageDraw.Draw(img)

# --- Background: warm wood-brown gradient (top -> bottom), same palette as before. ---
top = (78, 49, 25)      # warm wood brown
bottom = (22, 13, 7)     # near-black brown
for y in range(SIZE):
    t = y / SIZE
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

cx, cy = SIZE * 0.585, SIZE * 0.465  # big stone dominant, right-of-center, room for the trail

# Soft radial vignette for depth (darken corners slightly, warm glow behind the hero stone).
vignette = Image.new("L", (SIZE, SIZE), 0)
vdraw = ImageDraw.Draw(vignette)
max_r = SIZE * 0.85
for i in range(60):
    t = i / 59
    rad = max_r * (1 - t)
    alpha = int(75 * t)
    vdraw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=alpha)
dark_layer = Image.new("RGB", (SIZE, SIZE), (10, 6, 3))
img = Image.composite(img, dark_layer, vignette.point(lambda v: 255 - v))

# A warm glow directly behind the big stone so it pops off the background.
glow = Image.new("L", (SIZE, SIZE), 0)
gdraw = ImageDraw.Draw(glow)
glow_r = SIZE * 0.42
gdraw.ellipse([cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r], fill=90)
glow = glow.filter(ImageFilter.GaussianBlur(SIZE * 0.09))
glow_layer = Image.new("RGB", (SIZE, SIZE), (150, 108, 46))
img = Image.composite(glow_layer, img, glow)

img = img.convert("RGBA")


def draw_stone(base_rgba, ccx, ccy, radius, hi, mid, dark, outline, outline_w,
               offset_frac=0.20, steps=36, shadow=True):
    """Draw one dimensional 'stone': soft drop shadow + radial gradient (highlight
    upper-left, consistent light source) + crisp dark rim for definition at small sizes."""
    if shadow:
        shadow_layer = Image.new("RGBA", base_rgba.size, (0, 0, 0, 0))
        sdw = ImageDraw.Draw(shadow_layer)
        off = radius * 0.14
        sdw.ellipse([ccx - radius + off, ccy - radius + off * 1.6,
                     ccx + radius + off, ccy + radius + off * 1.6],
                    fill=(0, 0, 0, 130))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius * 0.18))
        base_rgba.alpha_composite(shadow_layer)

    stone_layer = Image.new("RGBA", base_rgba.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(stone_layer)
    for i in range(steps, 0, -1):
        t = i / steps  # 1 = outer rim, ->0 = highlight core
        rad = radius * t
        rr = int(dark[0] + (hi[0] - dark[0]) * (1 - t))
        gg = int(dark[1] + (hi[1] - dark[1]) * (1 - t))
        bb = int(dark[2] + (hi[2] - dark[2]) * (1 - t))
        offx = -radius * offset_frac * (1 - t)
        offy = -radius * offset_frac * (1 - t)
        sdraw.ellipse([ccx - rad + offx, ccy - rad + offy,
                        ccx + rad + offx, ccy + rad + offy],
                       fill=(rr, gg, bb, 255))
    sdraw.ellipse([ccx - radius, ccy - radius, ccx + radius, ccy + radius],
                  outline=outline, width=outline_w)
    base_rgba.alpha_composite(stone_layer)


# --- Small "dân" stones: a bold diagonal trail of large, confidently-shaded stones
# sweeping in from the bottom-left corner toward the big quan stone, as if mid-"rải"
# (sown one by one, closest-to-hand largest, tapering into the distance toward the
# stone) — a directional story instead of a static evenly-spaced halo, and it fills the
# lower-left of the frame that would otherwise read as empty background. Few, but big,
# so every stone still reads clearly at small icon sizes. ---

cream_hi = (251, 228, 180)
cream_mid = (216, 180, 122)
cream_dark = (142, 104, 58)
cream_outline = (84, 58, 28, 255)

r_big = SIZE * 0.335


def bezier(t, p0, p1, p2, p3):
    mt = 1 - t
    x = (mt**3) * p0[0] + 3 * (mt**2) * t * p1[0] + 3 * mt * (t**2) * p2[0] + (t**3) * p3[0]
    y = (mt**3) * p0[1] + 3 * (mt**2) * t * p1[1] + 3 * mt * (t**2) * p2[1] + (t**3) * p3[1]
    return x, y

# Control points (fractional 0..1 coords): bottom-left corner sweeping up into the big
# stone's upper-left flank, so the last stone tucks just beside the hero rather than
# piling messily on top of it.
p0 = (0.10, 0.90)
p1 = (0.03, 0.50)
p2 = (0.11, 0.17)
p3 = (0.28, 0.155)

trail_ts = [0.0, 0.20, 0.40, 0.60, 0.80, 1.0]
sizes = [0.088, 0.078, 0.068, 0.059, 0.051, 0.045]
for t, sfrac in zip(trail_ts, sizes):
    sx, sy = bezier(t, p0, p1, p2, p3)
    sx, sy = sx * SIZE, sy * SIZE
    r_small = SIZE * sfrac
    draw_stone(img, sx, sy, r_small, cream_hi, cream_mid, cream_dark,
               cream_outline, max(4, int(r_small * 0.09)), offset_frac=0.24, steps=32)

# Two loose stray stones tucked in the gaps beside the trail (just spilled, not yet in
# line) — organic scatter, not a second symmetric arm, placed clear of the main chain.
extra = [(0.20, 0.78, 0.032), (0.03, 0.58, 0.028)]
for fx, fy, sfrac in extra:
    sx, sy = fx * SIZE, fy * SIZE
    r_small = SIZE * sfrac
    draw_stone(img, sx, sy, r_small, cream_hi, cream_mid, cream_dark,
               cream_outline, max(3, int(r_small * 0.09)), offset_frac=0.24, steps=24)

# --- The big "quan" stone: the unambiguous hero, large and dominant, right-of-center and
# filling most of the frame, close to the top and right edges. ---
gold_hi = (248, 214, 138, 255)
gold_mid = (216, 170, 86, 255)
gold_dark = (132, 92, 38, 255)
draw_stone(img, cx, cy, r_big, gold_hi[:3], gold_mid[:3], gold_dark[:3],
           (86, 58, 24, 255), 12, offset_frac=0.20, steps=44)

img = img.convert("RGB")
img.save("/Users/q/Projects/OAnQuan/OAnQuan/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("wrote AppIcon.png", img.size)
