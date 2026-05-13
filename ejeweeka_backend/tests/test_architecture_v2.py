import asyncio
import os
import sys
import json
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from dotenv import load_dotenv
load_dotenv(override=True)

from app.api.plan import generate_plan, UserProfilePayload
from app.db import SessionLocal
from fastapi import Request
from starlette.datastructures import Headers

class MockRequest(Request):
    def __init__(self):
        super().__init__({
            "type": "http", 
            "headers": [],
            "path": "/api/v1/plan/generate",
            "client": ("127.0.0.1", 8000)
        })
        self._headers = Headers()

    @property
    def headers(self):
        return self._headers
        
    @property
    def client(self):
        class MockClient:
            host = "127.0.0.1"
        return MockClient()

profiles = [
    {
        "age": 28, "gender": "female", "weight": 60, "height": 165,
        "goal": "снижение веса", "activity_level": "moderate",
        "country": "ОАЭ", "tier": "white", "budget_level": "Премиум",
        "allergies": ["молоко"], "restrictions": ["халяль"],
        "meal_pattern": "5 раз в день (дробное)",
        "cooking_style": "каждый день"
    },
    {
        "age": 35, "gender": "male", "weight": 90, "height": 185,
        "goal": "набрать мышечную массу", "activity_level": "high",
        "country": "Россия", "tier": "black", "budget_level": "Средний",
        "allergies": ["орехи"], "restrictions": [], "diseases": ["диабет"],
        "meal_pattern": "3 приема",
        "cooking_style": "раз в неделю",
        "fasting_type": "periodic",
        "periodic_days": [2] # Голодание на второй день
    },
    {
        "age": 22, "gender": "female", "weight": 55, "height": 160,
        "goal": "поддержание веса", "activity_level": "moderate",
        "country": "Россия", "tier": "white", "budget_level": "Премиум",
        "allergies": [], "restrictions": ["веганство"], 
        "meal_pattern": "3 приема",
        "cooking_style": "none",
        "shopping_frequency": "daily"
    }
]

class MockBackgroundTasks:
    def add_task(self, func, *args, **kwargs):
        pass

async def run_tests():
    print("🚀 Запуск валидации Архитектуры 2.0 (Variants & Auto-Seeding)...")
    db = SessionLocal()
    req = MockRequest()
    bg = MockBackgroundTasks()
    
    for i, p in enumerate(profiles):
        profile = UserProfilePayload(**p)
        print(f"\\n--- Профиль {i+1} ---")
        print(f"Цель: {profile.goal}, Аллергии: {profile.allergies}, Ограничения: {profile.restrictions}")
        
        start_time = time.time()
        data = await generate_plan(request=req, profile=profile, background_tasks=bg, db=db, user_id="test-user")
        end_time = time.time()
        
        plan = data.get("data", {})
        
        print(f"✅ Успех за {end_time - start_time:.2f} сек.")
        print(f"Days generated: {data.get('days_generated')}, Meals per day: {data.get('meals_per_day')}")
        
        for day_key, day_data in plan.items():
            if not day_key.startswith("day_"): continue
            
            if day_data.get("fasting_day"):
                print(f"  {day_key}: 🧘 День голодания. {day_data.get('tip')}")
                continue
                
            meals = day_data.get("meals", [])
            print(f"  {day_key}: {len(meals)} вариантов блюд")
            
            type_counts = {}
            for m in meals:
                t = m.get("meal_type")
                type_counts[t] = type_counts.get(t, 0) + 1
                
            for t, c in type_counts.items():
                print(f"    {t}: {c} вариантов")
                
        # Shopping List calculation test
        from app.services.shopping_list_builder import build_shopping_list
        shop = build_shopping_list(plan, profile.budget_level, profile.country)
        print(f"🛒 Корзина покупок: {len(shop['items'])} уникальных товаров, Примерная стоимость: {shop['total_estimated_cost']} {shop['currency_symbol']}")


if __name__ == "__main__":
    asyncio.run(run_tests())

