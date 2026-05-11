import requests
import json

API_URL = "https://aidiet-api.onrender.com/api/v1/plan/generate"

payload = {
    "age": 30,
    "gender": "male",
    "weight": 70,
    "height": 175,
    "goal": "Снизить вес",
    "activity_level": "low",
    "tier": "free",
    "bmi": "22.9",
    "waist": "80"
}

try:
    auth_url = "https://aidiet-api.onrender.com/api/v1/auth/init"
    auth_resp = requests.post(auth_url, json={"device_id": "test_device_2"})
    token = auth_resp.json().get("access_token")
    print("Token:", token)
    
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    response = requests.post(API_URL, json=payload, headers=headers)
    print("Status:", response.status_code)
    try:
        data = response.json()
        print(json.dumps(data, ensure_ascii=False, indent=2)[:1000])
        
        day_1 = data.get('data', {}).get('day_1', [])
        print(f"\nMeals in day_1: {len(day_1)}")
        
        vitamins = [k for k in data.get('data', {}).keys() if k.startswith('vitamins')]
        print(f"Vitamin keys: {vitamins}")
    except Exception as e:
        print("Failed to parse JSON:", response.text[:500])

except Exception as e:
    print(f"Error: {e}")
