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
from app.models.recipe_cache import MealCache

env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
load_dotenv(dotenv_path=env_path, override=True)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    GEMINI_API_KEY = GEMINI_API_KEY.strip('"\'')
    print(f"API key loaded: yes, end: {GEMINI_API_KEY[-6:]}")
else:
    print("API key loaded: no")

def generate_hash(recipe_data: dict) -> str:
    """Генерирует уникальный хэш на основе названия и ингредиентов."""
    base_str = recipe_data["name"] + str(recipe_data.get("ingredients", []))
    return hashlib.sha256(base_str.encode('utf-8')).hexdigest()

async def fetch_recipes_batch(client, meal_type: str, condition: str, region: str, budget: str, count: int = 5):
    """Асинхронно просит LLM сгенерировать батч рецептов."""
    prompt = f"""
    Ты - профессиональный wellness-шеф и нутрициолог.
    Сгенерируй массив из {count} уникальных рецептов для приема пищи: {meal_type}.
    Целевая wellness-задача: {condition}.
    
    ВАЖНЫЕ ПАРАМЕТРЫ КОРЗИНЫ:
    Регион проживания: {region}. Используй ТОЛЬКО те ингредиенты, которые массово, легко и круглосуточно доступны в супермаркетах этого региона.
    Бюджет: {budget}. Адаптируй выбор продуктов (например, для "Эконом" избегай дорогих морепродуктов или экзотических ягод, заменяй на локальные аналоги).
    
    Они должны быть здоровыми, сбалансированными и строго подходить под концепцию Wellness & Lifestyle.
    НЕ используй медицинские термины (лечение, пациент, диагноз, вылечить). Заменяй их на "поддержание", "комфорт", "баланс".
    
    Каждый рецепт должен быть уникальным (разные ингредиенты, разные стили кухни).
    
    Верни ТОЛЬКО валидный JSON массив объектов:
    [
      {{
        "name": "Название",
        "meal_type": "{meal_type}",
        "regional_availability": {{"{region}": "{budget}", "Global": "{budget}"}},
        "cooking_time_minutes": 25,
        "calories": 400,
        "protein": 30,
        "fat": 15,
        "carbs": 40,
        "fiber": 8,
        "allergens_present": ["Орехи"],
        "safe_for_diseases": ["{condition}"],
        "rich_in_microelements": ["Железо", "Пребиотики", "Витамин C"],
        "wellness_rationale": "Богато клетчаткой для энергии.",
        "storage_instructions": "Хранить в контейнере до 3 дней",
        "reheating_instructions": "Разогреть в СВЧ 2 минуты",
        "freezable": false,
        "ingredients": ["Курица 100г", "Киноа 50г"],
        "steps": ["Сварить киноа", "Пожарить курицу"]
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
        print(f"Ошибка генерации для {meal_type}: {e}")
        return []

async def main():
    print("🚀 Старт пре-генерации рецептов в базу...")
    client = genai.Client(api_key=GEMINI_API_KEY)
    db = SessionLocal()
    
    meal_types = ["Завтрак", "Обед", "Ужин", "Перекус"]
    conditions = [
        "Общее здоровье", "Снижение веса", "Набор мышечной массы", 
        "Чувствительное пищеварение", "Без лактозы", 
        "Средиземноморская диета"
    ]
    regions = ["СНГ (Россия, Беларусь, Казахстан)", "Европа", "Азия (Таиланд, Бали)"]
    budgets = ["Эконом", "Средний", "Премиум"]
    total_added = 0
    
    # Nested loops
    import random
    
    for region in regions:
        for budget in budgets:
            for condition in conditions:
                for m_type in meal_types:
                    for batch_num in range(8): # 8 batches * 5 recipes = 40 recipes per bucket
                        print(f"Генерация: {region} | {budget} | {m_type} | {condition} (Батч {batch_num + 1})...")
                        recipes = await fetch_recipes_batch(client, m_type, condition, region, budget, count=5)
                        
                        for r in recipes:
                            r_hash = generate_hash(r)
                            
                            # Проверка на дубликат
                            exists = db.query(MealCache).filter(MealCache.ingredients_hash == r_hash).first()
                            if not exists:
                                new_meal = MealCache(
                                    ingredients_hash=r_hash,
                                    name=r.get("name", "Рецепт"),
                                    regional_availability=r.get("regional_availability", {region: budget, "Global": budget}),
                                    cooking_time_minutes=r.get("cooking_time_minutes", 30),
                                    calories=r.get("calories", 0),
                                    protein=r.get("protein", 0),
                                    fat=r.get("fat", 0),
                                    carbs=r.get("carbs", 0),
                                    fiber=r.get("fiber", 0),
                                    meal_type=r.get("meal_type", m_type),
                                    allergens_present=r.get("allergens_present", []),
                                    safe_for_diseases=r.get("safe_for_diseases", [condition]),
                                    rich_in_microelements=r.get("rich_in_microelements", []),
                                    wellness_rationale=r.get("wellness_rationale", ""),
                                    storage_instructions=r.get("storage_instructions", ""),
                                    reheating_instructions=r.get("reheating_instructions", ""),
                                    freezable=r.get("freezable", False),
                                    ingredients=r.get("ingredients", []),
                                    steps=r.get("steps", [])
                                )
                                db.add(new_meal)
                                total_added += 1
                        
                        db.commit()
                        await asyncio.sleep(8) # Увеличенная пауза для избежания 429 Too Many Requests
            
    print(f"✅ Успешно добавлено {total_added} новых рецептов в базу!")
    db.close()

if __name__ == "__main__":
    asyncio.run(main())
