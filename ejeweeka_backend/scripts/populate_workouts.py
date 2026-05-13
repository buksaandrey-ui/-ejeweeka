import asyncio
import os
import json
import hashlib
from dotenv import load_dotenv

# Настраиваем пути для импорта из папки app
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google import genai
from app.db import SessionLocal
from app.models.workout_cache import WorkoutCache

env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
load_dotenv(dotenv_path=env_path, override=True)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    GEMINI_API_KEY = GEMINI_API_KEY.strip('"\'')
    print(f"API key loaded: yes, end: {GEMINI_API_KEY[-6:]}")
else:
    print("API key loaded: no")

def generate_workout_hash(data: dict) -> str:
    """Генерирует хэш на основе названия и упражнений для проверки дублей."""
    base_str = data.get("name", "") + str(data.get("exercises", []))
    return hashlib.sha256(base_str.encode('utf-8')).hexdigest()

async def fetch_workouts_batch(client, difficulty: str, location: str, goal: str, count: int = 3):
    """Асинхронно просит LLM сгенерировать батч тренировок."""
    prompt = f"""
    Ты - профессиональный фитнес-тренер и реабилитолог.
    Сгенерируй массив из {count} уникальных тренировок: Уровень: {difficulty}, Место: {location}, Цель: {goal}.
    Они должны быть эффективными и безопасными. Не используй медицинские термины.
    
    Верни ТОЛЬКО валидный JSON массив объектов:
    [
      {{
        "name": "Название тренировки",
        "workout_type": "bodyweight",
        "target_goal": "{goal}",
        "difficulty_level": "{difficulty}",
        "location": "{location}",
        "description": "Краткое описание тренировки...",
        "muscle_groups": ["Ноги", "Ягодицы", "Кор"],
        "estimated_minutes": 45,
        "equipment_required": ["Коврик"],
        "contraindications": ["Травмы коленей"],
        "safety_tags": ["без_прыжков"],
        "exercises": [
          {{"name": "Приседания", "sets": 3, "reps_or_time": "15 раз", "rest_seconds": 60}},
          {{"name": "Планка", "sets": 3, "reps_or_time": "30 сек", "rest_seconds": 45}}
        ]
      }}
    ]
    """
    try:
        response = await asyncio.to_thread(
            client.models.generate_content,
            model='gemini-2.5-flash',
            contents=prompt
        )
        text = response.text.replace('```json', '').replace('```', '').strip()
        return json.loads(text)
    except Exception as e:
        print(f"Ошибка генерации для {difficulty}/{location}: {e}")
        return []

async def main():
    print("🚀 Старт пре-генерации тренировок в базу...")
    client = genai.Client(api_key=GEMINI_API_KEY)
    db = SessionLocal()
    
    difficulties = ["Новичок", "Средний", "Продвинутый", "Реабилитация"]
    locations = ["Дома", "В зале", "На улице"]
    goals = ["Похудение", "Набор массы", "Тонус", "Гибкость и рельеф"]
    total_added = 0
    
    # 4 difficulties * 3 locations * 4 goals * 7 batches * 3 workouts = ~1000 workouts
    for diff in difficulties:
        for loc in locations:
            for goal in goals:
                for batch_num in range(7): 
                    print(f"Генерация: {diff} - {loc} - {goal} (Батч {batch_num + 1})...")
                    workouts = await fetch_workouts_batch(client, diff, loc, goal, count=3)
                    
                    for w in workouts:
                        w_hash = generate_workout_hash(w)
                        
                        exists = db.query(WorkoutCache).filter(WorkoutCache.name == w.get("name")).first()
                        if not exists:
                            new_workout = WorkoutCache(
                                name=w.get("name", "Тренировка"),
                                workout_type=w.get("workout_type", "bodyweight"),
                                target_goal=w.get("target_goal", goal),
                                difficulty_level=w.get("difficulty_level", diff),
                                location=w.get("location", loc),
                                description=w.get("description", ""),
                                muscle_groups=w.get("muscle_groups", []),
                                estimated_minutes=w.get("estimated_minutes", 45),
                                equipment_required=w.get("equipment_required", []),
                                contraindications=w.get("contraindications", []),
                                exercises=w.get("exercises", []),
                                safety_tags=w.get("safety_tags", [])
                            )
                            db.add(new_workout)
                            total_added += 1
                    
                    db.commit()
                    await asyncio.sleep(8) # Пауза против rate-limit
            
    print(f"✅ Успешно добавлено {total_added} новых тренировок в базу!")
    db.close()

if __name__ == "__main__":
    asyncio.run(main())
