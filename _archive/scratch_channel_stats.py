import sys
from pathlib import Path
from pytubefix import Channel

sys.path.append(str(Path.cwd() / "aidiet-backend"))
from app.db import SessionLocal
from app.models.knowledge_base import KnowledgeChunk
from sqlalchemy import func

def get_channels_from_markdown():
    md_path = Path.cwd() / "04_ai_pipeline" / "knowledge_base_status.md"
    channels = []
    try:
        with open(md_path, "r", encoding="utf-8") as f:
            for line in f:
                if "https://www.youtube.com/" in line:
                    parts = line.split("|")
                    if len(parts) >= 3:
                        name = parts[1].strip()
                        url = parts[2].strip()
                        if url.startswith("https://"):
                            channels.append({"name": name, "url": url})
    except FileNotFoundError:
        pass
    return channels

if __name__ == "__main__":
    db = SessionLocal()
    
    print("Fetching DB data... (Distinct video topics per doctor)")
    db_stats = db.query(KnowledgeChunk.doctor_name, func.count(func.distinct(KnowledgeChunk.video_topic))).group_by(KnowledgeChunk.doctor_name).all()
    processed_map = {row[0]: row[1] for row in db_stats}
    print(f"DB Map: {processed_map}")

    channels = get_channels_from_markdown()
    
    print("\n============== YOUTUBE REPORT ==============")
    for ch in channels:
        try:
            # Fix cyrillic urls
            from urllib.parse import quote, urlparse
            parsed = urlparse(ch["url"])
            safe_path = quote(parsed.path)
            safe_url = f"{parsed.scheme}://{parsed.netloc}{safe_path}"
            
            c = Channel(safe_url)
            total_videos = len(c.videos)
            long_videos = 0
            
            # Since fetching all videos length might take extremely long due to lazy loading,
            # we just report total_videos available. Or maybe len() is instant?
            print(f"Channel: {ch['name']} ({ch['url']}) -> Total YT Videos: {total_videos}")
            
        except Exception as e:
            print(f"Error fetching channel {ch['name']}: {e}")
