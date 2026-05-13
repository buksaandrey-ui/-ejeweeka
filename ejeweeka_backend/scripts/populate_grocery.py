import asyncio
import os
import json
from dotenv import load_dotenv

import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google import genai
from app.db import SessionLocal, engine
from app.models.grocery_price import GroceryPrice
from app.db import Base

env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
load_dotenv(dotenv_path=env_path, override=True)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    GEMINI_API_KEY = GEMINI_API_KEY.strip('"\'')
    print(f"API key loaded: yes, end: {GEMINI_API_KEY[-6:]}")
else:
    print("API key loaded: no")

async def fetch_grocery_batch(client, region: str, city: str, currency: str, category: str):
    prompt = f"""
    Ты - аналитик продовольственных рынков.
    Твоя задача: собрать реалистичные цены на 20 самых популярных базовых продуктов в супермаркетах для региона: {region} (город: {city}).
    Валюта: {currency}. Категория продуктов: {category} (например: Мясо и рыба, Овощи, Фрукты, Крупы, Молочка).
    Укажи базовую цену (за 1 кг, 1 литр или 1 десяток) и премиум цену (в дорогих супермаркетах, +15-30%).
    
    Верни ТОЛЬКО валидный JSON массив объектов:
    [
      {{
        "product_name": "Куриное филе (1 кг)",
        "base_price": 400.0,
        "premium_price": 550.0
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
        print(f"Ошибка генерации для {region}/{category}: {e}")
        return []

async def main():
    print("🚀 Старт генерации продуктовой корзины...")
    Base.metadata.create_all(bind=engine, tables=[GroceryPrice.__table__])
    
    client = genai.Client(api_key=GEMINI_API_KEY)
    db = SessionLocal()
    
    # Глобальная карта стран, городов и их локальных валют
    regions = [
        {"country": "Россия", "city": "Москва", "currency": "RUB"},
        {"country": "Беларусь", "city": "Минск", "currency": "BYN"},
        {"country": "Казахстан", "city": "Алматы", "currency": "KZT"},
        {"country": "Узбекистан", "city": "Ташкент", "currency": "UZS"},
        {"country": "Европа (Германия)", "city": "Берлин", "currency": "EUR"},
        {"country": "Азия (Индонезия)", "city": "Бали", "currency": "IDR"},
        {"country": "Таиланд", "city": "Бангкок", "currency": "THB"},
        {"country": "Австралия", "city": "Сидней", "currency": "AUD"},
        {"country": "США", "city": "Нью-Йорк", "currency": "USD"},
        {"country": "ОАЭ", "city": "Дубай", "currency": "AED"},
        {"country": "Аргентина", "city": "Буэнос-Айрес", "currency": "ARS"},
        {"country": "Чили", "city": "Сантьяго", "currency": "CLP"},
        {"country": "ЮАР", "city": "Кейптаун", "currency": "ZAR"}
    ]
    categories = ["Мясо и птица", "Рыба и морепродукты", "Овощи и зелень", "Фрукты и ягоды", "Крупы и бакалея", "Молочные продукты и яйца", "Масла и соусы", "Орехи и сухофрукты"]
    
    total_added = 0
    
    for r in regions:
        for cat in categories:
            print(f"Генерация: {r['country']} ({r['city']}) - {cat}...")
            items = await fetch_grocery_batch(client, r['country'], r['city'], r['currency'], cat)
            
            for item in items:
                exists = db.query(GroceryPrice).filter(
                    GroceryPrice.country == r['country'],
                    GroceryPrice.city == r['city'],
                    GroceryPrice.product_name == item.get("product_name")
                ).first()
                
                if not exists:
                    new_price = GroceryPrice(
                        country=r['country'],
                        city=r['city'],
                        product_name=item.get("product_name"),
                        base_price=float(item.get("base_price", 0)),
                        premium_price=float(item.get("premium_price", 0)),
                        currency=r['currency']
                    )
                    db.add(new_price)
                    total_added += 1
                    
            db.commit()
            await asyncio.sleep(2) # Пауза против rate-limit
            
    print(f"✅ Успешно добавлено {total_added} цен на продукты в базу!")
    db.close()

if __name__ == "__main__":
    asyncio.run(main())
