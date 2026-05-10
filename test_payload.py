import requests
import json

payload = {
    "age": 30,
    "gender": "female",
    "weight": 65,
    "height": 165,
    "goal": "Снизить вес",
    "activity_level": "Умеренная",
    "allergies": [],
    "restrictions": [],
    "diseases": [],
    "symptoms": ["Вздутие"],
    "medications": "Нет",
    "supplements": "Нет",
    "supplement_openness": None,
    "country": "Россия",
    "city": "",
    "budget_level": "Средний",
    "cooking_time": "Без разницы",
    "fasting_status": False,
    "meal_pattern": "3 приема (завтрак, обед, ужин)",
    "training_schedule": "Без регулярных тренировок",
    "sleep_schedule": "8 часов",
    "liked_foods": [],
    "disliked_foods": [],
    "excluded_meal_types": [],
    "motivation_barriers": [],
    "womens_health": None,
    "bmi": "23.9",
    "waist": "70",
    "body_type": None,
    "blood_tests": None,
    "activity_multiplier": None,
    "tier": "gold"
}

r = requests.post("http://localhost:8005/api/v1/plan/generate", json=payload)
print(r.status_code)
print(json.dumps(r.json(), ensure_ascii=False, indent=2))
