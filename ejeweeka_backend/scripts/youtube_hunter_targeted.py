"""
YouTube Hunter — Targeted Run
Целевой запуск ТОЛЬКО для каналов, которые ещё не обработаны.
Запуск: cd ejeweeka-backend && .venv/bin/python scripts/youtube_hunter_targeted.py
"""

import os
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from dotenv import load_dotenv
load_dotenv()

# Импортируем всё из основного хантера
from scripts.youtube_hunter import process_channel, get_total_chunks

# ТОЛЬКО необработанные каналы — в порядке приоритета
TARGETED_CHANNELS = [
    "https://www.youtube.com/@eokomarovskiy",       # 292 видео, 0 обработано
    "https://www.youtube.com/@%D0%9E%D0%BB%D1%8C%D0%B3%D0%B0%D0%9F%D0%B0%D0%B2%D0%BB%D0%BE%D0%B2%D0%B0-%D1%8E7%D1%81",  # Ольга Павлова (URL-encoded)
    "https://www.youtube.com/@DoctorNovak",          # 30 видео, 0 обработано
    "https://www.youtube.com/@Scinquisitor",         # 100+ видео, 0 обработано
]

TARGET = 5000

def run():
    print(f"🎯 YouTube Hunter — ЦЕЛЕВОЙ ЗАПУСК")
    print(f"   Каналов: {len(TARGETED_CHANNELS)}")
    print(f"   Цель: {TARGET}+ чанков\n")

    total = get_total_chunks()
    print(f"📊 В базе сейчас: {total} чанков\n")

    for ch in TARGETED_CHANNELS:
        total = get_total_chunks()
        if total >= TARGET:
            print(f"\n🎉 ЦЕЛЬ ДОСТИГНУТА: {total} >= {TARGET}!")
            return

        try:
            process_channel(ch)
        except Exception as e:
            print(f"❌ Канал {ch}: {e}")
            import traceback
            traceback.print_exc()
            import time
            time.sleep(5)

    print(f"\n📊 Итого в базе: {get_total_chunks()} чанков")


if __name__ == "__main__":
    run()
