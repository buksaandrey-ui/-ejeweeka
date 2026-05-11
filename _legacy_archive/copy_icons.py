import os
import shutil

ios_dest = 'health_code/ios/Runner/Assets.xcassets/AppIcon.appiconset'
ios_mapping = {
    'ios-20.png': ['Icon-App-20x20@1x.png'],
    'ios-40.png': ['Icon-App-20x20@2x.png', 'Icon-App-40x40@1x.png'],
    'ios-60.png': ['Icon-App-20x20@3x.png', 'Icon-App-60x60@1x.png'],
    'ios-29.png': ['Icon-App-29x29@1x.png'],
    'ios-58.png': ['Icon-App-29x29@2x.png'],
    'ios-87.png': ['Icon-App-29x29@3x.png'],
    'ios-80.png': ['Icon-App-40x40@2x.png'],
    'ios-120.png': ['Icon-App-40x40@3x.png', 'Icon-App-60x60@2x.png'],
    'ios-180.png': ['Icon-App-60x60@3x.png'],
    'ios-76.png': ['Icon-App-76x76@1x.png'],
    'ios-152.png': ['Icon-App-76x76@2x.png'],
    'ios-167.png': ['Icon-App-83.5x83.5@2x.png'],
    'ios-1024.png': ['Icon-App-1024x1024@1x.png']
}

for src_name, dest_names in ios_mapping.items():
    src_path = os.path.join('brandbook/assets/app-icon', src_name)
    if os.path.exists(src_path):
        for dest_name in dest_names:
            dest_path = os.path.join(ios_dest, dest_name)
            shutil.copy2(src_path, dest_path)

android_dest_base = 'health_code/android/app/src/main/res'
android_mapping = {
    'android-48.png': 'mipmap-mdpi',
    'android-72.png': 'mipmap-hdpi',
    'android-96.png': 'mipmap-xhdpi',
    'android-144.png': 'mipmap-xxhdpi',
    'android-192.png': 'mipmap-xxxhdpi',
}

for src_name, mipmap_dir in android_mapping.items():
    src_path = os.path.join('brandbook/assets/app-icon', src_name)
    dest_dir = os.path.join(android_dest_base, mipmap_dir)
    if os.path.exists(src_path):
        os.makedirs(dest_dir, exist_ok=True)
        shutil.copy2(src_path, os.path.join(dest_dir, 'ic_launcher.png'))

print("Icons copied successfully.")
