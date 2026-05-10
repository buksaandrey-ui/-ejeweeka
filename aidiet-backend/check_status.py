import subprocess
from app.db import SessionLocal
from app.models.knowledge_base import KnowledgeChunk

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

db = SessionLocal()

print("Собираем статистику через yt-dlp...")
print("==================================================")

# Пытаемся понять, сколько всего уникальных видео было обработано.
# Для этого считаем уникальные названия видео в базе:
processed_videos_db = db.query(KnowledgeChunk.video_topic).distinct().all()
total_processed_videos = len(processed_videos_db)

results = []

for url in CHANNELS:
    try:
        # Скачиваем ТОЛЬКО метаданные (не видео), и фильтруем > 480
        cmd = [
            "python3", "-m", "yt_dlp",
            "--flat-playlist",
            "--match-filter", "duration >= 480",
            "--print", "%(id)s::::%(title)s",
            url
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            lines = result.stdout.strip().split("\n")
            # yt-dlp может выдать пустоту если нет видео
            titles_on_channel = []
            for line in lines:
                if "::::" in line:
                    _, title = line.split("::::", 1)
                    titles_on_channel.append(title)
                    
            count = len(titles_on_channel)
            
            # Попробуем прикинуть сколько УЖЕ скачано с ЭТОГО канала
            # (очень приблизительно, сравнивая titles_on_channel и processed_videos_db)
            db_topics = [t[0] for t in processed_videos_db]
            processed_for_channel = sum(1 for t in titles_on_channel if t.strip() in db_topics)
            
            # Так как yt-dlp с --url часто возвращает 0 если боится бана, но --flat-playlist работает
            print(f"{url} -> Всего на канале длинных: {count}. Из них в базе: {processed_for_channel} (Осталось ~{count - processed_for_channel})")
        else:
            print(f"{url} -> Ошибка: {result.stderr.strip()}")
    except Exception as e:
        print(f"Ошибка {url}: {e}")

print("==================================================")
print(f"Итого мы имеем В БАЗЕ знаний видео суммарно: {total_processed_videos}")
