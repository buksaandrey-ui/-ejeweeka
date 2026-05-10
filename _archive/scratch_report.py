import sys
from pathlib import Path

sys.path.append(str(Path.cwd() / "aidiet-backend"))
from scripts.youtube_hunter import CHANNELS, is_video_processed
from app.db import SessionLocal
from app.models.knowledge_base import ProcessedVideo, KnowledgeChunk
from sqlalchemy import func
import yt_dlp

def generate_report():
    print("Генерация отчета по каналам YouTube...")
    db = SessionLocal()
    
    # Считаем уникальные video_topic (старые данные до таблицы ProcessedVideo)
    db_stats = db.query(KnowledgeChunk.doctor_name, func.count(func.distinct(KnowledgeChunk.video_topic))).group_by(KnowledgeChunk.doctor_name).all()
    old_processed_map = {row[0]: row[1] for row in db_stats}
    
    ydl_opts = {
        'extract_flat': True,
        'force_generic_extractor': False,
        'quiet': True
    }
    
    print(f"\n{'КАНАЛ':<40} | {'Всего видео':<12} | {'Обработано (БД)':<16} | {'Осталось (Оценка)':<18}")
    print("-" * 90)
    
    total_db_chunks = db.query(KnowledgeChunk).count()
    
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        for channel_url in CHANNELS:
            try:
                res = ydl.extract_info(channel_url, download=False)
                if not res or 'entries' not in res:
                    print(f"{channel_url:<40} | Ошибка загрузки")
                    continue
                
                videos = list(res['entries'])
                total_videos = len(videos)
                
                # Ищем количество обработанных по новому методу
                processed_in_new_db = db.query(ProcessedVideo).filter(ProcessedVideo.channel_url == channel_url).count()
                
                # Пытаемся сопоставить со старым методом по имени канала (грубо)
                channel_title = res.get('title', channel_url.split('@')[-1])
                old_count = 0
                for doc_name, count in old_processed_map.items():
                    if doc_name and (doc_name.lower() in channel_title.lower() or channel_title.lower() in doc_name.lower()):
                        old_count = max(old_count, count)
                
                # Если в новой таблице пусто, используем старые данные
                actual_processed = max(processed_in_new_db, old_count)
                
                remaining = max(0, total_videos - actual_processed)
                
                print(f"{channel_title[:38]:<40} | {total_videos:<12} | {actual_processed:<16} | {remaining:<18}")
                
            except Exception as e:
                print(f"{channel_url:<40} | Сбой: {e}")
                
    print("-" * 90)
    print(f"Всего медицинских чанков в векторной БД: {total_db_chunks}")

generate_report()
