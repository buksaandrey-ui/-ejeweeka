import requests
import json
import time
import subprocess
import os

print("Starting backend server...")
server_process = subprocess.Popen(["python3", "-m", "uvicorn", "app.main:app", "--port", "8000"])

# Wait for server to start
time.sleep(8)

def test_plan_with_allergies_and_workouts():
    print("\n--- TEST 1: PLAN GENERATION (Allergies + Workouts) ---")
    payload = {
        "age": 30,
        "gender": "male",
        "weight": 80,
        "height": 180,
        "goal": "Снизить вес",
        "activity_level": "Средняя активность",
        "meal_pattern": "3 приема (завтрак, обед, ужин)",
        "budget_level": "Средний",
        "cooking_time": "До 30 мин",
        "country": "Россия",
        "city": "Москва",
        "allergies": ["Орехи", "Рыба"],
        "diseases": ["Гастрит"],
        "target_weight": 75,
        "target_timeline_weeks": 5,
        "training_days": 3,
        "workout_location": "Дома",
        "physical_limitations": ["Осевая нагрузка"]
    }
    
    headers = {"Authorization": "Bearer anonymous_dev_token"}  # Auth middleware in ejeweeka-backend might just accept anything if MOCK is on or token check is light
    
    # We might get 401 if auth fails. Let's see.
    try:
        resp = requests.post("http://127.0.0.1:8000/api/v1/plan/generate", json=payload, headers=headers)
        if resp.status_code == 401:
            print("Auth failed. Need to initialize anonymous session first.")
            auth_resp = requests.post("http://127.0.0.1:8000/api/v1/auth/init", json={"anonymous_uuid":"live_test_uuid"})
            token = auth_resp.json().get("token")
            print("Got token:", token)
            headers["Authorization"] = f"Bearer {token}"
            resp = requests.post("http://127.0.0.1:8000/api/v1/plan/generate", json=payload, headers=headers)
            
        print("Status:", resp.status_code)
        data = resp.json()
        if 'plan' in data:
            print("Success! Got plan.")
            plan = data['plan']
            print(f"BMR: {plan.get('bmr')}, TDEE: {plan.get('tdee')}, Target: {plan.get('target_kcal')}")
            
            # Check workout assigned
            workouts = 0
            for day_k, day_v in plan.get('days', {}).items():
                if 'workout' in day_v and day_v['workout'] is not None:
                    workouts += 1
                    print(f"{day_k} has workout: {day_v['workout'].get('title')}")
            print(f"Total workouts assigned: {workouts}")
            
            # Check allergy exclusions by doing a simple string scan
            plan_str = json.dumps(plan, ensure_ascii=False).lower()
            if "орех" in plan_str or "рыб" in plan_str:
                print("⚠️ WARNING: Found allergen in the plan!")
            else:
                print("✅ Allergens successfully excluded.")
        else:
            print("Error response:", data)
    except Exception as e:
        print("Exception:", e)


test_plan_with_allergies_and_workouts()

print("\nShutting down server...")
server_process.terminate()
