"""
Seed: drinks_library — baseline drinks with macros per 100ml.
Used for drink logging autocomplete and calorie estimation.
Run: cd ejeweeka_backend && python -m scripts.populate_drinks
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.db import engine, Base, SessionLocal
from app.models.drink_cache import DrinkCache
from sqlalchemy import text

DRINKS = [
    # ────────────── ВОДА ──────────────
    {"name": "Вода", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вода газированная", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вода с лимоном", "calories": 3, "protein": 0, "fat": 0, "carbs": 0.8, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ────────────── ЧАЙ ──────────────
    {"name": "Чай чёрный (без сахара)", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Чай зелёный (без сахара)", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.2, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Чай травяной (ромашка)", "calories": 1, "protein": 0, "fat": 0, "carbs": 0.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Чай с молоком", "calories": 16, "protein": 0.7, "fat": 0.6, "carbs": 1.6, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["RU", "GB", "KZ"]},
    {"name": "Матча латте", "calories": 45, "protein": 2.4, "fat": 1.5, "carbs": 5.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ────────────── КОФЕ ──────────────
    {"name": "Эспрессо", "calories": 2, "protein": 0.1, "fat": 0, "carbs": 0.4, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Американо", "calories": 2, "protein": 0.1, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Капучино", "calories": 36, "protein": 1.8, "fat": 1.4, "carbs": 3.8, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Латте", "calories": 42, "protein": 2.0, "fat": 1.8, "carbs": 3.8, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Флэт Уайт", "calories": 48, "protein": 2.5, "fat": 2.0, "carbs": 4.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Раф кофе", "calories": 90, "protein": 1.5, "fat": 5.0, "carbs": 9.5, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["RU"]},
    {"name": "Кофе растворимый (без сахара)", "calories": 2, "protein": 0.1, "fat": 0, "carbs": 0.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Кофе с сахаром (1 ч.л.)", "calories": 22, "protein": 0.1, "fat": 0, "carbs": 5.3, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Кофе со сливками", "calories": 32, "protein": 0.5, "fat": 2.0, "carbs": 1.8, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Турецкий кофе", "calories": 6, "protein": 0.2, "fat": 0.1, "carbs": 1.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["TR", "AE", "SA"]},

    # ────────────── МОЛОЧНЫЕ ──────────────
    {"name": "Молоко 2.5%", "calories": 52, "protein": 2.8, "fat": 2.5, "carbs": 4.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Молоко обезжиренное", "calories": 34, "protein": 3.4, "fat": 0.1, "carbs": 5.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Кефир 1%", "calories": 40, "protein": 3.0, "fat": 1.0, "carbs": 4.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "KZ", "BY"]},
    {"name": "Ряженка 2.5%", "calories": 54, "protein": 2.9, "fat": 2.5, "carbs": 4.2, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "BY"]},
    {"name": "Айран", "calories": 24, "protein": 1.1, "fat": 1.0, "carbs": 2.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "TR", "KZ"]},
    {"name": "Тан", "calories": 20, "protein": 1.1, "fat": 0.9, "carbs": 1.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "AM", "GE"]},

    # ────────────── РАСТИТЕЛЬНОЕ МОЛОКО ──────────────
    {"name": "Овсяное молоко", "calories": 43, "protein": 0.4, "fat": 1.5, "carbs": 6.7, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Миндальное молоко", "calories": 17, "protein": 0.6, "fat": 1.1, "carbs": 0.6, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Соевое молоко", "calories": 54, "protein": 3.3, "fat": 1.8, "carbs": 6.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Кокосовое молоко (напиток)", "calories": 20, "protein": 0.2, "fat": 1.5, "carbs": 1.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ────────────── СОКИ ──────────────
    {"name": "Апельсиновый сок", "calories": 45, "protein": 0.7, "fat": 0.2, "carbs": 10.4, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Яблочный сок", "calories": 46, "protein": 0.1, "fat": 0.1, "carbs": 11.3, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Грейпфрутовый сок", "calories": 39, "protein": 0.5, "fat": 0.1, "carbs": 9.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Морковный сок", "calories": 28, "protein": 0.6, "fat": 0.1, "carbs": 6.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Томатный сок", "calories": 17, "protein": 0.8, "fat": 0.1, "carbs": 3.6, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Гранатовый сок", "calories": 54, "protein": 0.2, "fat": 0.3, "carbs": 13.1, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ────────────── СМУЗИ & КОКТЕЙЛИ ──────────────
    {"name": "Протеиновый коктейль (сывороточный)", "calories": 60, "protein": 12.0, "fat": 0.5, "carbs": 2.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Смузи банан-клубника", "calories": 52, "protein": 0.8, "fat": 0.3, "carbs": 12.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Смузи зелёный (шпинат+банан)", "calories": 38, "protein": 1.0, "fat": 0.2, "carbs": 8.8, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ────────────── ГАЗИРОВАННЫЕ ──────────────
    {"name": "Кола (Coca-Cola)", "calories": 42, "protein": 0, "fat": 0, "carbs": 10.6, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Кола Zero", "calories": 0, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Фанта", "calories": 48, "protein": 0, "fat": 0, "carbs": 12.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Лимонад (сладкий)", "calories": 40, "protein": 0, "fat": 0, "carbs": 10.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Квас", "calories": 27, "protein": 0.2, "fat": 0, "carbs": 6.8, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "BY", "KZ"]},
    {"name": "Комбуча", "calories": 14, "protein": 0, "fat": 0, "carbs": 3.2, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ────────────── ЭНЕРГЕТИКИ ──────────────
    {"name": "Энергетик (Red Bull)", "calories": 46, "protein": 0, "fat": 0, "carbs": 11.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},
    {"name": "Энергетик без сахара", "calories": 3, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["GLOBAL"]},

    # ────────────── АЛКОГОЛЬ (для логирования) ──────────────
    {"name": "Пиво (светлое 4.5%)", "calories": 43, "protein": 0.5, "fat": 0, "carbs": 3.6, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Пиво безалкогольное", "calories": 22, "protein": 0.3, "fat": 0, "carbs": 5.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вино красное (сухое)", "calories": 83, "protein": 0.1, "fat": 0, "carbs": 2.6, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Вино белое (сухое)", "calories": 82, "protein": 0.1, "fat": 0, "carbs": 2.6, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Шампанское (брют)", "calories": 76, "protein": 0.2, "fat": 0, "carbs": 1.4, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Водка", "calories": 231, "protein": 0, "fat": 0, "carbs": 0, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},
    {"name": "Виски", "calories": 250, "protein": 0, "fat": 0, "carbs": 0.1, "is_alcoholic": True, "has_caffeine": False, "region_tags": ["GLOBAL"]},

    # ────────────── РЕГИОНАЛЬНЫЕ ──────────────
    {"name": "Морс клюквенный", "calories": 35, "protein": 0.1, "fat": 0, "carbs": 8.5, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Компот", "calories": 40, "protein": 0.1, "fat": 0, "carbs": 9.8, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU", "BY", "KZ"]},
    {"name": "Кисель", "calories": 53, "protein": 0.1, "fat": 0, "carbs": 13.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["RU"]},
    {"name": "Кумыс", "calories": 50, "protein": 2.1, "fat": 1.9, "carbs": 5.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["KZ", "KG"]},
    {"name": "Шорле (сок+вода)", "calories": 22, "protein": 0, "fat": 0, "carbs": 5.3, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["DE", "AT", "CH"]},
    {"name": "Ласси (йогуртовый напиток)", "calories": 56, "protein": 2.0, "fat": 1.5, "carbs": 8.0, "is_alcoholic": False, "has_caffeine": False, "region_tags": ["IN"]},
    {"name": "Тайский чай (cha yen)", "calories": 65, "protein": 1.0, "fat": 2.5, "carbs": 10.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["TH"]},
    {"name": "Кофе по-вьетнамски (с молоком)", "calories": 70, "protein": 1.5, "fat": 2.0, "carbs": 12.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["VN"]},
    {"name": "Арабский кофе (гахва)", "calories": 5, "protein": 0.1, "fat": 0.1, "carbs": 1.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["AE", "SA"]},
    {"name": "Сакура латте", "calories": 55, "protein": 2.0, "fat": 2.0, "carbs": 7.0, "is_alcoholic": False, "has_caffeine": True, "region_tags": ["JP", "KR"]},
]


def seed():
    Base.metadata.create_all(bind=engine, tables=[DrinkCache.__table__])
    db = SessionLocal()

    existing = db.query(DrinkCache).count()
    if existing > 0:
        print(f"⚠️  Таблица drinks_library уже содержит {existing} записей. Очищаем...")
        db.execute(text("TRUNCATE TABLE drinks_library RESTART IDENTITY"))
        db.commit()

    added = 0
    for d in DRINKS:
        drink = DrinkCache(
            name=d["name"],
            calories=d["calories"],
            protein=d["protein"],
            fat=d["fat"],
            carbs=d["carbs"],
            is_alcoholic=d["is_alcoholic"],
            has_caffeine=d["has_caffeine"],
            region_tags=d["region_tags"],
        )
        db.add(drink)
        added += 1

    db.commit()
    db.close()
    print(f"✅ Добавлено {added} напитков в drinks_library.")


if __name__ == "__main__":
    seed()
