import asyncio
import httpx
import json

async def run():
    url = "http://127.0.0.1:8001/api/v1/plan/generate"
    headers = {"Content-Type": "application/json"}
    data = {
      "age": 46,
      "gender": "female",
      "weight": 65.0,
      "height": 168.0,
      "goal": "Адаптировать питание к возрасту",
      "activity_level": "2 раза в неделю",
      "target_weight": 56.0,
      "target_timeline_weeks": 13,
      "bmi": "23.0",
      "bmi_class": "normal",
      "waist": "76.0",
      "country": "Беларусь",
      "budget_level": "Экономный",
      "cooking_time": "Без разницы",
      "allergies": [],
      "restrictions": ["vegetarian", "no_red_meat", "pescatarian", "no_dairy"],
      "diets": ["vegetarian", "no_red_meat", "pescatarian", "no_dairy"],
      "diseases": ["insulin_resistance"],
      "symptoms": ["constipation", "unstable_stool", "sugar_cravings"],
      "womens_health": ["irregular_cycle", "breastfeeding"],
      "medications": "клайра",
      "supplements": "Нет",
      "fasting_type": "none",
      "tier": "gold"
    }

    async with httpx.AsyncClient(timeout=120) as client:
        response = await client.post(url, headers=headers, json=data)
        if response.status_code == 200:
            print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        else:
            print(response.status_code, response.text)

asyncio.run(run())
