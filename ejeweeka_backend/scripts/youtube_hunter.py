"""
YouTube Hunter v7.0 — pytubefix edition
Скачивает аудио из YouTube каналов, анализирует через Gemini 2.5 Flash,
инжестит медицинские знания в Supabase (pgvector).

Использует pytubefix вместо yt-dlp (обход YouTube 403 бана).
Требует: Python 3.12 + .venv
Запуск: cd ejeweeka-backend && .venv/bin/python scripts/youtube_hunter.py
"""

import os
import json
import time
import traceback
from pathlib import Path
from urllib.parse import quote, urlparse
from dotenv import load_dotenv

import sys
sys.path.append(str(Path(__file__).parent.parent))

from google import genai
from pydantic import BaseModel, Field
from pytubefix import YouTube, Channel

from app.db import SessionLocal
from app.services.rag_engine import add_knowledge_chunk
from app.models.knowledge_base import ProcessedVideo, KnowledgeChunk

load_dotenv()

TEMP_DIR = Path(__file__).parent.parent / "data" / "temp_audio"
TEMP_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================
# НОРМАЛИЗАЦИЯ ИМЁН ВРАЧЕЙ
# ============================================================
DOCTOR_NORMALIZE = {
    "вялов":        ("Сергей Вялов", "Гастроэнтеролог"),
    "новак":        ("Ксения Новак", "Диетолог"),
    "новок":        ("Ксения Новак", "Диетолог"),
    "дадали":       ("Владимир Дадали", "Биохимик / Нутрициолог"),
    "комаровский":  ("Евгений Комаровский", "Педиатр"),
    "павлова":      ("Ольга Павлова", "Эндокринолог"),
    "машкина":      ("Доктор Машкина", "Терапевт"),
    "дзария":       ("Александр Дзария", "Уролог / Онколог"),
    "дзари":        ("Александр Дзария", "Уролог / Онколог"),
    "дзизари":      ("Александр Дзария", "Уролог / Онколог"),
    "scinquisitor": ("Александр Панчин", "Биолог / Научпоп"),
    "панчин":       ("Александр Панчин", "Биолог / Научпоп"),
    "smith":        ("Medic Smith", "Терапевт / Нутрициолог"),
    "кузнецов":     ("Medic Smith", "Терапевт / Нутрициолог"),
    # Новые каналы (доказательная медицина)
    "сергиенко":    ("Игорь Сергиенко", "Кардиолог / Д.м.н."),
    "кардиолог":    ("Игорь Сергиенко", "Кардиолог / Д.м.н."),
    "пыриков":      ("Данила Пыриков", "Нефролог"),
    "docpyrikov":   ("Данила Пыриков", "Нефролог"),
    "docdeti":      ("DocDeti / DocMed", "Доказательная медицина"),
    "docmed":       ("DocDeti / DocMed", "Доказательная медицина"),
}

ALLOWED_DOCTORS = [
    'Сергей Вялов', 'Ксения Новак', 'Medic Smith', 'Владимир Дадали', 
    'Александр Дзария', 'Евгений Комаровский', 'Ольга Павлова', 
    'Доктор Машкина', 'Александр Панчин', 'ejeweeka-База',
    # Новые специалисты (доказательная медицина)
    'Игорь Сергиенко',     # Кардиолог, д.м.н., профессор
    'Данила Пыриков',       # Нефролог, доказательная медицина
    'DocDeti / DocMed',       # Клиника доказательной медицины (аллергология, педиатрия, нутрициология)
]

def normalize_doctor(raw_name: str, raw_spec: str, channel_url: str) -> tuple[str, str]:
    key = raw_name.lower().strip()
    for keyword, (canon_name, canon_spec) in DOCTOR_NORMALIZE.items():
        if keyword in key or keyword in channel_url.lower():
            return canon_name, canon_spec
    
    # Если имя распознано Gemini, но его нет в маппинге — сверяем со списком разрешенных
    for allowed in ALLOWED_DOCTORS:
        if allowed.lower() in key:
            return allowed, raw_spec.strip() or "Врач"
            
    # Если врач не в списке одобренных — ВОЗВРАЩАЕМ NONE
    return None, None


