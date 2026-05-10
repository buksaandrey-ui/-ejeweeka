async function test() {
  const initRes = await fetch('https://aidiet-api.onrender.com/api/v1/auth/init', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ initData: 'dummy', platform: 'web' })
  });
  const authData = await initRes.json();
  const token = authData.token || authData.access_token;

  const res = await fetch('https://aidiet-api.onrender.com/api/v1/plan/generate', {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token
    },
    body: JSON.stringify({
      "age": 30, "gender": "male", "weight": 80, "height": 180, "goal": "Сбалансированное питание",
      "activity_level": "Умеренная", "activity_multiplier": null, "allergies": [], "restrictions": [],
      "diseases": [], "symptoms": [], "medications": "Нет", "supplements": "Нет", "supplement_openness": null,
      "country": "Россия", "city": "", "budget_level": "Средний", "cooking_time": "Без разницы",
      "fasting_status": false, "meal_pattern": "3 приема (завтрак, обед, ужин)", "training_schedule": "Без регулярных тренировок",
      "sleep_schedule": "8 часов", "liked_foods": [], "disliked_foods": [], "excluded_meal_types": [],
      "motivation_barriers": [], "womens_health": null, "bmi": null, "waist": null, "body_type": null,
      "blood_tests": null, "tier": "T1"
    })
  });
  const data = await res.json();
  console.log("Data:", data);
}
test();
