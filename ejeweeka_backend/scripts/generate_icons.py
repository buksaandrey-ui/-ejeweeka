#!/usr/bin/env python3
"""
ejeweeka Icon Generator
Создаёт все нужные размеры иконок для iOS и Android из source 1024x1024.

Использование:
  1. Положи исходную иконку 1024x1024 как: ejeweeka-app/assets/icon-1024.png
  2. Запусти: python3 scripts/generate_icons.py
  
Установка зависимостей:
  pip install Pillow
"""

from PIL import Image
from pathlib import Path

SOURCE = Path(__file__).parent.parent / "ejeweeka-app" / "assets" / "icon-1024.png"
IOS_OUT = Path(__file__).parent.parent / "ejeweeka-app" / "ios" / "App" / "App" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_OUT = Path(__file__).parent.parent / "ejeweeka-app" / "android" / "app" / "src" / "main" / "res"

# iOS иконки
IOS_SIZES = [
    ("Icon-20@2x.png", 40),
    ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58),
    ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80),
    ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-76.png", 76),
    ("Icon-76@2x.png", 152),
    ("Icon-83.5@2x.png", 167),
    ("Icon-1024.png", 1024),  # App Store
]

# Android иконки
ANDROID_SIZES = [
    ("mipmap-mdpi/ic_launcher.png", 48),
    ("mipmap-hdpi/ic_launcher.png", 72),
    ("mipmap-xhdpi/ic_launcher.png", 96),
    ("mipmap-xxhdpi/ic_launcher.png", 144),
    ("mipmap-xxxhdpi/ic_launcher.png", 192),
]

def generate_icons():
    if not SOURCE.exists():
        print(f"❌ Исходная иконка не найдена: {SOURCE}")
        print(f"   Создайте файл icon-1024.png в папке ejeweeka-app/assets/")
        return

    img = Image.open(SOURCE).convert("RGBA")
    print(f"✅ Загружена иконка: {SOURCE}")

    # iOS
    IOS_OUT.mkdir(parents=True, exist_ok=True)
    for filename, size in IOS_SIZES:
        out = IOS_OUT / filename
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(out, "PNG")
        print(f"  iOS: {filename} ({size}×{size})")

    # Android
    for path, size in ANDROID_SIZES:
        out = ANDROID_OUT / path
        out.parent.mkdir(parents=True, exist_ok=True)
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(out, "PNG")
        print(f"  Android: {path} ({size}×{size})")

    print(f"\n🎉 Готово! {len(IOS_SIZES)} iOS + {len(ANDROID_SIZES)} Android иконок")
    print(f"   Теперь запусти: cd ejeweeka-app && npx cap sync")

if __name__ == "__main__":
    generate_icons()