# ============================================================
# СПИСОК КАНАЛОВ
# ============================================================
def get_channels():
    md_path = Path(__file__).parent.parent.parent / "04_ai_pipeline" / "knowledge_base_status.md"
    channels = []
    try:
        with open(md_path, "r", encoding="utf-8") as f:
            for line in f:
                if "https://www.youtube.com/" in line:
                    parts = line.split("|")
                    if len(parts) >= 3:
                        url = parts[2].strip()
                        if url.startswith("https://"):
                            channels.append(url)
    except FileNotFoundError:
        pass
    if not channels:
        channels = [
            "https://www.youtube.com/@dr_mashkina",
            "https://www.youtube.com/@ОльгаПавлова-ю7с",
            "https://www.youtube.com/@eokomarovskiy",
            "https://www.youtube.com/@DoctorVyalov",
            "https://www.youtube.com/@DoctorNovak",
            "https://www.youtube.com/@medic_smith",
            "https://www.youtube.com/@pr_dadali",
            "https://www.youtube.com/@Dzari",
            "https://www.youtube.com/@Scinquisitor",
            # Новые каналы (доказательная медицина, 2026-04-23)
            "https://www.youtube.com/@КардиологИ.В.Сергиенко",  # Кардиолог, д.м.н.
            "https://www.youtube.com/@DocPyrikov",                      # Нефролог
            "https://www.youtube.com/@docdeti_docmed",                  # Аллергология / Доказательная медицина
        ]
    return channels


CHANNELS = get_channels()


# ============================================================
# GEMINI ANALYSIS SCHEMA
# ============================================================
class VideoAnalysis(BaseModel):
    is_relevant: bool = Field(description="Касается ли видео питания, витаминов, диет, тренировок, сна или хронических болезней?")
    reasoning: str = Field(description="Краткое объяснение")
    doctor_name: str = Field(description="Имя врача")
    specialization: str = Field(description="Специализация врача")
    video_topic: str = Field(description="Тема видео")
    chunks: list[str] = Field(description="Выжимки по 100-200 слов с конкретными рекомендациями. Пусто если нерелевантно")


# ============================================================
# DB HELPERS
# ============================================================
def is_video_processed(video_id: str) -> bool:
    db = SessionLocal()
    try:
        rec = db.query(ProcessedVideo).filter(ProcessedVideo.video_id == video_id).first()
        return rec is not None and rec.status in ('success', 'skipped_irrelevant', 'skipped_too_short')
    finally:
        db.close()


def mark_video(video_id: str, channel_url: str, title: str, status: str, chunks_count: int = 0):
    db = SessionLocal()
    try:
        rec = db.query(ProcessedVideo).filter(ProcessedVideo.video_id == video_id).first()
        if rec:
            rec.status = status
            rec.chunks_extracted = chunks_count
        else:
            rec = ProcessedVideo(
                video_id=video_id,
                channel_url=channel_url,
                title=(title or "Unknown")[:490],
                status=status,
                chunks_extracted=chunks_count
            )
            db.add(rec)
        db.commit()
    except Exception as e:
        print(f"  ⚠️ DB error: {e}")
        db.rollback()
    finally:
        db.close()


def get_total_chunks() -> int:
    db = SessionLocal()
    try:
        return db.query(KnowledgeChunk).count()
    finally:
        db.close()


# ============================================================
# DOWNLOAD via pytubefix
# ============================================================
def download_audio(video_url: str, output_path: str) -> bool:
    try:
        yt = YouTube(video_url)
        # Prefer m4a (aac), fallback to any audio
        stream = yt.streams.filter(only_audio=True, file_extension='m4a').order_by('abr').desc().first()
        if not stream:
            stream = yt.streams.filter(only_audio=True).order_by('abr').desc().first()
        if not stream:
            print("  ❌ Нет аудио-потоков")
            return False
        stream.download(output_path=str(Path(output_path).parent), filename=Path(output_path).name)
        return os.path.exists(output_path) and os.path.getsize(output_path) > 10000
    except Exception as e:
        print(f"  ❌ Ошибка скачивания: {e}")
        return False


