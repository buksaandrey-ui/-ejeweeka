"""
Mass Seed: meals_library — systematically generates recipes for ALL
combinations of meal_type × disease × allergen × budget.

This is the ONE-TIME script that makes PlanRouter work without Gemini.
After running, 90%+ of plan generations will be served from cache.

Run: python -m app.scripts.seed_meals_mass
"""

import asyncio
import os
import sys
import json
import hashlib
from datetime import datetime
from itertools import product as iterproduct

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import SessionLocal
from app.models.recipe_cache import MealCache

# ═══════════════════════════════════════════
# GENERATION MATRIX
# ═══════════════════════════════════════════

MEAL_TYPES = ["Завтрак", "Обед", "Ужин", "Перекус"]

DISEASE_COMBOS = [
    [],                     # Здоровый
    ["Гастрит"],
    ["Диабет 2 типа"],
    ["Подагра"],
    ["Гипертония"],
]

ALLERGEN_COMBOS = [
    [],                         # Без аллергий
    ["Лактоза"],
    ["Глютен"],
    ["Орехи", "Арахис"],
    ["Рыба", "Морепродукты"],
]

BUDGET_LEVELS = ["Экономный", "Средний"]

# Total: 4 × 5 × 5 × 2 = 200 combinations × 3 recipes = 600 recipes


def build_prompt(meal_type: str, diseases: list, allergens: list, budget: str) -> str:
    """Build a deterministic prompt for recipe generation."""
    prompt = f"""Ты профессиональный нутрициолог ejeweeka. Сгенерируй 3 уникальных рецепта для: {meal_type}.

ПРАВИЛА:
- Каждый рецепт содержит КБЖУ, ингредиенты с граммовками и пошаговую инструкцию.
- Бюджет: {budget}. {'Используй только дешёвые продукты масс-маркета.' if budget == 'Экономный' else 'Средний ценовой сегмент.'}
"""
    if diseases:
        prompt += f"- Заболевания: {', '.join(diseases)}. Блюда АБСОЛЮТНО безопасны при этих заболеваниях.\n"
    if allergens:
        prompt += f"- Аллергии: {', '.join(allergens)}. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНЫ эти продукты и их производные.\n"

    prompt += """
СТРОГОЕ ПРАВИЛО ДЛЯ ШАГОВ (НАРЕЗКА):
При любом упоминании нарезки, шинковки или кусков (кубиками, соломкой, слайсами) ОБЯЗАТЕЛЬНО указывай примерный физический размер в мм или см (например, "нарежьте кубиками 1х1 см", "соломкой толщиной 2 мм", "слайсами по 5 мм").

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


async def generate_batch(client, combo_queue: list, db_session_factory, max_concurrent: int = 3):
    """Process combos with rate limiting."""
    semaphore = asyncio.Semaphore(max_concurrent)
    results = {"added": 0, "skipped": 0, "errors": 0}

    async def process_one(combo):
        async with semaphore:
            meal_type, diseases, allergens, budget = combo
            label = f"{meal_type} | D:{diseases or '—'} | A:{allergens or '—'} | B:{budget}"

            prompt = build_prompt(meal_type, diseases, allergens, budget)

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
                    # Check duplicate
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
                        allergens_present=allergens,  # Tag with the excluded allergens
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

            # Rate limit: 0.5s between requests to avoid 429
            await asyncio.sleep(0.5)

    tasks = [process_one(combo) for combo in combo_queue]
    await asyncio.gather(*tasks)
    return results


async def main():
    from google import genai

    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    if not GEMINI_API_KEY:
        print("❌ GEMINI_API_KEY not set. Run: export GEMINI_API_KEY=your_key")
        return

    client = genai.Client(api_key=GEMINI_API_KEY)

    # Build full combination matrix
    all_combos = list(iterproduct(MEAL_TYPES, DISEASE_COMBOS, ALLERGEN_COMBOS, BUDGET_LEVELS))
    print(f"🚀 Mass Meal Seed: {len(all_combos)} combinations × 3 recipes = ~{len(all_combos)*3} recipes")

    # Check how many already exist
    db = SessionLocal()
    existing_count = db.query(MealCache).count()
    db.close()
    print(f"📦 Currently in meals_library: {existing_count} recipes")

    if existing_count >= 500:
        print("✅ meals_library already has 500+ recipes. Skipping mass seed.")
        print("   To force re-seed, clear the table first.")
        return

    start = datetime.now()
    results = await generate_batch(client, all_combos, SessionLocal, max_concurrent=3)
    elapsed = (datetime.now() - start).total_seconds()

    print(f"\n{'='*50}")
    print(f"🎉 Mass Seed Complete!")
    print(f"   Added:   {results['added']}")
    print(f"   Skipped: {results['skipped']} (duplicates)")
    print(f"   Errors:  {results['errors']}")
    print(f"   Time:    {elapsed:.0f}s")
    print(f"{'='*50}")


if __name__ == "__main__":
    asyncio.run(main())
