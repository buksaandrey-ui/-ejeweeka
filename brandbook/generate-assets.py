#!/usr/bin/env python3
"""
ejeweeka — Brand Asset Generator
Generates all required PNG assets from the master app icon.
Usage: python3 brandbook/generate-assets.py
"""

import os
import sys
import shutil
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

SOURCE = "/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/rebranding/images/logo_face_playful_1778348247597.png"
BASE   = os.path.dirname(os.path.abspath(__file__))

DIRS = [
    "assets/source",
    "assets/logo",
    "assets/favicon",
    "assets/app-icon",
    "assets/examples",
]

# ── iOS app icon sizes ──────────────────────────────────────────
IOS_SIZES = [1024, 512, 256, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20]

# ── Android icon sizes ──────────────────────────────────────────
ANDROID_SIZES = [512, 192, 144, 96, 72, 48]

# ── Favicon sizes ───────────────────────────────────────────────
FAVICON_SIZES = [16, 32, 48, 128, 192, 512]


def ensure_dirs():
    for d in DIRS:
        os.makedirs(os.path.join(BASE, d), exist_ok=True)
    print("✓ Directories ready")


def save_source(img_orig):
    dest = os.path.join(BASE, "assets/source/original-app-icon.png")
    shutil.copy2(SOURCE, dest)
    print(f"✓ Original copied → {dest}")


def make_app_icon_transparent(img_orig):
    """
    Remove the white outer corners only — keep the dark rounded square intact.
    Returns RGBA image: the full app icon with transparent corners.
    """
    img = img_orig.convert("RGBA")
    arr = np.array(img, dtype=np.float32)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]

    # Detect pure white outer area (corners outside the rounded square)
    is_white = (r > 230) & (g > 230) & (b > 230)
    a[is_white] = 0

    # Soft anti-alias: pixels near white that are greyish should also fade
    near_white = (r > 180) & (g > 180) & (b > 180) & ~is_white
    a[near_white] = np.minimum(a[near_white], ((r[near_white] - 180) / 75 * 255).astype(np.float32))
    # Invert — whiter = more transparent
    a[near_white] = 255 - a[near_white]

    arr[..., 3] = np.clip(a, 0, 255)
    return Image.fromarray(arr.astype(np.uint8))


def make_mark_transparent(img_orig):
    """
    Extract the neon eje+smile mark on a fully transparent background.

    Works on BOTH dark and light (white) backgrounds.

    Method: Blue-channel smoothstep threshold.
    Glass panel max B ≈ 146, letter min B ≈ 207 — clean gap at 155.
    White-edge anti-alias artifact removed via B−G saturation guard.
    """
    img = img_orig.convert("RGBA")
    arr = np.array(img, dtype=np.float32)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]

    # glass panel max B≈146, j-dot glow tops ≈163, letters B≥207
    # LOW_B=168 excludes all non-mark glow; works on white AND dark backgrounds
    LOW_B, HIGH_B = 168.0, 220.0
    t = np.clip((b - LOW_B) / (HIGH_B - LOW_B), 0.0, 1.0)
    t = t * t * (3.0 - 2.0 * t)   # smoothstep
    new_alpha = t * 255.0

    # Kill white→dark anti-alias: near-equal RGB = not neon (B−G < 70, R > 60)
    new_alpha[(b - g < 70) & (r > 60)] = 0.0

    # Kill any near-white / light-gray pixels (LANCZOS upscale artifacts)
    new_alpha[(r > 180) & (g > 180) & (b > 180)] = 0.0

    # Kill pixels where red channel too close to blue (not saturated enough to be neon)
    new_alpha[r > (b * 0.85 + 30)] = 0.0

    # Soft Gaussian blur for smooth letter edges
    alpha_img = Image.fromarray(new_alpha.astype(np.uint8))
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.5))
    alpha_arr = np.array(alpha_img, dtype=np.float32)

    # Strip isolated artifact rows at the top (thin glow halos above the real mark)
    for row_idx in range(alpha_arr.shape[0]):
        if alpha_arr[row_idx].max() < 80:
            alpha_arr[row_idx] = 0.0
        else:
            break

    arr[..., 3] = np.clip(alpha_arr, 0, 255)
    return Image.fromarray(arr.astype(np.uint8))


