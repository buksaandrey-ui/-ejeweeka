from PIL import Image

def process_logo(input_path, output_path, target_color=(245, 146, 43)):
    img = Image.open(input_path).convert("L") # convert to grayscale
    # Invert grayscale: white becomes 0 (transparent), black/dark becomes 255 (opaque)
    # The logo is orange, so it's gray, not black.
    # Let's find min and max values to stretch contrast.
    extrema = img.getextrema()
    min_val, max_val = extrema
    
    # We want max_val (white) -> alpha 0
    # We want min_val (orange) -> alpha 255
    # For any pixel p: alpha = 255 * (max_val - p) / (max_val - min_val)
    
    img_data = img.getdata()
    new_data = []
    for p in img_data:
        if max_val == min_val:
            alpha = 255
        else:
            alpha = int(255 * (max_val - p) / (max_val - min_val))
            
        # Optional: apply an exponent to adjust the curve if it looks too thin or thick
        alpha = int(255 * ((alpha / 255) ** 0.8)) # slightly boost alpha for edge smoothness
        
        # Output color is always the target orange, just with varying alpha
        new_data.append((target_color[0], target_color[1], target_color[2], alpha))
        
    out_img = Image.new("RGBA", img.size)
    out_img.putdata(new_data)
    out_img.save(output_path, "PNG")
    print(f"Saved {output_path}")

process_logo("/Users/andreybuksa/.gemini/antigravity/brain/bdc2c918-99db-4db2-8239-c54d0157080f/media__1777056111188.png", "landing/logo-transparent.png")
