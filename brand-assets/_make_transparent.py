#!/usr/bin/env python3
"""
Remove solid backgrounds (white or black) from logo PNGs and make them transparent.
Uses color distance threshold for anti-aliased edges.
"""
from PIL import Image
import sys
import os

BRAIN = "/Users/andreybuksa/.gemini/antigravity/brain/160860ad-6382-45da-8f1b-62ee7bc34c38"
OUT = "/Users/andreybuksa/Downloads/aidiet-docs/brand-assets/production"

os.makedirs(OUT, exist_ok=True)

# Define all source images and their background type
ASSETS = {
    # (source_filename, output_filename, bg_type)
    # bg_type: 'white' = remove white bg, 'black' = remove black bg, 'none' = keep as-is
    
    # Horizontal wordmark
    "hc_logo_horizontal_dark_1778044633457.png": ("logo-horizontal-dark-on-transparent.png", "white"),
    "hc_logo_horizontal_white_1778044646157.png": ("logo-horizontal-white-on-transparent.png", "black"),
    
    # Stacked / vertical
    "hc_logo_stacked_dark_1778044661920.png": ("logo-stacked-dark-on-transparent.png", "white"),
    "hc_logo_stacked_white_1778044707275.png": ("logo-stacked-white-on-transparent.png", "black"),
    
    # Icon-only (symbol)
    "hc_icon_only_orange_1778044719866.png": ("icon-symbol-orange-on-transparent.png", "white"),
    "hc_icon_only_white_1778044732419.png": ("icon-symbol-white-on-transparent.png", "black"),
    
    # Monochrome (dark charcoal on white)
    "hc_logo_mono_white_on_white_1778044800462.png": ("logo-monochrome-dark-on-transparent.png", "white"),
    
    # Monochrome (white on dark) - from earlier
    "hc_monochrome_1778041597422.png": ("logo-monochrome-white-on-transparent.png", "dark_gray"),
    
    # App icon (keep background, just copy)
    "hc_appicon_production_1778044769127.png": ("appicon-1024.png", "none"),
    
    # Favicon (keep background, just copy)
    "hc_favicon_square_1778044787061.png": ("favicon-source.png", "none"),
}


def remove_background(img, bg_type, threshold=60):
    """Remove white or black background, making it transparent."""
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    
    for pixel in data:
        r, g, b, a = pixel
        
        if bg_type == "white":
            # Distance from pure white
            dist = ((255 - r)**2 + (255 - g)**2 + (255 - b)**2) ** 0.5
            if dist < threshold:
                # Scale alpha by distance for anti-aliasing
                alpha = min(255, int(dist * 255 / threshold))
                new_data.append((r, g, b, alpha))
            else:
                new_data.append(pixel)
                
        elif bg_type == "black":
            # Distance from pure black
            dist = (r**2 + g**2 + b**2) ** 0.5
            if dist < threshold:
                alpha = min(255, int(dist * 255 / threshold))
                new_data.append((r, g, b, alpha))
            else:
                new_data.append(pixel)
                
        elif bg_type == "dark_gray":
            # Distance from dark gray (#2D3748 ≈ 45, 55, 72)
            dist = ((r - 45)**2 + (g - 55)**2 + (b - 72)**2) ** 0.5
            if dist < threshold:
                alpha = min(255, int(dist * 255 / threshold))
                new_data.append((r, g, b, alpha))
            else:
                new_data.append(pixel)
        else:
            new_data.append(pixel)
    
    img.putdata(new_data)
    return img


def generate_favicon_sizes(source_path, out_dir):
    """Generate favicon at multiple sizes from the source."""
    img = Image.open(source_path)
    
    sizes = [16, 32, 48, 64, 128, 180, 192, 512]
    for size in sizes:
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(os.path.join(out_dir, f"favicon-{size}x{size}.png"))
        print(f"  ✓ favicon-{size}x{size}.png")
    
    # Generate ICO (16, 32, 48 combined)
    img_16 = img.resize((16, 16), Image.LANCZOS)
    img_32 = img.resize((32, 32), Image.LANCZOS)
    img_48 = img.resize((48, 48), Image.LANCZOS)
    img_16.save(os.path.join(out_dir, "favicon.ico"), format="ICO", 
                sizes=[(16, 16), (32, 32), (48, 48)])
    print(f"  ✓ favicon.ico (multi-size)")


def generate_appicon_sizes(source_path, out_dir):
    """Generate iOS app icon sizes."""
    img = Image.open(source_path)
    
    ios_sizes = [
        (20, 1), (20, 2), (20, 3),
        (29, 1), (29, 2), (29, 3),
        (40, 1), (40, 2), (40, 3),
        (60, 2), (60, 3),
        (76, 1), (76, 2),
        (83.5, 2),
        (1024, 1),
    ]
    
    icon_dir = os.path.join(out_dir, "AppIcon.appiconset")
    os.makedirs(icon_dir, exist_ok=True)
    
    for base_size, scale in ios_sizes:
        px = int(base_size * scale)
        resized = img.resize((px, px), Image.LANCZOS)
        name = f"icon-{int(base_size)}@{scale}x.png" if scale > 1 else f"icon-{int(base_size)}.png"
        resized.save(os.path.join(icon_dir, name))
        print(f"  ✓ {name} ({px}x{px})")


# Main
print("🎨 Health Code — Brand Asset Production Pipeline")
print("=" * 50)

for src_file, (out_name, bg_type) in ASSETS.items():
    src_path = os.path.join(BRAIN, src_file)
    out_path = os.path.join(OUT, out_name)
    
    if not os.path.exists(src_path):
        print(f"⚠️  SKIP: {src_file} not found")
        continue
    
    img = Image.open(src_path)
    
    if bg_type == "none":
        # Just copy
        img.save(out_path)
        print(f"✅ {out_name} (copied, {img.size[0]}x{img.size[1]})")
    else:
        # Remove background
        result = remove_background(img, bg_type)
        result.save(out_path)
        print(f"✅ {out_name} (transparent, {result.size[0]}x{result.size[1]})")

# Generate favicon sizes
print("\n📐 Generating favicon sizes...")
favicon_src = os.path.join(OUT, "favicon-source.png")
if os.path.exists(favicon_src):
    generate_favicon_sizes(favicon_src, OUT)

# Generate app icon sizes  
print("\n📱 Generating iOS app icon sizes...")
appicon_src = os.path.join(OUT, "appicon-1024.png")
if os.path.exists(appicon_src):
    generate_appicon_sizes(appicon_src, OUT)

print("\n✨ Done! All assets in:", OUT)
