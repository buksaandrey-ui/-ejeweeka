def calculate_metrics(profile):
    if profile.gender.lower() in ('female', 'женский'):
        bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age - 161
        floor_calories = 1200
    else:
        bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5
        floor_calories = 1500
    
    act_map = {
        "Не готов(а) сейчас": 1.2,
        "1 раз": 1.375,
        "2 раза": 1.375,
        "3 раза": 1.55,
        "4 и более": 1.725
    }
    multiplier = act_map.get(profile.activity_level, 1.375)
    tdee = bmr * multiplier
    target_kcal = tdee
    
    goal_lower = profile.goal.lower() if profile.goal else ''
    is_weight_loss = any(k in goal_lower for k in ['снизить вес', 'снижение веса', 'похудеть', 'lose_weight', 'weight_loss'])
    is_muscle_gain = any(k in goal_lower for k in ['набрать мышечную массу', 'muscle_gain'])
    
    if is_weight_loss and profile.target_weight and getattr(profile, 'target_timeline_weeks', None):
        delta_weight = profile.weight - profile.target_weight
        if delta_weight > 0:
            daily_deficit = (delta_weight * 7700) / (profile.target_timeline_weeks * 7)
            max_safe_deficit = tdee * 0.25
            if getattr(profile, 'pace_classification', '') != 'aggressive' and daily_deficit > max_safe_deficit:
                daily_deficit = max_safe_deficit
            target_kcal = tdee - daily_deficit
    elif is_weight_loss:
        target_kcal = tdee - (tdee * 0.15)
    elif is_muscle_gain:
        target_kcal = tdee + (tdee * 0.10)
        
    if "Беременность" in getattr(profile, "diseases", []):
        target_kcal = tdee + 340
    if "Кормление грудью" in getattr(profile, "diseases", []):
        floor_calories = max(floor_calories, 1800)
        
    target_kcal = max(target_kcal, floor_calories)
    return int(bmr), int(tdee), int(target_kcal)
