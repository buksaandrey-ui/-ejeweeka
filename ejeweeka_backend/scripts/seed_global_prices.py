"""
Seed: global_prices — uses Gemini to estimate baseline grocery prices 
for a wide range of global cities to support Region/City level filtering.
Run: python -m scripts.seed_global_prices
"""

import sys, os, json, asyncio
from datetime import datetime
from google import genai
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from app.db import engine, Base, SessionLocal
from app.models.grocery_price import GroceryPrice

async def generate_with_retry(prompt_contents, max_retries=3):
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    for attempt in range(max_retries):
        try:
            # We use a non-async wrapper if the client is sync, but wrap in thread
            def _call():
                return client.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=prompt_contents
                )
            return await asyncio.to_thread(_call)
        except Exception as e:
            if attempt == max_retries - 1:
                raise e
            await asyncio.sleep(2 ** attempt)

# Full list of countries and cities we want to seed baseline prices for
LOCATIONS = [
    # СНГ
    ("RU", "Москва"), ("RU", "Санкт-Петербург"), ("RU", "Новосибирск"), ("RU", "Екатеринбург"), ("RU", "Казань"),
    ("RU", "Самара"), ("RU", "Ростов-на-Дону"), ("RU", "Уфа"), ("RU", "Краснодар"), ("RU", "Сочи"),
    ("BY", "Минск"), ("KZ", "Алматы"), ("KZ", "Астана"), ("UZ", "Ташкент"), ("GE", "Тбилиси"), ("AM", "Ереван"),
    
    # Европа
    ("DE", "Берлин"), ("DE", "Мюнхен"), ("FR", "Париж"), ("GB", "Лондон"), ("IT", "Рим"), ("ES", "Мадрид"),
    ("ES", "Барселона"), ("NL", "Амстердам"), ("RS", "Белград"), ("CY", "Лимасол"),
    
    # Азия и Ближний Восток
    ("AE", "Дубай"), ("TR", "Стамбул"), ("TR", "Анталья"), ("TH", "Бангкок"), ("TH", "Пхукет"), ("ID", "Бали"),
    
    # Америка и Австралия
    ("US", "Нью-Йорк"), ("US", "Лос-Анджелес"), ("US", "Майами"), ("CA", "Торонто"), ("AR", "Буэнос-Айрес"), 
    ("BR", "Сан-Паулу"), ("AU", "Сидней")
]

PRODUCTS = [
    "Курица (филе)", "Говядина (лопатка)", "Свинина (шея)", "Минтай", "Лосось",
    "Гречка", "Рис белый", "Овсянка", "Макароны", "Молоко 2.5%", "Творог 5%", "Сыр", "Яйца (10 шт)",
    "Капуста белокочанная", "Морковь", "Картофель", "Лук репчатый", "Помидор", "Огурец",
    "Яблоко", "Банан", "Масло подсолнечное", "Масло оливковое", "Хлеб цельнозерновой", "Чечевица"
]

prompt_template = """
Твоя задача — выступить в роли эксперта по стоимости жизни.
Для города {city} (Страна: {country}) сгенерируй средние розничные цены на базовые продукты питания в типичном масс-маркет супермаркете (например, Пятерочка, Carrefour, Walmart, Migros и т.д.).
Верни результат СТРОГО в формате JSON.
Не пиши ничего кроме JSON.

Используй местную валюту (в ISO коде, например, RUB, EUR, USD, TRY, THB, AED).
Для каждого продукта укажи base_price (цена за эконом/стандарт) и premium_price (цена за бренд/качество). 
Все цены за 1 кг (или 1 литр/1 десяток).

Формат JSON:
{{
  "currency": "RUB",
  "prices": [
    {{
      "product_name": "Курица (филе)",
      "base_price": 350,
      "premium_price": 450
    }}
  ]
}}

Список продуктов:
{products_list}
"""

async def seed_city(db, country, city, semaphore):
    async with semaphore:
        # Проверяем, есть ли уже этот город (и хотя бы 10 продуктов)
        existing_count = db.query(GroceryPrice).filter(GroceryPrice.city == city).count()
        if existing_count > 10:
            print(f"⏩ Пропускаем {city} — уже в базе ({existing_count} записей)")
            return

        print(f"⏳ Генерируем цены для {city}...")
        prompt = prompt_template.format(
            country=country,
            city=city,
            products_list=", ".join(PRODUCTS)
        )
        
        try:
            response = await generate_with_retry(prompt)
            rec_text = response.text.replace("```json", "").replace("```", "").strip()
            start_idx = rec_text.find('{')
            if start_idx >= 0:
                rec_text = rec_text[start_idx:]
            
            data = json.loads(rec_text)
            currency = data.get("currency", "USD")
            now = datetime.utcnow()
            
            for item in data.get("prices", []):
                price_record = GroceryPrice(
                    country=country,
                    city=city,
                    product_name=item.get("product_name"),
                    base_price=item.get("base_price", 0),
                    premium_price=item.get("premium_price", 0),
                    currency=currency,
                    last_updated=now
                )
                db.add(price_record)
            
            db.commit()
            print(f"✅ Успешно: {city} (Валюта: {currency})")
            
        except Exception as e:
            print(f"❌ Ошибка для {city}: {e}")
            db.rollback()

async def main_async():
    Base.metadata.create_all(bind=engine, tables=[GroceryPrice.__table__])
    db = SessionLocal()
    
    print(f"🚀 Начинаем парсинг цен для {len(LOCATIONS)} городов...")
    
    # Ограничиваем до 3 параллельных запросов, чтобы не словить Rate Limit от Gemini
    sem = asyncio.Semaphore(3)
    
    tasks = [seed_city(db, country, city, sem) for country, city in LOCATIONS]
    await asyncio.gather(*tasks)
    
    db.close()
    print("🎉 Сидинг глобальных цен завершен!")

if __name__ == "__main__":
    asyncio.run(main_async())
