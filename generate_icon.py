from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), "#1D2124")
draw = ImageDraw.Draw(img)

cx, cy = SIZE // 2, SIZE // 2 - 20

# Flat halo rings (no gradients) suggesting the glow-dimming metaphor:
# outer cool ring, inner warm core, split visually left(warm)/right(cool).
draw.ellipse([cx - 420, cy - 420, cx + 420, cy + 420], fill="#2A3038")
draw.ellipse([cx - 340, cy - 340, cx + 340, cy + 340], fill="#333A44")

# Bulb body: rounded shape filling ~65% of tile.
bulb_r = 280
draw.ellipse([cx - bulb_r, cy - bulb_r - 40, cx + bulb_r, cy + bulb_r - 40], fill="#F2C86E")

# Cool half overlay (right side) — flat shape, no gradient, showing the
# warm-to-cool dimming metaphor baked directly into the icon.
draw.pieslice([cx - bulb_r, cy - bulb_r - 40, cx + bulb_r, cy + bulb_r - 40], -90, 90, fill="#5E82A8")

# Bulb screw base (flat dark shape at bottom).
base_w = 160
base_top = cy + bulb_r - 100
draw.rectangle([cx - base_w // 2, base_top, cx + base_w // 2, base_top + 140], fill="#171A1D")
for i in range(3):
    y = base_top + 30 + i * 35
    draw.rectangle([cx - base_w // 2, y, cx + base_w // 2, y + 14], fill="#0E1012")

# Filament: simple bold zigzag line through the center, dark on warm side,
# light on cool side, to read clearly at small sizes.
filament = [
    (cx - 90, cy - 160),
    (cx - 20, cy - 20),
    (cx - 70, cy - 20),
    (cx + 10, cy + 140),
]
draw.line(filament, fill="#171A1D", width=26, joint="curve")
draw.line([(pt[0]+4, pt[1]) for pt in filament], fill="#0E1012", width=8, joint="curve")

img.save("/tmp/beacon_icon.png")
print("saved")
