"""
Cron Worker: Скрипт для асинхронного пополнения базы данных рецептов (Hybrid DB Seeding).
Запускается по расписанию (cron) для генерации рецептов через Gemini в часы минимальной нагрузки.
"""

import asyncio
import os
import sys
import json
import random
import hashlib
from datetime import datetime
from google import genai

# Добавляем корневую директорию проекта в sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import SessionLocal
from app.models.recipe_cache import MealCache

# Матрица профилей для генерации
MEAL_TYPES = ["Завтрак", "Обед", "Ужин", "Перекус"]
DISEASES = [
    [], # Здоровый
    ["Гастрит"],
    ["Диабет 2 типа"],
    ["Подагра"],
    ["Гипертония"]
]
ALLERGENS = [
    [], # Без аллергий
    ["Лактоза"],
    ["Глютен"],
    ["Орехи", "Арахис"],
    ["Рыба", "Морепродукты"]
]

def build_prompt(meal_type: str, diseases: list, allergens: list) -> str:
    prompt = f"""
Ты профессиональный нутрициолог. Твоя задача - сгенерировать 3 уникальных и вкусных рецепта для приема пищи: {meal_type}.
Они должны быть строго рассчитаны на 100-граммовую базовую порцию (macros per 100g) или как базовый эталон.

Важные ограничения (СТРОГО СОБЛЮДАТЬ):
"""
    if diseases:
        prompt += f"- Заболевания: {', '.join(diseases)}. Блюда должны быть абсолютно безопасны при этих заболеваниях.\n"
    if allergens:
        prompt += f"- Аллергии: {', '.join(allergens)}. В ингредиентах не должно быть этих продуктов или их следов.\n"

    prompt += """
Верни ответ СТРОГО в формате JSON-массива без лишнего текста и markdown (без ```json). 
Пример формата:
[
  {
    "name": "Название блюда",
    "calories": 250.0,
    "protein": 15.0,
    "fat": 8.0,
    "carbs": 30.0,
    "fiber": 5.0,
    "allergens_present": [],
    "safe_for_diseases": [""" + (f'"{diseases[0]}"' if diseases else '"Здоровый"') + """],
    "wellness_rationale": "Краткое обоснование пользы",
    "ingredients": [
      {"name": "Ингредиент 1", "grams": 100}
    ],
    "steps": ["Шаг 1", "Шаг 2"]
  }
]
"""
    return prompt

async def populate_cache():
    print(f"[{datetime.now()}] 🔄 Запуск Cache Populator Worker...")
    
    # 1. Выбираем случайную комбинацию для пополнения (чтобы не генерировать всё сразу и не упереться в лимиты)
    meal_type = random.choice(MEAL_TYPES)
    disease = random.choice(DISEASES)
    allergen = random.choice(ALLERGENS)
    
    print(f"🎯 Выбрана категория: {meal_type} | Болезни: {disease} | Аллергии: {allergen}")
    
    prompt = build_prompt(meal_type, disease, allergen)
    
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    if not GEMINI_API_KEY:
        print("⚠️ GEMINI_API_KEY не установлен. Выход.")
        return
        
    client = genai.Client(api_key=GEMINI_API_KEY)
    
    try:
        # Вызов Gemini
        response = await asyncio.to_thread(client.models.generate_content, model='gemini-2.5-flash', contents=prompt)
        text_resp = response.text.replace("```json", "").replace("```", "").strip()
        recipes = json.loads(text_resp)
        
        # 2. Сохраняем в БД
        db = SessionLocal()
        try:
            added_count = 0
            for r in recipes:
                # Генерируем hash ингредиентов или имени для уникальности
                ing_str = ", ".join([i.get("name", "") for i in r.get("ingredients", [])])
                name_hash = hashlib.sha256(r.get("name", "").encode('utf-8')).hexdigest()
                
                # Проверяем, есть ли такое блюдо уже
                existing = db.query(MealCache).filter(MealCache.name == r.get("name")).first()
                if not existing:
                    meal = MealCache(
                        ingredients_hash=name_hash,
                        name=r.get("name"),
                        meal_type=meal_type,
                        calories=r.get("calories", 0),
                        protein=r.get("protein", 0),
                        fat=r.get("fat", 0),
                        carbs=r.get("carbs", 0),
                        fiber=r.get("fiber", 0),
                        allergens_present=r.get("allergens_present", []),
                        safe_for_diseases=disease, # Форсируем тег болезни, под которую просили
                        wellness_rationale=r.get("wellness_rationale", ""),
                        ingredients=r.get("ingredients", []),
                        steps=r.get("steps", [])
                    )
                    db.add(meal)
                    added_count += 1
            
            if added_count > 0:
                db.commit()
            print(f"✅ Успешно добавлено {added_count} новых рецептов в MealCache.")
        except Exception as e:
            db.rollback()
            print(f"❌ Ошибка БД при сохранении: {e}")
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Ошибка Gemini или парсинга: {e}")

if __name__ == "__main__":
    asyncio.run(populate_cache())
