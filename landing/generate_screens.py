import os
import sys
from playwright.sync_api import sync_playwright

# Absolute paths
BASE_DIR = "/Users/andreybuksa/Downloads/aidiet-docs"
SCREENS_DIR = os.path.join(BASE_DIR, "05_ui_screens/main-screens")
OUTPUT_DIR = os.path.join(BASE_DIR, "landing/assets/screens")

SCREENS = {
    "o16-summary.webp": "o16-summary-analysis.html",
    "o17-statuswall.webp": "o17-statuswall.html",
    "h1-dashboard.webp": "h1-dashboard.html",
    "p1-weekly-plan.webp": "p1-weekly-plan.html",
    "ph1-photo.webp": "ph1-photo-analysis.html",
    "s1-shopping.webp": "s1-shopping-list.html",
    "pr1-progress.webp": "pr1-activity-detail.html"
}

def capture_screens():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    with sync_playwright() as p:
        # iPhone 13 Pro size: 390x844. We will use 2x scale for retina quality.
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()

        for out_filename, html_filename in SCREENS.items():
            file_path = os.path.join(SCREENS_DIR, html_filename)
            out_path = os.path.join(OUTPUT_DIR, out_filename)
            
            if not os.path.exists(file_path):
                print(f"Warning: {file_path} does not exist. Skipping.")
                continue
                
            print(f"Capturing {html_filename}...")
            # Inject a script to force dark theme if possible, since prototypes check localStorage
            page.goto(f"file://{file_path}", wait_until="networkidle")
            
            # Forcing dark theme using local storage evaluation
            try:
                page.evaluate("""
                    const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
                    profile.selected_theme = 'dark';
                    localStorage.setItem('aidiet_profile', JSON.stringify(profile));
                """)
                # Reload to apply theme
                page.reload(wait_until="networkidle")
            except Exception as e:
                print(f"Could not set dark theme for {html_filename}")

            # Wait a bit for animations
            page.wait_for_timeout(1000)
            
            # Save screenshot as jpeg then convert to webp (playwright native webp support might be limited, but we'll try)
            # Actually playwright screenshot format accepts 'jpeg', 'png'. We will save as png and convert via PIL or just save as png and use it, wait, user wants WebP.
            # I'll save as PNG first.
            png_path = out_path.replace('.webp', '.png')
            page.screenshot(path=png_path)
            print(f"Saved {png_path}")

        browser.close()

if __name__ == "__main__":
    capture_screens()

from PIL import Image
import glob
for img_path in glob.glob(os.path.join(OUTPUT_DIR, '*.png')):
    img = Image.open(img_path)
    webp_path = img_path.replace('.png', '.webp')
    img.save(webp_path, 'webp', quality=85)
    os.remove(img_path)
    print(f"Converted to {webp_path}")