def make_clean_icon_source(img_master):
    """
    Composite the source over its own dark background so there are
    ZERO white corner pixels before any resize.  The original image
    has white corners outside the rounded square; mixing those with
    dark content during LANCZOS downscaling creates purple fringing.
    Fix: mask first → composite on #0D0618 → solid RGB, no white corners.
    Returned image is solid RGB — safe for App Store submission.
    """
    masked = apply_rounded_mask(img_master.convert("RGBA"), radius_fraction=0.225)
    bg = Image.new("RGBA", masked.size, (13, 6, 24, 255))   # #0D0618
    bg.paste(masked, (0, 0), masked)
    return bg.convert("RGB")


def generate_ios_icons(img_master):
    """Resize to all iOS sizes — solid RGB, no white corners, safe for App Store."""
    out_dir = os.path.join(BASE, "assets/app-icon")
    clean = make_clean_icon_source(img_master)

    for size in IOS_SIZES:
        clean.resize((size, size), Image.LANCZOS).save(
            os.path.join(out_dir, f"ios-{size}.png"), "PNG", optimize=True)

    print(f"✓ iOS icons ({len(IOS_SIZES)} sizes, clean mask) → assets/app-icon/")


def generate_android_icons(img_master):
    """Resize to all Android sizes — solid RGB, no white corners."""
    out_dir = os.path.join(BASE, "assets/app-icon")
    clean = make_clean_icon_source(img_master)

    for size in ANDROID_SIZES:
        clean.resize((size, size), Image.LANCZOS).save(
            os.path.join(out_dir, f"android-{size}.png"), "PNG", optimize=True)

    print(f"✓ Android icons ({len(ANDROID_SIZES)} sizes, clean mask) → assets/app-icon/")


def generate_mark_transparent(img_master):
    """Generate transparent neon mark at @1x, @2x, @3x."""
    out_dir = os.path.join(BASE, "assets/logo")
    mark = make_mark_transparent(img_master)

    # Crop to the actual mark area (remove empty transparent edges)
    bbox = mark.getbbox()
    if bbox:
        mark = mark.crop(bbox)

    # @3x — full resolution (roughly 1024px wide)
    w3x = 512
    h3x = int(mark.height * w3x / mark.width)
    mark_3x = mark.resize((w3x, h3x), Image.LANCZOS)
    mark_3x.save(os.path.join(out_dir, "eje-mark-transparent@3x.png"), "PNG")

    # @2x
    w2x, h2x = w3x // 3 * 2, h3x // 3 * 2
    mark.resize((w2x, h2x), Image.LANCZOS).save(
        os.path.join(out_dir, "eje-mark-transparent@2x.png"), "PNG")

    # @1x
    w1x, h1x = w3x // 3, h3x // 3
    mark.resize((w1x, h1x), Image.LANCZOS).save(
        os.path.join(out_dir, "eje-mark-transparent.png"), "PNG")

    print("✓ Transparent neon mark (@1x @2x @3x) → assets/logo/")


def apply_rounded_mask(img, radius_fraction=0.225):
    """Cut image to a clean rounded rectangle (RGBA, transparent corners)."""
    img = img.convert("RGBA")
    w, h = img.size
    radius = int(min(w, h) * radius_fraction)
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=255)
    img.putalpha(mask)
    return img


