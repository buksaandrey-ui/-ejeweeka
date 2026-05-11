"""
Seed: drinks_library — 55 напитков с КБЖУ на 100 мл.
Детерминированный справочник, без обращений к LLM.

Run: python -m app.scripts.seed_drinks
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import engine, Base, SessionLocal
from app.models.drink_cache import DrinkCache


DRINKS = [
    # ── Вода ──
    {"name": "Вода", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вода минеральная газированная", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ── Чай ──
    {"name": "Чай чёрный (без сахара)", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Чай зелёный (без сахара)", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.2, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Чай травяной (ромашка)", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Чай с молоком", "calories": 16, "protein": 0.8, "fat": 0.8, "carbs": 1.4, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["RU", "GB"]},
    {"name": "Матча латте", "calories": 45, "protein": 2.5, "fat": 1.8, "carbs": 4.5, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ── Кофе ──
    {"name": "Эспрессо", "calories": 2, "protein": 0.1, "fat": 0, "carbs": 0.4, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Американо (без сахара)", "calories": 2, "protein": 0.1, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Капучино", "calories": 40, "protein": 2.4, "fat": 1.8, "carbs": 3.5, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Латте", "calories": 50, "protein": 2.8, "fat": 2.2, "carbs": 4.2, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Раф-кофе", "calories": 85, "protein": 1.8, "fat": 5.0, "carbs": 8.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["RU"]},
    {"name": "Кофе растворимый (без сахара)", "calories": 2, "protein": 0.1, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ── Молочные и кисломолочные ──
    {"name": "Молоко 2.5%", "calories": 52, "protein": 2.8, "fat": 2.5, "carbs": 4.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Молоко 3.2%", "calories": 59, "protein": 2.9, "fat": 3.2, "carbs": 4.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Кефир 1%", "calories": 40, "protein": 3.3, "fat": 1.0, "carbs": 4.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "KZ"]},
    {"name": "Ряженка 2.5%", "calories": 54, "protein": 2.9, "fat": 2.5, "carbs": 4.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Айран", "calories": 24, "protein": 1.1, "fat": 1.0, "carbs": 2.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "TR", "KZ"]},
    {"name": "Тан", "calories": 22, "protein": 1.0, "fat": 0.9, "carbs": 2.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "AM"]},

    # ── Растительное молоко ──
    {"name": "Овсяное молоко", "calories": 43, "protein": 0.5, "fat": 1.5, "carbs": 7.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Миндальное молоко", "calories": 17, "protein": 0.4, "fat": 1.1, "carbs": 1.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Кокосовое молоко (напиток)", "calories": 20, "protein": 0.2, "fat": 1.8, "carbs": 0.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Соевое молоко", "calories": 33, "protein": 2.8, "fat": 1.6, "carbs": 1.8, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ── Соки ──
    {"name": "Апельсиновый сок (свежевыжатый)", "calories": 45, "protein": 0.7, "fat": 0.2, "carbs": 10.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Яблочный сок", "calories": 46, "protein": 0.1, "fat": 0.1, "carbs": 11.3, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Томатный сок", "calories": 18, "protein": 0.8, "fat": 0.1, "carbs": 3.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Морковный сок", "calories": 28, "protein": 0.6, "fat": 0.1, "carbs": 6.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Гранатовый сок", "calories": 54, "protein": 0.3, "fat": 0.1, "carbs": 13.1, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "TR", "AZ"]},

    # ── Смузи и протеин ──
    {"name": "Смузи ягодный", "calories": 55, "protein": 1.0, "fat": 0.3, "carbs": 12.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Протеиновый коктейль (сывороточный)", "calories": 90, "protein": 18.0, "fat": 1.0, "carbs": 3.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ── Газировки и лимонады ──
    {"name": "Кола (Coca-Cola)", "calories": 42, "protein": 0, "fat": 0, "carbs": 10.6, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Кола Zero", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Фанта", "calories": 41, "protein": 0, "fat": 0, "carbs": 10.3, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Лимонад домашний", "calories": 35, "protein": 0.1, "fat": 0, "carbs": 8.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Морс клюквенный", "calories": 30, "protein": 0.1, "fat": 0, "carbs": 7.3, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Компот из сухофруктов", "calories": 38, "protein": 0.2, "fat": 0, "carbs": 9.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "KZ"]},
    {"name": "Квас", "calories": 27, "protein": 0.2, "fat": 0, "carbs": 6.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Комбуча (чайный гриб)", "calories": 13, "protein": 0, "fat": 0, "carbs": 3.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ── Энергетики ──
    {"name": "Red Bull", "calories": 45, "protein": 0, "fat": 0, "carbs": 11.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Red Bull Sugar Free", "calories": 3, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ── Алкоголь ──
    {"name": "Пиво светлое (4.5%)", "calories": 42, "protein": 0.5, "fat": 0, "carbs": 3.5, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Пиво безалкогольное", "calories": 26, "protein": 0.3, "fat": 0, "carbs": 5.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вино красное сухое", "calories": 68, "protein": 0.1, "fat": 0, "carbs": 0.3, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вино белое сухое", "calories": 66, "protein": 0.1, "fat": 0, "carbs": 0.6, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Шампанское Brut", "calories": 75, "protein": 0.1, "fat": 0, "carbs": 1.4, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Водка", "calories": 231, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Виски", "calories": 250, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Ром", "calories": 231, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Коньяк", "calories": 239, "protein": 0, "fat": 0, "carbs": 1.5, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Джин-тоник", "calories": 73, "protein": 0, "fat": 0, "carbs": 7.2, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Мохито", "calories": 64, "protein": 0, "fat": 0, "carbs": 6.3, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ── Специальные ──
    {"name": "Какао на молоке", "calories": 75, "protein": 3.2, "fat": 3.0, "carbs": 8.5, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Цикорий растворимый", "calories": 11, "protein": 0.1, "fat": 0, "carbs": 2.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Кисель", "calories": 53, "protein": 0, "fat": 0, "carbs": 13.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Кокосовая вода", "calories": 19, "protein": 0.7, "fat": 0.2, "carbs": 3.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
]


def main():
    Base.metadata.create_all(bind=engine, tables=[DrinkCache.__table__])
    db = SessionLocal()
    try:
        if db.query(DrinkCache).count() > 0:
            print(f"⚠️ drinks_library already has {db.query(DrinkCache).count()} entries, skipping seed")
            return
        for d in DRINKS:
            db.add(DrinkCache(**d))
        db.commit()
        print(f"✅ Seeded {len(DRINKS)} drinks into drinks_library")
    finally:
        db.close()


if __name__ == "__main__":
    main()
