from PIL import Image
import sys

img_path = 'brandbook/assets/app-icon/ios-1024.png'
out_path = 'health_code/assets/icon.png'

try:
    img = Image.open(img_path).convert("RGBA")
    # Create a white background image
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    # Paste the image on the background using alpha as mask
    bg.paste(img, (0, 0), img)
    # Convert to RGB (no alpha) and save
    bg.convert("RGB").save(out_path, "PNG")
    print("Icon fixed and saved to " + out_path)
except Exception as e:
    print("Error:", e)
