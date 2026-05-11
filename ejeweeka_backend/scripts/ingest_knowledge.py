import os
import glob
from pathlib import Path
import time
from dotenv import load_dotenv

import sys
# Добавляем родительскую папку (ejeweeka-backend) в пути питона, чтобы импорты app.* работали из папки scripts/
sys.path.append(str(Path(__file__).parent.parent))

from app.db import SessionLocal
from app.services.rag_engine import add_knowledge_chunk

load_dotenv()

DATA_DIR = Path(__file__).parent.parent / "data" / "transcripts"

def split_text_into_chunks(text: str, max_chunk_size: int = 800) -> list[str]:
    """
    Разбивка длинного текста на логические чанки.
    Сначала по двойному абзацу. Если абзац слишком длинный — разбиваем по одному.
    """
    paragraphs = [p.strip() for p in text.split("\n") if p.strip()]
    
    chunks = []
    current_chunk = ""
    
    for p in paragraphs:
        if len(current_chunk) + len(p) < max_chunk_size:
            current_chunk += p + "\n\n"
        else:
            if current_chunk:
                chunks.append(current_chunk.strip())
            current_chunk = p + "\n\n"
            
    if current_chunk:
        chunks.append(current_chunk.strip())
        
    return chunks

def process_directory():
    db = SessionLocal()
    
    # Находим все папки врачей в data/transcripts/
    folders = glob.glob(str(DATA_DIR / "*"))
    
    total_chunks_added = 0
    
    for folder_path in folders:
        folder = Path(folder_path)
        if not folder.is_dir():
            continue
            
        folder_name = folder.name
        # Формат должен быть Специализация_ИмяВрача, например: Эндокринолог_Магерия
        if "_" not in folder_name:
            print(f"⚠️ Пропуск папки {folder_name} (неверный формат, нужен Спец_Имя)")
            continue
            
        spec, doctor = folder_name.split("_", 1)
        spec = spec.replace("-", " ")
        doctor = doctor.replace("_", " ")

        # Читаем файлы внутри папки врача
        files = glob.glob(str(folder / "*.txt")) + glob.glob(str(folder / "*.md"))
        
        for file_path in files:
            file = Path(file_path)
            topic = file.stem.replace("_", " ") # Убираем расширение и подчеркивания
            
            with open(file, "r", encoding="utf-8") as f:
                content = f.read()
                
            chunks = split_text_into_chunks(content)
            print(f"\n📄 Файл: {file.name} | Тема: {topic}")
            print(f"Врач: {doctor} ({spec}) | Найдено чанков: {len(chunks)}")
            
            for i, chunk in enumerate(chunks, 1):
                print(f"  [{i}/{len(chunks)}] Генерируем вектор и сохраняем в БД...")
                
                # Сохраняем в Supabase.
                add_knowledge_chunk(db, doctor, spec, topic, chunk)
                
                total_chunks_added += 1
                # Небольшая пауза для избежания Rate Limits (429) от Google Gemini
                time.sleep(2)
                
    db.close()
    print(f"\n🎉 ГОТОВО! Успешно обработано и добавлено чанков: {total_chunks_added}")

if __name__ == "__main__":
    print("🚀 Старт загрузки (Ingestion Pipeline) в базу знаний ejeweeka...\n")
    if not DATA_DIR.exists():
        print(f"❌ Ошибка: Папка {DATA_DIR} не найдена. Создайте её и добавьте `.txt` файлы.")
        exit(1)
        
    process_directory()