# ============================================================
# GEMINI ANALYSIS + INGEST
# ============================================================
def analyze_and_ingest(audio_path: str, video_title: str, channel_url: str) -> int:
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    db = SessionLocal()
    chunks_extracted = 0

    print("  📤 Загружаем аудио в Gemini...")
    try:
        import time
        uploaded_file = client.files.upload(file=audio_path)
        while uploaded_file.state.name == "PROCESSING":
            print("  ⏳ Обработка аудио на сервере Gemini...")
            time.sleep(5)
            uploaded_file = client.files.get(name=uploaded_file.name)
        if uploaded_file.state.name == "FAILED":
            print("  ❌ Ошибка обработки файла на серверах Google")
            db.close()
            return 0
    except Exception as e:
        print(f"  ❌ Upload failed: {e}")
        db.close()
        return 0

    print("  🧠 Gemini слушает...")

    prompt = f"""
    Прослушай аудио из видео: '{video_title}'.
    Определи, относится ли оно к тематике приложения ejeweeka:
    - питание, продукты, голодание, КБЖУ, калории
    - витамины, БАДы, минералы, добавки
    - тренировки, спорт, физическая активность
    - похудение, набор массы, метаболизм
    - сон, циркадные ритмы
    - хронические болезни (диабет, щитовидка, ЖКТ, почки, холестерин, давление)
    - гормоны, инсулинорезистентность

    Если да — сделай подробную выжимку КОНКРЕТНЫХ рекомендаций. Каждый чанк (100-200 слов):
    - Конкретная рекомендация или факт (продукты, дозировки, противопоказания)
    - Контекст применимости (при каком состоянии/диагнозе)
    - Имя врача-источника
    
    НЕ включай общие фразы. Нужны КОНКРЕТНЫЕ данные.
    Если нерелевантно — is_relevant = false.
    """

    try:
        import time
        max_retries = 5
        base_delay = 5
        
        for attempt in range(max_retries):
            try:
                response = client.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=[uploaded_file, prompt],
                    config={
                        'response_mime_type': 'application/json',
                        'response_schema': VideoAnalysis
                    }
                )
                break # Успех, выходим из цикла retry
            except Exception as e:
                # Ошибка при генерации, возможно 503
                if attempt < max_retries - 1:
                    sleep_time = base_delay * (2 ** attempt)
                    print(f"  ⚠️ Ошибка Gemini API ({e}). Повтор через {sleep_time} секунд (Попытка {attempt+1}/{max_retries})...")
                    time.sleep(sleep_time)
                else:
                    raise e # Бросаем исключение дальше, если исчерпали попытки

        result_json = response.text
        if result_json.startswith("```json"):
            result_json = result_json[7:-3].strip()

        data = json.loads(result_json)

        if not data.get("is_relevant"):
            print(f"  ⏭️ Нерелевантно: {data.get('reasoning', '?')[:80]}")
            return -1  # Signal: irrelevant
        
        chunks = data.get("chunks", [])
        doctor, spec = normalize_doctor(
            data.get('doctor_name', ''), 
            data.get('specialization', ''),
            channel_url
        )
        
        if doctor is None:
            print(f"  🚫 Пропуск: врач '{data.get('doctor_name')}' не входит в белый список.")
            return -2  # Signal: unapproved doctor
        topic = data.get('video_topic', video_title)

        print(f"  🎯 {doctor} ({spec}) — {len(chunks)} чанков")

        for i, chunk in enumerate(chunks):
            try:
                add_knowledge_chunk(db, doctor, spec, topic, chunk)
                chunks_extracted += 1
            except Exception as e:
                print(f"    ⚠️ Chunk {i+1} error: {e}")
            time.sleep(0.3)

    except Exception as e:
        print(f"  ❌ AI error: {e}")
        traceback.print_exc()
    finally:
        try:
            client.files.delete(name=uploaded_file.name)
        except:
            pass
        db.close()

    return chunks_extracted


