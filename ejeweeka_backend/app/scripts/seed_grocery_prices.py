"""
Seed: grocery_prices — migrates PRICE_MATRIX from shopping_list_builder.py
into the grocery_prices DB table for dynamic pricing.

Run: python -m app.scripts.seed_grocery_prices
"""

import sys, os
from datetime import datetime
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import engine, Base, SessionLocal
from app.models.grocery_price import GroceryPrice


PRICES = [
    # ── Мясо и птица ──
    {"country": "RU", "city": "Москва", "product_name": "Курица (филе)", "base_price": 350, "premium_price": 402, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Индейка (филе)", "base_price": 550, "premium_price": 632, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Говядина (лопатка)", "base_price": 800, "premium_price": 920, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Свинина (шея)", "base_price": 400, "premium_price": 460, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Печень говяжья", "base_price": 250, "premium_price": 288, "currency": "RUB"},

    # ── Рыба ──
    {"country": "RU", "city": "Москва", "product_name": "Минтай", "base_price": 250, "premium_price": 288, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Хек", "base_price": 280, "premium_price": 322, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Лосось", "base_price": 2500, "premium_price": 2875, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Форель", "base_price": 1200, "premium_price": 1380, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Тунец (консервы)", "base_price": 200, "premium_price": 230, "currency": "RUB"},

    # ── Крупы ──
    {"country": "RU", "city": "Москва", "product_name": "Гречка", "base_price": 80, "premium_price": 92, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Рис белый", "base_price": 100, "premium_price": 115, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Овсянка", "base_price": 50, "premium_price": 58, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Перловка", "base_price": 45, "premium_price": 52, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Макароны", "base_price": 70, "premium_price": 80, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Киноа", "base_price": 600, "premium_price": 690, "currency": "RUB"},

    # ── Молочные ──
    {"country": "RU", "city": "Москва", "product_name": "Молоко 2.5%", "base_price": 80, "premium_price": 92, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Кефир 1%", "base_price": 90, "premium_price": 104, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Творог 5%", "base_price": 350, "premium_price": 402, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Сыр", "base_price": 800, "premium_price": 920, "currency": "RUB"},

    # ── Яйца ──
    {"country": "RU", "city": "Москва", "product_name": "Яйца (10 шт)", "base_price": 100, "premium_price": 115, "currency": "RUB"},

    # ── Овощи ──
    {"country": "RU", "city": "Москва", "product_name": "Капуста белокочанная", "base_price": 40, "premium_price": 46, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Морковь", "base_price": 50, "premium_price": 58, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Картофель", "base_price": 40, "premium_price": 46, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Лук репчатый", "base_price": 35, "premium_price": 40, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Свёкла", "base_price": 40, "premium_price": 46, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Помидор", "base_price": 300, "premium_price": 345, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Огурец", "base_price": 250, "premium_price": 288, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Перец болгарский", "base_price": 400, "premium_price": 460, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Брокколи", "base_price": 350, "premium_price": 402, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Шпинат", "base_price": 800, "premium_price": 920, "currency": "RUB"},

    # ── Фрукты ──
    {"country": "RU", "city": "Москва", "product_name": "Яблоко", "base_price": 120, "premium_price": 138, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Банан", "base_price": 140, "premium_price": 161, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Авокадо", "base_price": 800, "premium_price": 920, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Ягоды замороженные", "base_price": 500, "premium_price": 575, "currency": "RUB"},

    # ── Масла ──
    {"country": "RU", "city": "Москва", "product_name": "Масло подсолнечное", "base_price": 120, "premium_price": 138, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Масло оливковое", "base_price": 1500, "premium_price": 1725, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Масло сливочное", "base_price": 900, "premium_price": 1035, "currency": "RUB"},

    # ── Хлеб ──
    {"country": "RU", "city": "Москва", "product_name": "Хлеб цельнозерновой", "base_price": 80, "premium_price": 92, "currency": "RUB"},

    # ── Бобовые ──
    {"country": "RU", "city": "Москва", "product_name": "Чечевица", "base_price": 150, "premium_price": 172, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Нут", "base_price": 180, "premium_price": 207, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Фасоль", "base_price": 130, "premium_price": 150, "currency": "RUB"},

    # ── Орехи и сухофрукты ──
    {"country": "RU", "city": "Москва", "product_name": "Орехи (микс)", "base_price": 1500, "premium_price": 1725, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Семена льна", "base_price": 200, "premium_price": 230, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Семена чиа", "base_price": 800, "premium_price": 920, "currency": "RUB"},

    # ── Зелень и специи ──
    {"country": "RU", "city": "Москва", "product_name": "Укроп (пучок)", "base_price": 50, "premium_price": 58, "currency": "RUB"},
    {"country": "RU", "city": "Москва", "product_name": "Петрушка (пучок)", "base_price": 50, "premium_price": 58, "currency": "RUB"},

    # ── Морепродукты ──
    {"country": "RU", "city": "Москва", "product_name": "Креветки", "base_price": 1500, "premium_price": 1725, "currency": "RUB"},
]


def main():
    Base.metadata.create_all(bind=engine, tables=[GroceryPrice.__table__])
    db = SessionLocal()
    try:
        if db.query(GroceryPrice).count() > 0:
            print(f"⚠️ grocery_prices already has {db.query(GroceryPrice).count()} entries, skipping")
            return
        now = datetime.utcnow()
        for p in PRICES:
            p["last_updated"] = now
            db.add(GroceryPrice(**p))
        db.commit()
        print(f"✅ Seeded {len(PRICES)} grocery prices (Moscow, RUB)")
    finally:
        db.close()


if __name__ == "__main__":
    main()
