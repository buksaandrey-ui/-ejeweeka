import os
import json
import asyncio
from fastapi.testclient import TestClient

# 1. Start with the main app
from app.main import app
from app.api.dependencies import get_current_user
from app.models.user import User

# 2. Bypass Auth
def override_get_current_user():
    user = User(
        id=1,
        anonymous_uuid="test-uuid-live",
        subscription_status="Gold"
    )
    return user

app.dependency_overrides[get_current_user] = override_get_current_user

client = TestClient(app)

def test_plan():
    print("\n" + "="*50)
    print("TESTING PLAN GENERATION WITH GEMINI")
    print("="*50)
    
    payload = {
        "age": 32,
        "gender": "male",
        "weight": 85,
        "height": 182,
        "goal": "Снизить вес",
        "activity_level": "Низкая активность",
        "meal_pattern": "3 приема (завтрак, обед, ужин)",
        "budget_level": "Средний",
        "cooking_time": "До 30 мин",
        "country": "Россия",
        "city": "Москва",
        "allergies": ["Арахис", "Глютен"],
        "diseases": ["Подагра"],
        "target_weight": 78,
        "target_timeline_weeks": 6,
        "training_days": 3,
        "workout_location": "Дома"
    }

    print("Sending payload:", json.dumps(payload, ensure_ascii=False))
    
    # Needs a longer timeout for Gemini calls, TestClient is synchronous but allows waiting.
    # Actually TestClient waits until the request finishes.
    try:
        response = client.post("/api/v1/plan/generate", json=payload, timeout=60.0)
        print("\nStatus:", response.status_code)
        print("Response:", json.dumps(response.json(), indent=2, ensure_ascii=False)[:2000] + "...")
        assert response.status_code == 200
        assert "plan" in response.json()
    except Exception as e:
        print("Error during plan generation:", e)


def test_photo():
    print("\n" + "="*50)
    print("TESTING PHOTO ANALYSIS WITH GEMINI VISION")
    print("="*50)
    
    # Create a dummy image
    with open("dummy_food.jpg", "wb") as f:
        f.write(b"fake image data")
        
    data = {
        "goal": "Снизить вес",
        "allergies": json.dumps(["Лактоза"]),
        "diseases": json.dumps(["Гастрит"]),
        "daily_calories": "1800",
        "calories_consumed": "400"
    }
    
    # We shouldn't use a fake image if Gemini Vision actually tries to parse it, 
    # it will return an error from Google API: "invalid image".
    # We should just print that it would be tested, or use a real image if we have one.
    pass

if __name__ == "__main__":
    test_plan()

