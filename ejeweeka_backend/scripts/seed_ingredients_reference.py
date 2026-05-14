"""
Seed: ingredients_reference — USDA-like macronutrient reference table.
Used for post-LLM validation of generated recipes (calorie/macro sanity checks).
Values per 100g of raw product.
Run: cd ejeweeka_backend && python -m scripts.seed_ingredients_reference
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.db import engine, Base, SessionLocal
from app.models.safety_tables import IngredientReference
from sqlalchemy import text

# ═══════════════════════════════════════════════════════════════
# СПРАВОЧНИК (на 100г сырого продукта)
# Источники: USDA FoodData Central, Роспотребнадзор, ФАО
# ═══════════════════════════════════════════════════════════════
PRODUCTS = [
    # ────────────── МЯСО И ПТИЦА ──────────────
    {"name_ru": "Куриная грудка", "name_en": "Chicken breast", "calories": 113, "protein": 23.6, "fat": 1.9, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Куриное бедро", "name_en": "Chicken thigh", "calories": 177, "protein": 18.5, "fat": 11.0, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Индейка (филе)", "name_en": "Turkey breast", "calories": 104, "protein": 23.5, "fat": 1.0, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Говядина (вырезка)", "name_en": "Beef tenderloin", "calories": 158, "protein": 22.0, "fat": 7.5, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": False},
    {"name_ru": "Говядина (фарш 15%)", "name_en": "Ground beef 15%", "calories": 215, "protein": 18.6, "fat": 15.0, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Свинина (корейка)", "name_en": "Pork loin", "calories": 143, "protein": 21.0, "fat": 6.5, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Баранина", "name_en": "Lamb", "calories": 209, "protein": 17.0, "fat": 15.3, "carbs": 0, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": False},
    {"name_ru": "Печень говяжья", "name_en": "Beef liver", "calories": 135, "protein": 20.0, "fat": 3.6, "carbs": 3.9, "fiber": 0, "category": "мясо", "allergen_tags": "", "is_budget_friendly": True},

    # ────────────── РЫБА И МОРЕПРОДУКТЫ ──────────────
    {"name_ru": "Лосось (сёмга)", "name_en": "Salmon", "calories": 208, "protein": 20.0, "fat": 13.5, "carbs": 0, "fiber": 0, "category": "рыба", "allergen_tags": "рыба", "is_budget_friendly": False},
    {"name_ru": "Тунец", "name_en": "Tuna", "calories": 130, "protein": 29.0, "fat": 1.0, "carbs": 0, "fiber": 0, "category": "рыба", "allergen_tags": "рыба", "is_budget_friendly": True},
    {"name_ru": "Треска", "name_en": "Cod", "calories": 82, "protein": 18.0, "fat": 0.7, "carbs": 0, "fiber": 0, "category": "рыба", "allergen_tags": "рыба", "is_budget_friendly": True},
    {"name_ru": "Минтай", "name_en": "Pollock", "calories": 72, "protein": 15.9, "fat": 0.9, "carbs": 0, "fiber": 0, "category": "рыба", "allergen_tags": "рыба", "is_budget_friendly": True},
    {"name_ru": "Креветки", "name_en": "Shrimp", "calories": 99, "protein": 20.1, "fat": 1.7, "carbs": 0.2, "fiber": 0, "category": "рыба", "allergen_tags": "ракообразные", "is_budget_friendly": False},
    {"name_ru": "Скумбрия", "name_en": "Mackerel", "calories": 262, "protein": 18.0, "fat": 18.0, "carbs": 0, "fiber": 0, "category": "рыба", "allergen_tags": "рыба", "is_budget_friendly": True},

    # ────────────── КРУПЫ И БОБОВЫЕ ──────────────
    {"name_ru": "Рис белый (сухой)", "name_en": "White rice (dry)", "calories": 360, "protein": 6.7, "fat": 0.7, "carbs": 79.0, "fiber": 0.4, "category": "крупы", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Рис бурый (сухой)", "name_en": "Brown rice (dry)", "calories": 362, "protein": 7.5, "fat": 2.7, "carbs": 73.0, "fiber": 3.4, "category": "крупы", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Гречка (сухая)", "name_en": "Buckwheat (dry)", "calories": 343, "protein": 13.3, "fat": 3.4, "carbs": 68.0, "fiber": 10.0, "category": "крупы", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Овсянка (хлопья)", "name_en": "Oats (rolled)", "calories": 379, "protein": 13.2, "fat": 6.5, "carbs": 66.0, "fiber": 10.1, "category": "крупы", "allergen_tags": "глютен", "is_budget_friendly": True},
    {"name_ru": "Киноа (сухая)", "name_en": "Quinoa (dry)", "calories": 368, "protein": 14.1, "fat": 6.1, "carbs": 64.0, "fiber": 7.0, "category": "крупы", "allergen_tags": "", "is_budget_friendly": False},
    {"name_ru": "Булгур (сухой)", "name_en": "Bulgur (dry)", "calories": 342, "protein": 12.3, "fat": 1.3, "carbs": 63.4, "fiber": 18.3, "category": "крупы", "allergen_tags": "глютен", "is_budget_friendly": True},
    {"name_ru": "Чечевица (сухая)", "name_en": "Lentils (dry)", "calories": 352, "protein": 24.6, "fat": 1.1, "carbs": 53.0, "fiber": 11.5, "category": "бобовые", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Нут (сухой)", "name_en": "Chickpeas (dry)", "calories": 364, "protein": 19.3, "fat": 6.0, "carbs": 61.0, "fiber": 17.4, "category": "бобовые", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Фасоль красная (сухая)", "name_en": "Red kidney beans (dry)", "calories": 337, "protein": 22.5, "fat": 1.1, "carbs": 52.0, "fiber": 25.0, "category": "бобовые", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Горох (сухой)", "name_en": "Green peas (dry)", "calories": 298, "protein": 20.5, "fat": 2.0, "carbs": 49.5, "fiber": 11.2, "category": "бобовые", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Макароны (сухие)", "name_en": "Pasta (dry)", "calories": 350, "protein": 12.5, "fat": 1.4, "carbs": 71.0, "fiber": 3.2, "category": "крупы", "allergen_tags": "глютен", "is_budget_friendly": True},

    # ────────────── МОЛОЧНЫЕ ПРОДУКТЫ ──────────────
    {"name_ru": "Молоко 2.5%", "name_en": "Milk 2.5%", "calories": 52, "protein": 2.8, "fat": 2.5, "carbs": 4.7, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
    {"name_ru": "Кефир 1%", "name_en": "Kefir 1%", "calories": 40, "protein": 3.0, "fat": 1.0, "carbs": 4.0, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
    {"name_ru": "Творог 5%", "name_en": "Cottage cheese 5%", "calories": 121, "protein": 17.2, "fat": 5.0, "carbs": 1.8, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
    {"name_ru": "Творог обезжиренный", "name_en": "Cottage cheese 0%", "calories": 71, "protein": 18.0, "fat": 0.6, "carbs": 1.5, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
    {"name_ru": "Сыр твёрдый", "name_en": "Hard cheese", "calories": 370, "protein": 26.0, "fat": 29.0, "carbs": 0, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": False},
    {"name_ru": "Греческий йогурт", "name_en": "Greek yogurt", "calories": 59, "protein": 10.0, "fat": 0.7, "carbs": 3.6, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
    {"name_ru": "Сметана 15%", "name_en": "Sour cream 15%", "calories": 162, "protein": 2.6, "fat": 15.0, "carbs": 3.6, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},

    # ────────────── ЯЙЦА ──────────────
    {"name_ru": "Яйцо куриное (целое)", "name_en": "Chicken egg", "calories": 155, "protein": 12.6, "fat": 10.6, "carbs": 1.1, "fiber": 0, "category": "яйца", "allergen_tags": "яйца", "is_budget_friendly": True},
    {"name_ru": "Яичный белок", "name_en": "Egg white", "calories": 48, "protein": 11.0, "fat": 0.2, "carbs": 0.7, "fiber": 0, "category": "яйца", "allergen_tags": "яйца", "is_budget_friendly": True},

    # ────────────── ОВОЩИ ──────────────
    {"name_ru": "Картофель", "name_en": "Potato", "calories": 77, "protein": 2.0, "fat": 0.1, "carbs": 17.0, "fiber": 2.2, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Батат (сладкий картофель)", "name_en": "Sweet potato", "calories": 86, "protein": 1.6, "fat": 0.1, "carbs": 20.0, "fiber": 3.0, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Помидор", "name_en": "Tomato", "calories": 18, "protein": 0.9, "fat": 0.2, "carbs": 3.9, "fiber": 1.2, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Огурец", "name_en": "Cucumber", "calories": 14, "protein": 0.7, "fat": 0.1, "carbs": 2.5, "fiber": 0.5, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Морковь", "name_en": "Carrot", "calories": 41, "protein": 0.9, "fat": 0.2, "carbs": 9.6, "fiber": 2.8, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Капуста белокочанная", "name_en": "White cabbage", "calories": 27, "protein": 1.3, "fat": 0.1, "carbs": 4.7, "fiber": 2.0, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Брокколи", "name_en": "Broccoli", "calories": 34, "protein": 2.8, "fat": 0.4, "carbs": 6.6, "fiber": 2.6, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Цветная капуста", "name_en": "Cauliflower", "calories": 25, "protein": 1.9, "fat": 0.3, "carbs": 5.0, "fiber": 2.0, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Шпинат", "name_en": "Spinach", "calories": 23, "protein": 2.9, "fat": 0.4, "carbs": 3.6, "fiber": 2.2, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Лук репчатый", "name_en": "Onion", "calories": 40, "protein": 1.1, "fat": 0.1, "carbs": 9.3, "fiber": 1.7, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Чеснок", "name_en": "Garlic", "calories": 149, "protein": 6.4, "fat": 0.5, "carbs": 33.1, "fiber": 2.1, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Перец болгарский", "name_en": "Bell pepper", "calories": 27, "protein": 1.3, "fat": 0, "carbs": 5.3, "fiber": 1.4, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Кабачок (цуккини)", "name_en": "Zucchini", "calories": 17, "protein": 1.2, "fat": 0.3, "carbs": 3.1, "fiber": 1.0, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Баклажан", "name_en": "Eggplant", "calories": 25, "protein": 1.0, "fat": 0.2, "carbs": 5.9, "fiber": 3.0, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Свёкла", "name_en": "Beet", "calories": 43, "protein": 1.6, "fat": 0.2, "carbs": 9.6, "fiber": 2.8, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Тыква", "name_en": "Pumpkin", "calories": 26, "protein": 1.0, "fat": 0.1, "carbs": 6.5, "fiber": 0.5, "category": "овощи", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Авокадо", "name_en": "Avocado", "calories": 160, "protein": 2.0, "fat": 14.7, "carbs": 8.5, "fiber": 6.7, "category": "овощи", "allergen_tags": "", "is_budget_friendly": False},

    # ────────────── ФРУКТЫ ──────────────
    {"name_ru": "Яблоко", "name_en": "Apple", "calories": 52, "protein": 0.3, "fat": 0.2, "carbs": 14.0, "fiber": 2.4, "category": "фрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Банан", "name_en": "Banana", "calories": 89, "protein": 1.1, "fat": 0.3, "carbs": 22.8, "fiber": 2.6, "category": "фрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Апельсин", "name_en": "Orange", "calories": 43, "protein": 0.9, "fat": 0.1, "carbs": 8.1, "fiber": 2.2, "category": "фрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Грейпфрут", "name_en": "Grapefruit", "calories": 42, "protein": 0.8, "fat": 0.1, "carbs": 10.7, "fiber": 1.6, "category": "фрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Клубника", "name_en": "Strawberry", "calories": 32, "protein": 0.7, "fat": 0.3, "carbs": 7.7, "fiber": 2.0, "category": "фрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Черника", "name_en": "Blueberry", "calories": 57, "protein": 0.7, "fat": 0.3, "carbs": 14.5, "fiber": 2.4, "category": "фрукты", "allergen_tags": "", "is_budget_friendly": False},

    # ────────────── ОРЕХИ И СЕМЕНА ──────────────
    {"name_ru": "Миндаль", "name_en": "Almond", "calories": 579, "protein": 21.2, "fat": 49.9, "carbs": 21.7, "fiber": 12.5, "category": "орехи", "allergen_tags": "орехи", "is_budget_friendly": False},
    {"name_ru": "Грецкий орех", "name_en": "Walnut", "calories": 654, "protein": 15.2, "fat": 65.2, "carbs": 13.7, "fiber": 6.7, "category": "орехи", "allergen_tags": "орехи", "is_budget_friendly": False},
    {"name_ru": "Арахис", "name_en": "Peanut", "calories": 567, "protein": 25.8, "fat": 49.2, "carbs": 16.1, "fiber": 8.5, "category": "орехи", "allergen_tags": "орехи, арахис", "is_budget_friendly": True},
    {"name_ru": "Семена льна", "name_en": "Flaxseed", "calories": 534, "protein": 18.3, "fat": 42.2, "carbs": 28.9, "fiber": 27.3, "category": "семена", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Семена чиа", "name_en": "Chia seeds", "calories": 486, "protein": 16.5, "fat": 30.7, "carbs": 42.1, "fiber": 34.4, "category": "семена", "allergen_tags": "", "is_budget_friendly": False},
    {"name_ru": "Семена подсолнуха", "name_en": "Sunflower seeds", "calories": 584, "protein": 20.8, "fat": 51.5, "carbs": 20.0, "fiber": 8.6, "category": "семена", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Тыквенные семечки", "name_en": "Pumpkin seeds", "calories": 559, "protein": 30.2, "fat": 49.1, "carbs": 10.7, "fiber": 6.0, "category": "семена", "allergen_tags": "", "is_budget_friendly": True},

    # ────────────── МАСЛА И ЖИРЫ ──────────────
    {"name_ru": "Масло оливковое", "name_en": "Olive oil", "calories": 884, "protein": 0, "fat": 100, "carbs": 0, "fiber": 0, "category": "масла", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Масло подсолнечное", "name_en": "Sunflower oil", "calories": 884, "protein": 0, "fat": 100, "carbs": 0, "fiber": 0, "category": "масла", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Масло сливочное", "name_en": "Butter", "calories": 717, "protein": 0.9, "fat": 81.1, "carbs": 0.1, "fiber": 0, "category": "масла", "allergen_tags": "лактоза", "is_budget_friendly": True},
    {"name_ru": "Масло кокосовое", "name_en": "Coconut oil", "calories": 862, "protein": 0, "fat": 99.1, "carbs": 0, "fiber": 0, "category": "масла", "allergen_tags": "", "is_budget_friendly": False},

    # ────────────── ХЛЕБ И ВЫПЕЧКА ──────────────
    {"name_ru": "Хлеб белый", "name_en": "White bread", "calories": 265, "protein": 7.6, "fat": 3.3, "carbs": 49.0, "fiber": 2.7, "category": "хлеб", "allergen_tags": "глютен", "is_budget_friendly": True},
    {"name_ru": "Хлеб цельнозерновой", "name_en": "Whole wheat bread", "calories": 247, "protein": 13.0, "fat": 3.4, "carbs": 41.3, "fiber": 6.0, "category": "хлеб", "allergen_tags": "глютен", "is_budget_friendly": True},
    {"name_ru": "Лаваш тонкий", "name_en": "Lavash", "calories": 275, "protein": 9.1, "fat": 1.2, "carbs": 56.0, "fiber": 2.2, "category": "хлеб", "allergen_tags": "глютен", "is_budget_friendly": True},

    # ────────────── ПРОЧЕЕ ──────────────
    {"name_ru": "Мёд", "name_en": "Honey", "calories": 304, "protein": 0.3, "fat": 0, "carbs": 82.4, "fiber": 0.2, "category": "прочее", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Тофу", "name_en": "Tofu", "calories": 76, "protein": 8.1, "fat": 4.8, "carbs": 1.9, "fiber": 0.3, "category": "бобовые", "allergen_tags": "соя", "is_budget_friendly": True},
    {"name_ru": "Курага", "name_en": "Dried apricots", "calories": 241, "protein": 3.4, "fat": 0.5, "carbs": 62.6, "fiber": 7.3, "category": "сухофрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Финики", "name_en": "Dates", "calories": 277, "protein": 1.8, "fat": 0.2, "carbs": 75.0, "fiber": 6.7, "category": "сухофрукты", "allergen_tags": "", "is_budget_friendly": True},
    {"name_ru": "Шоколад тёмный (70%+)", "name_en": "Dark chocolate 70%", "calories": 598, "protein": 7.8, "fat": 42.6, "carbs": 45.9, "fiber": 10.9, "category": "прочее", "allergen_tags": "", "is_budget_friendly": False},
    {"name_ru": "Сахар", "name_en": "Sugar", "calories": 387, "protein": 0, "fat": 0, "carbs": 100, "fiber": 0, "category": "прочее", "allergen_tags": "", "is_budget_friendly": True},
]


def seed():
    Base.metadata.create_all(bind=engine, tables=[IngredientReference.__table__])
    db = SessionLocal()

    existing = db.query(IngredientReference).count()
    if existing > 0:
        print(f"⚠️  Таблица ingredients_reference уже содержит {existing} записей. Очищаем...")
        db.execute(text("TRUNCATE TABLE ingredients_reference RESTART IDENTITY"))
        db.commit()

    added = 0
    for p in PRODUCTS:
        ref = IngredientReference(
            name_ru=p["name_ru"],
            name_en=p.get("name_en"),
            calories=p["calories"],
            protein=p["protein"],
            fat=p["fat"],
            carbs=p["carbs"],
            fiber=p["fiber"],
            category=p.get("category"),
            allergen_tags=p.get("allergen_tags"),
            is_budget_friendly=p.get("is_budget_friendly", True),
        )
        db.add(ref)
        added += 1

    db.commit()
    db.close()
    print(f"✅ Добавлено {added} продуктов в справочник ingredients_reference.")


if __name__ == "__main__":
    seed()