def generate_app_icon_master(img_master):
    """Master app icon at @1x @2x @3x — RGBA with clean rounded corners, no glow outside."""
    out_dir = os.path.join(BASE, "assets/logo")

    # Mask at full 1024px FIRST, then resize — prevents LANCZOS fringing at corners
    masked_source = apply_rounded_mask(img_master.convert("RGBA"), radius_fraction=0.225)
    for scale, size in [(1, 342), (2, 684), (3, 1024)]:
        resized = masked_source.resize((size, size), Image.LANCZOS)
        suffix = f"@{scale}x" if scale > 1 else ""
        resized.save(os.path.join(out_dir, f"eje-app-icon-master{suffix}.png"), "PNG")

    print("✓ App icon master (@1x @2x @3x, RGBA clean mask) → assets/logo/")


def generate_favicons(img_master):
    """Generate all favicon sizes — no white corners via clean mask composite."""
    out_dir = os.path.join(BASE, "assets/favicon")
    img_rgb = make_clean_icon_source(img_master)

    for size in FAVICON_SIZES:
        resized = img_rgb.resize((size, size), Image.LANCZOS)
        fname = {
            16:  "favicon-16.png",
            32:  "favicon-32.png",
            48:  "favicon-48.png",
            128: "favicon-128.png",
            192: "pwa-192.png",
            512: "pwa-512.png",
        }[size]
        resized.save(os.path.join(out_dir, fname), "PNG", optimize=True)

    # apple-touch-icon (180×180)
    img_rgb.resize((180, 180), Image.LANCZOS).save(
        os.path.join(out_dir, "apple-touch-icon.png"), "PNG")

    # favicon.ico (multi-size: 16, 32, 48)
    ico_images = [img_rgb.resize((s, s), Image.LANCZOS) for s in [16, 32, 48]]
    ico_images[0].save(
        os.path.join(out_dir, "favicon.ico"),
        format="ICO",
        sizes=[(16,16), (32,32), (48,48)],
        append_images=ico_images[1:]
    )

    print("✓ Favicons (16/32/48/128, PWA 192/512, apple-touch-icon, favicon.ico) → assets/favicon/")


def generate_social_avatar(img_master):
    """512×512 social avatar (solid, no transparent corners)."""
    out_dir = os.path.join(BASE, "assets/examples")
    img_master.convert("RGB").resize((512, 512), Image.LANCZOS).save(
        os.path.join(out_dir, "social-avatar.png"), "PNG")
    print("✓ Social avatar 512×512 → assets/examples/")


def crop_to_face(img_orig, inset=150):
    """
    Uniform zoom: cut equal pixels from all 4 sides, then upscale to 1024×1024.
    Equal inset preserves all internal geometry — no distortion, no 3D effect.
    inset=150 removes the thick dark border while keeping natural proportions.
    """
    w, h = img_orig.size
    cropped = img_orig.convert("RGB").crop((inset, inset, w - inset, h - inset))
    return cropped.resize((1024, 1024), Image.LANCZOS)


def main():
    print("\n── ejeweeka Brand Asset Generator ──────────────────")
    ensure_dirs()

    if not os.path.exists(SOURCE):
        print(f"✗ Source not found: {SOURCE}")
        sys.exit(1)

    img_raw = Image.open(SOURCE)
    print(f"✓ Source loaded: {img_raw.size[0]}×{img_raw.size[1]} {img_raw.mode}")

    # Crop to the face area — removes thick dark border, face fills the icon
    img_master = crop_to_face(img_raw, inset=150)
    print(f"✓ Cropped to face area → 1024×1024")

    save_source(img_raw)          # keep original in source/
    generate_app_icon_master(img_master)
    generate_mark_transparent(img_master)
    generate_ios_icons(img_master)
    generate_android_icons(img_master)
    generate_favicons(img_master)
    generate_social_avatar(img_master)

    print("\n── Done ─────────────────────────────────────────────")
    print("NOTE: eje-mark-transparent* is auto-extracted.")
    print("      For a pixel-perfect light-background version,")
    print("      mask the original manually in Figma/Photoshop.")
    print("─────────────────────────────────────────────────────\n")


if __name__ == "__main__":
    main()
