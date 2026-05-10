import json
from pytubefix import Channel
from urllib.parse import urlparse, quote

CHANNELS = [
    "https://www.youtube.com/@DoctorVyalov",
    "https://www.youtube.com/@DoctorNovak",
    "https://www.youtube.com/@medic_smith",
    "https://www.youtube.com/@pr_dadali",
    "https://www.youtube.com/@Dzari",
    "https://www.youtube.com/@eokomarovskiy",
    "https://www.youtube.com/@ОльгаПавлова-ю7с",
    "https://www.youtube.com/@dr_mashkina",
    "https://www.youtube.com/@Scinquisitor"
]

results = []
for url in CHANNELS:
    try:
        parsed = urlparse(url)
        safe_path = quote(parsed.path)
        safe_url = f"{parsed.scheme}://{parsed.netloc}{safe_path}"
        
        c = Channel(safe_url)
        # Accessing c.videos can be slow for large channels, let's just count total length to get an estimate
        # Actually len(c.videos) handles pagination automatically, but can take ~10 secs per channel
        total = len(c.videos)
        print(f"{url}: {total} всего видео")
    except Exception as e:
        print(f"Ошибка {url}: {e}")

