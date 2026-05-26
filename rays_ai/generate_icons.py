"""
Generate proper launcher icons for Rakshak AI.
Creates ic_launcher.png and ic_launcher_foreground.png at all density buckets.
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

BASE = r"d:\RAY\rakshak_ai\android\app\src\main\res"

# Android mipmap sizes: ic_launcher = 48dp base
DENSITIES = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}

# Adaptive icon foreground is 108dp base
FG_DENSITIES = {
    "mipmap-mdpi":    108,
    "mipmap-hdpi":    162,
    "mipmap-xhdpi":   216,
    "mipmap-xxhdpi":  324,
    "mipmap-xxxhdpi": 432,
}

BG_COLOR = (26, 26, 46)       # #1A1A2E - dark navy
ACCENT   = (0, 180, 216)      # #00B4D8 - cyber blue
WHITE    = (255, 255, 255)

def draw_shield(draw, cx, cy, size, fill_color, outline_color):
    """Draw a simple shield shape."""
    s = size
    # Shield points (top-left, top-right, right-mid, bottom-point, left-mid)
    points = [
        (cx - s*0.4, cy - s*0.4),   # top left
        (cx + s*0.4, cy - s*0.4),   # top right
        (cx + s*0.4, cy + s*0.05),  # right mid
        (cx, cy + s*0.45),          # bottom point
        (cx - s*0.4, cy + s*0.05),  # left mid
    ]
    draw.polygon(points, fill=fill_color, outline=outline_color)

def draw_icon(size, for_foreground=False):
    """Create a Rakshak AI icon at the given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2

    if not for_foreground:
        # For ic_launcher: draw full icon with background
        # Round rect background
        margin = int(size * 0.05)
        radius = int(size * 0.2)
        draw.rounded_rectangle(
            [margin, margin, size - margin, size - margin],
            radius=radius,
            fill=BG_COLOR
        )
        shield_size = size * 0.7
    else:
        # For foreground: transparent bg, centered in 108dp safe zone (66dp inner)
        shield_size = size * 0.5

    # Draw shield
    draw_shield(draw, cx, cy - size*0.02, shield_size, ACCENT, WHITE)

    # Draw inner shield (smaller)
    inner = shield_size * 0.6
    draw_shield(draw, cx, cy - size*0.02, inner, BG_COLOR, None)

    # Draw "R" letter in center
    font_size = int(shield_size * 0.3)
    try:
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", font_size)
        except:
            font = ImageFont.load_default()

    text = "R"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw / 2
    ty = cy - th / 2 - size * 0.03
    draw.text((tx, ty), text, fill=ACCENT, font=font)

    # Small AI dot
    dot_r = int(size * 0.03)
    dot_cx = cx + int(shield_size * 0.12)
    dot_cy = cy + int(shield_size * 0.12)
    draw.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r], fill=WHITE)

    return img.convert("RGBA")

# Generate ic_launcher.png for each density
for folder, px in DENSITIES.items():
    path = os.path.join(BASE, folder, "ic_launcher.png")
    img = draw_icon(px, for_foreground=False)
    # Convert to RGB for non-transparent launcher icon
    rgb_img = Image.new("RGB", img.size, BG_COLOR)
    rgb_img.paste(img, mask=img.split()[3])
    rgb_img.save(path, "PNG")
    print(f"  Created {folder}/ic_launcher.png ({px}x{px}, {os.path.getsize(path)} bytes)")

# Generate ic_launcher_foreground.png for each density  
for folder, px in FG_DENSITIES.items():
    path = os.path.join(BASE, folder, "ic_launcher_foreground.png")
    img = draw_icon(px, for_foreground=True)
    img.save(path, "PNG")
    print(f"  Created {folder}/ic_launcher_foreground.png ({px}x{px}, {os.path.getsize(path)} bytes)")

print("\nAll icons generated successfully!")
