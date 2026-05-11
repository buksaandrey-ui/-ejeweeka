import os
import sys
import json
from dotenv import load_dotenv

# Нужно для корректных импортов из корня бэкенда
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

load_dotenv()

from google import genai
from pydantic import BaseModel, Field
from sqlalchemy import func
from app.db import SessionLocal
from app.models.grocery_price import GroceryPrice

class ProductItem(BaseModel):
    name: str = Field(description="Универсальное название продукта (например: Куриное филе, Гречка, Яйца десяток, Лосось)")
    estimated_price: float = Field(description="Средняя рыночная цена за 1 кг/шт/упаковку в указанной валюте (строго число)")
    unit: str = Field(description="Единица измерения: кг, уп (упаковка), десяток, шт")

class PriceList(BaseModel):
    items: list[ProductItem]

def generate_prices_for_city(country: str, city: str, currency: str):
    """Генерирует список цен через ИИ для популярных ЗОЖ-продуктов"""
    api_key = os.getenv('GEMINI_API_KEY')
    if not api_key:
        print("Ошибка: GEMINI_API_KEY не установлен.")
        return []

    client = genai.Client(api_key=api_key)
    
    prompt = f"""
    Для страны {country} (г. {city}), сформируй актуальный на текущий год прайс-лист для ~50 самых популярных продуктов здорового питания.
    Тебе нужно вернуть усредненные рыночные цены в валюте {currency} строго в виде JSON.
    Обязательно включи: Куриное филе, Лосось, Говядина, Яйца, Творог, Оливковое масло, Авокадо, Гречка, Рис, Овсянка, Овощи (томаты, огурцы, зелень, брокколи), Фрукты (яблоки, бананы, ягоды), Орехи (миндаль, грецкий).
    Учти, что это средненькие цены супермаркета (не эксклюзив).
    """

    print(f"🌍 Обращаемся к Gemini для формирования базы цен в: {city}, {country} ({currency})...")
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-pro',
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
                'response_schema': PriceList,
                'temperature': 0.2
            }
        )
        
        data = json.loads(response.text)
        return data.get('items', [])
        
    except Exception as e:
        print(f"❌ Ошибка генерации: {e}")
        return []


def update_db_with_prices(country: str, city: str, currency: str, items: list):
    """Обновляет БД, добавляя 15% наценку к базовой стоимости"""
    db = SessionLocal()
    try:
        added = 0
        updated = 0
        
        for item in items:
            name_lower = item['name'].strip().lower()
            base_price = item['estimated_price']
            
            # Наценка 15% для ощущения премиальности (Азбука Вкуса / Whole Foods)
            premium = base_price * 1.15
            
            existing = db.query(GroceryPrice).filter(
                GroceryPrice.country == country,
                GroceryPrice.city == city,
                func.lower(GroceryPrice.product_name) == name_lower
            ).first()
            
            if existing:
                existing.base_price = base_price
                existing.premium_price = premium
                existing.currency = currency
                updated += 1
            else:
                new_price = GroceryPrice(
                    country=country,
                    city=city,
                    product_name=name_lower, # Храним в нижнем регистре для удобного поиска
                    base_price=base_price,
                    premium_price=premium,
                    currency=currency
                )
                db.add(new_price)
                added += 1
                
        db.commit()
        print(f"✅ Успешно! Добавлено новых продуктов: {added}. Обновлено существующих: {updated}.")
    except Exception as e:
        db.rollback()
        print(f"❌ Ошибка БД: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    print("--- 🛒 ejeweeka Grocery Price Updater ---")
    TARGETS = [
        {"country": "Россия", "city": "Москва", "currency": "RUB"},
        # В будущем сюда динамически можно добавлять города юзеров, которых нет в БД.
    ]
    
    for t in TARGETS:
        items = generate_prices_for_city(t["country"], t["city"], t["currency"])
        if items:
            update_db_with_prices(t["country"], t["city"], t["currency"], items)
