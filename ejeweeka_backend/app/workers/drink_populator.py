import asyncio
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import SessionLocal
from app.models.drink_cache import DrinkCache
from sqlalchemy import text

# Хардкодная база напитков на 100 мл
DRINKS_DATA = [
    # Вода и базовые
    {"name": "Вода", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Черный чай", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Зеленый чай", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.2, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Кофе (Черный)", "calories": 2, "protein": 0.2, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Капучино", "calories": 45, "protein": 3.0, "fat": 2.0, "carbs": 3.8, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    
    # Соки и Газировки
    {"name": "Апельсиновый сок", "calories": 45, "protein": 0.7, "fat": 0.2, "carbs": 10.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Кока-Кола", "calories": 42, "protein": 0, "fat": 0, "carbs": 10.6, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    
    # Алкоголь
    {"name": "Пиво светлое", "calories": 43, "protein": 0.5, "fat": 0, "carbs": 3.6, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вино красное", "calories": 85, "protein": 0.1, "fat": 0, "carbs": 2.6, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Водка", "calories": 231, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    
    # Региональные
    {"name": "Квас", "calories": 27, "protein": 0.2, "fat": 0, "carbs": 5.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "CIS"]},
    {"name": "Кумыс", "calories": 50, "protein": 2.1, "fat": 1.9, "carbs": 5.0, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["KZ", "UZ", "RU"]}, # Слабый алкоголь
    {"name": "Мате", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.2, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["AR", "BR", "UY", "GLOBAL"]},
    {"name": "Комбуча", "calories": 15, "protein": 0, "fat": 0, "carbs": 3.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["US", "AU", "GLOBAL"]},
    {"name": "Карак чай", "calories": 60, "protein": 1.5, "fat": 2.0, "carbs": 9.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["UAE", "SA", "QA"]},
]

def run():
    print("🚀 Запуск Drink Populator...")
    db = SessionLocal()
    try:
        # Create table if not exists (for sqlite/local dev)
        db.execute(text("""
            CREATE TABLE IF NOT EXISTS drinks_library (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) UNIQUE NOT NULL,
                calories FLOAT DEFAULT 0,
                protein FLOAT DEFAULT 0,
                fat FLOAT DEFAULT 0,
                carbs FLOAT DEFAULT 0,
                is_alcoholic BOOLEAN DEFAULT FALSE,
                has_caffeine BOOLEAN DEFAULT FALSE,
                region_tags JSON DEFAULT '["GLOBAL"]'
            )
        """))
        db.commit()

        added = 0
        for d in DRINKS_DATA:
            existing = db.query(DrinkCache).filter(DrinkCache.name == d["name"]).first()
            if not existing:
                drink = DrinkCache(**d)
                db.add(drink)
                added += 1
        db.commit()
        print(f"✅ Успешно добавлено {added} новых напитков.")
    except Exception as e:
        db.rollback()
        print("❌ Ошибка:", e)
    finally:
        db.close()

if __name__ == "__main__":
    run()
