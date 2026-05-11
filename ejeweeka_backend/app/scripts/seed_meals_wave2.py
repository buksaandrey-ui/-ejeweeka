"""
Mass Seed WAVE 2: meals_library — дополнительные комбинации.
Добавляет рецепты для целей (похудение/набор массы) и расширенных болезней.
Запускать ПОСЛЕ seed_meals_mass.py.

Run: python3 -m app.scripts.seed_meals_wave2
"""

import asyncio
import os
import sys
import json
import hashlib
from datetime import datetime
from itertools import product as iterproduct
from pathlib import Path
from dotenv import load_dotenv

_backend_root = Path(__file__).resolve().parent.parent.parent
load_dotenv(_backend_root / ".env")
sys.path.insert(0, str(_backend_root))

from app.db import SessionLocal
from app.models.recipe_cache import MealCache


# ═══════════════════════════════════════════
# WAVE 2 MATRIX — дополнительные оси
# ═══════════════════════════════════════════

MEAL_TYPES = ["Завтрак", "Обед", "Ужин", "Перекус"]

# Новые болезни, которых не было в wave 1
DISEASE_COMBOS_W2 = [
    ["СРК"],                    # Синдром раздражённого кишечника
    ["Гипотиреоз"],
    ["Подагра", "Гипертония"],  # Мультиморбидность
    ["Диабет 2 типа", "Гастрит"],
]

# Новые аллергии
ALLERGEN_COMBOS_W2 = [
    [],
    ["Яйца"],
    ["Соя"],
    ["Лактоза", "Глютен"],       # Двойная непереносимость
]

BUDGET_LEVELS = ["Экономный", "Средний"]

# Цели (новая ось)
GOALS = ["Похудение", "Набор массы"]


def build_prompt(meal_type, diseases, allergens, budget, goal):
    prompt = f"""Ты профессиональный нутрициолог ejeweeka. Сгенерируй 3 уникальных рецепта для: {meal_type}.

ПРАВИЛА:
- Цель пользователя: {goal}.
{"- Калорийность ниже средней, акцент на белок и клетчатку." if goal == "Похудение" else "- Калорийность выше средней, акцент на белок и углеводы."}
- Бюджет: {budget}. {'Используй только дешёвые продукты масс-маркета.' if budget == 'Экономный' else 'Средний ценовой сегмент.'}
"""
    if diseases:
        prompt += f"- Заболевания: {', '.join(diseases)}. Блюда АБСОЛЮТНО безопасны при этих заболеваниях.\n"
    if allergens:
        prompt += f"- Аллергии: {', '.join(allergens)}. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНЫ эти продукты и их производные.\n"

    prompt += """
Верни СТРОГО JSON-массив (без markdown, без ```):
[
  {
    "name": "Название",
    "calories": 250.0,
    "protein": 15.0,
    "fat": 8.0,
    "carbs": 30.0,
    "fiber": 5.0,
    "allergens_present": [],
    "wellness_rationale": "Обоснование",
    "ingredients": [{"name": "Ингредиент", "grams": 100}],
    "steps": ["Шаг 1", "Шаг 2"]
  }
]"""
    return prompt


async def generate_batch(client, combo_queue, db_session_factory, max_concurrent=3):
    semaphore = asyncio.Semaphore(max_concurrent)
    results = {"added": 0, "skipped": 0, "errors": 0}

    async def process_one(combo):
        async with semaphore:
            meal_type, diseases, allergens, budget, goal = combo
            label = f"{meal_type} | {goal} | D:{diseases or '—'} | A:{allergens or '—'} | B:{budget}"

            prompt = build_prompt(meal_type, diseases, allergens, budget, goal)

            try:
                response = await asyncio.to_thread(
                    client.models.generate_content,
                    model='gemini-2.5-flash',
                    contents=prompt
                )
                text = response.text.replace("```json", "").replace("```", "").strip()
                recipes = json.loads(text)
            except Exception as e:
                print(f"  ❌ {label}: {e}")
                results["errors"] += 1
                return

            db = db_session_factory()
            try:
                for r in recipes:
                    name = r.get("name", "").strip()
                    if not name:
                        continue
                    existing = db.query(MealCache).filter(MealCache.name == name).first()
                    if existing:
                        results["skipped"] += 1
                        continue

                    name_hash = hashlib.sha256(name.encode('utf-8')).hexdigest()
                    meal = MealCache(
                        ingredients_hash=name_hash,
                        name=name,
                        meal_type=meal_type,
                        calories=r.get("calories", 0),
                        protein=r.get("protein", 0),
                        fat=r.get("fat", 0),
                        carbs=r.get("carbs", 0),
                        fiber=r.get("fiber", 0),
                        allergens_present=allergens,
                        safe_for_diseases=diseases if diseases else ["Здоровый"],
                        wellness_rationale=r.get("wellness_rationale", ""),
                        ingredients=r.get("ingredients", []),
                        steps=r.get("steps", [])
                    )
                    db.add(meal)
                    results["added"] += 1
                db.commit()
                print(f"  ✅ {label}: +{len(recipes)} recipes")
            except Exception as e:
                db.rollback()
                print(f"  ❌ DB error {label}: {e}")
                results["errors"] += 1
            finally:
                db.close()

            await asyncio.sleep(0.5)

    tasks = [process_one(combo) for combo in combo_queue]
    await asyncio.gather(*tasks)
    return results


async def main():
    from google import genai

    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    if not GEMINI_API_KEY:
        print("❌ GEMINI_API_KEY not set")
        return

    client = genai.Client(api_key=GEMINI_API_KEY)

    # Wave 2 combos: 4 meals × 4 diseases × 4 allergens × 2 budgets × 2 goals = 256 combos × 3 = ~768 recipes
    all_combos = list(iterproduct(MEAL_TYPES, DISEASE_COMBOS_W2, ALLERGEN_COMBOS_W2, BUDGET_LEVELS, GOALS))
    print(f"🚀 Wave 2: {len(all_combos)} combinations × 3 recipes = ~{len(all_combos)*3} recipes")

    db = SessionLocal()
    existing_count = db.query(MealCache).count()
    db.close()
    print(f"📦 Currently in meals_library: {existing_count} recipes")

    if existing_count >= 1200:
        print("✅ meals_library already has 1200+ recipes. Done!")
        return

    start = datetime.now()
    results = await generate_batch(client, all_combos, SessionLocal, max_concurrent=3)
    elapsed = (datetime.now() - start).total_seconds()

    db = SessionLocal()
    total = db.query(MealCache).count()
    db.close()

    print(f"\n{'='*50}")
    print(f"🎉 Wave 2 Complete!")
    print(f"   Added:   {results['added']}")
    print(f"   Skipped: {results['skipped']} (duplicates)")
    print(f"   Errors:  {results['errors']}")
    print(f"   Time:    {elapsed:.0f}s")
    print(f"   TOTAL in meals_library: {total}")
    print(f"{'='*50}")


if __name__ == "__main__":
    asyncio.run(main())