# ============================================================
# PROCESS CHANNEL
# ============================================================
def process_channel(url: str):
    print(f"\n{'='*55}")
    print(f"📡 {url}")
    print(f"{'='*55}")

    # URL-encode кириллицы
    parsed = urlparse(url)
    safe_path = quote(parsed.path, safe="/@")
    safe_url = f"{parsed.scheme}://{parsed.netloc}{safe_path}"

    try:
        channel = Channel(safe_url)
        # Собираем видео из всех разделов: обычные видео + трансляции
        videos = list(channel.videos) + list(channel.live)
        # Убираем дубликаты по ID
        seen_ids = set()
        unique_videos = []
        for v in videos:
            if v.video_id not in seen_ids:
                unique_videos.append(v)
                seen_ids.add(v.video_id)
        
        videos = unique_videos
    except Exception as e:
        print(f"  ❌ Ошибка канала: {e}")
        return

    print(f"  Видео на канале: {len(videos)}")

    processed = 0
    skipped = 0

    for video in videos:
        video_id = video.video_id
        title = video.title or "Unknown"
        duration = video.length or 0

        if is_video_processed(video_id):
            skipped += 1
            continue

        # Минимальная длина видео: 5 мин (300 сек) для всех
        threshold = 300
        if duration and duration < threshold:
            mark_video(video_id, url, title, "skipped_too_short")
            skipped += 1
            continue

        print(f"\n  📺 [{processed+1}] {title[:65]}... ({duration//60}м)")

        audio_path = str(TEMP_DIR / f"{video_id}.m4a")

        print("  ⬇️ Скачиваем...")
        if download_audio(f"https://www.youtube.com/watch?v={video_id}", audio_path):
            try:
                result = analyze_and_ingest(audio_path, title, url)
                if result == -1:
                    mark_video(video_id, url, title, "skipped_irrelevant", 0)
                elif result > 0:
                    mark_video(video_id, url, title, "success", result)
                    print(f"  ✅ +{result} чанков")
                else:
                    mark_video(video_id, url, title, "error_analysis", 0)
            except Exception as e:
                print(f"  ❌ {e}")
                mark_video(video_id, url, title, "error")
        else:
            mark_video(video_id, url, title, "error_download")

        # Cleanup
        for f in TEMP_DIR.glob(f"{video_id}*"):
            try: f.unlink()
            except: pass

        processed += 1
        time.sleep(2)  # Пауза между видео

    print(f"\n  📊 Канал: обработано {processed}, пропущено {skipped}")


# ============================================================
# RETRY ERRORS — повторная обработка упавших видео
# ============================================================
def retry_errors():
    """
    Берём все видео со статусом error/error_download/error_analysis
    и пробуем обработать заново.
    """
    db = SessionLocal()
    try:
        errors = db.query(ProcessedVideo).filter(
            ProcessedVideo.status.in_(['error', 'error_download', 'error_analysis'])
        ).all()
        print(f"\n🔄 RETRY MODE: {len(errors)} видео с ошибками")
    finally:
        db.close()

    retried = 0
    fixed = 0
    for rec in errors:
        video_id = rec.video_id
        channel_url = rec.channel_url or ''
        title = rec.title or 'Unknown'

        print(f"\n  🔄 [{retried+1}/{len(errors)}] {title[:60]}... (was: {rec.status})")

        audio_path = str(TEMP_DIR / f"{video_id}.m4a")

        # Скачиваем заново
        print("  ⬇️ Скачиваем...")
        if download_audio(f"https://www.youtube.com/watch?v={video_id}", audio_path):
            try:
                result = analyze_and_ingest(audio_path, title, channel_url)
                if result == -1:
                    mark_video(video_id, channel_url, title, "skipped_irrelevant", 0)
                elif result == -2:
                    mark_video(video_id, channel_url, title, "skipped_irrelevant", 0)
                elif result > 0:
                    mark_video(video_id, channel_url, title, "success", result)
                    fixed += 1
                    print(f"  ✅ +{result} чанков (FIXED!)")
                else:
                    mark_video(video_id, channel_url, title, "error_analysis", 0)
            except Exception as e:
                print(f"  ❌ {e}")
        else:
            print("  ⏭️ Download still failing, skip")

        # Cleanup
        for f in TEMP_DIR.glob(f"{video_id}*"):
            try: f.unlink()
            except: pass

        retried += 1
        time.sleep(2)

    total = get_total_chunks()
    print(f"\n🔄 RETRY DONE: {fixed} fixed из {retried}. В базе: {total} чанков")


# ============================================================
# MAIN LOOP — БЕЗ ЛИМИТА, собираем ВСЁ
# ============================================================
def run():
    print(f"🚀 YouTube Hunter v8.0 (UNLIMITED)")
    print(f"   Каналов: {len(CHANNELS)}")
    print(f"   Режим: собираем ВСЁ, лимита нет\n")

    total = get_total_chunks()
    print(f"   В базе сейчас: {total} чанков\n")

    for ch in CHANNELS:
        try:
            process_channel(ch)
        except Exception as e:
            print(f"❌ Канал {ch}: {e}")
            traceback.print_exc()
            time.sleep(5)

    total = get_total_chunks()
    print(f"\n{'#'*55}")
    print(f"# ВСЕ КАНАЛЫ ОБРАБОТАНЫ | В базе: {total} чанков")
    print(f"{'#'*55}")


if __name__ == "__main__":
    import sys
    if '--retry-errors' in sys.argv:
        retry_errors()
    else:
        run()
        # После основного прогона — автоматически retry ошибок
        print("\n" + "="*55)
        print("Автоматический retry ошибок...")
        print("="*55)
        retry_errors()
