from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, field_validator
from typing import Optional, List, Dict, Any

from sqlalchemy.orm import Session
from google import genai
import os
import json
import asyncio

from slowapi import Limiter
from slowapi.util import get_remote_address

from app.db import get_db
from app.services.rag_engine import search_knowledge
from app.services.assembler import PromptAssembler
from app.api.dependencies import get_current_user

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

# --- Нормализация плана для фронтенда ---
MEAL_TYPE_MAP = {
    'завтрак': 'breakfast',
    'обед': 'lunch',
    'ужин': 'dinner',
    'перекус': 'snack',
}

def normalize_plan_for_frontend(plan_data, budget_level="Средний"):
    """
    Конвертирует ответ Gemini в формат, ожидаемый фронтендом.
    Решает проблемы:
    1. meal → meal_type (Завтрак → breakfast)
    2. proteins → protein, fats → fat
    3. steps: ["строка"] → [{title, text}]
    4. day_N.meals → day_N (плоский массив)
    5. Добавление image_url, serving_g fallbacks
    """
    # Если data — строка, распарсим
    if isinstance(plan_data, str):
        plan_data = json.loads(plan_data)
    
    normalized = {}
    
    for key, value in plan_data.items():
        if not key.startswith('day_'):
            normalized[key] = value
            continue
        
        # Извлекаем массив блюд из вложенной структуры
        if isinstance(value, dict) and 'meals' in value:
            meals = value['meals']
            # Сохраняем витамины отдельно
            if 'vitamins' in value:
                normalized[f'vitamins_{key}'] = value['vitamins']
            if 'daily_tip' in value:
                normalized[f'tip_{key}'] = value['daily_tip']
        elif isinstance(value, list):
            meals = value
        else:
            normalized[key] = value
            continue
        
        # Нормализуем каждое блюдо
        normalized_meals = []
        for meal in meals:
            if not isinstance(meal, dict):
                continue
            
            # Маппинг типа приёма пищи
            meal_ru = (meal.get('meal') or '').lower().strip()
            meal_type = MEAL_TYPE_MAP.get(meal_ru, 'snack')
            
            # Нормализация шагов
            raw_steps = meal.get('steps', [])
            normalized_steps = []
            for i, step in enumerate(raw_steps):
                if isinstance(step, str):
                    normalized_steps.append({
                        'title': f'Шаг {i + 1}',
                        'text': step
                    })
                elif isinstance(step, dict):
                    normalized_steps.append(step)
            
            normalized_meal = {
                'meal_type': meal_type,
                'variant_name': meal.get('variant_name', 'Основной'),
                'name': meal.get('name', 'Блюдо'),
                'calories': meal.get('calories', 0),
                'protein': meal.get('proteins', meal.get('protein', 0)),
                'fat': meal.get('fats', meal.get('fat', 0)),
                'carbs': meal.get('carbs', 0),
                'fiber': meal.get('fiber', 0),
                'prep_time_min': meal.get('prep_time_min', 15),
                'serving_g': meal.get('serving_g', 300),
                'image_url': meal.get('image_url', ''),
                'wellness_rationale': meal.get('wellness_rationale', ''),
                'has_probiotics': bool(meal.get('has_probiotics', False)),
                'ingredients': meal.get('ingredients', []),
                'steps': normalized_steps,
            }
            normalized_meals.append(normalized_meal)
        
        # Записываем нормализованный день с учетом тренировок, если они есть
        day_output = {"meals": normalized_meals}
        if isinstance(value, dict) and 'workout' in value:
            day_output['workout'] = value['workout']
        normalized[key] = day_output
    from app.services.shopping_list_builder import build_shopping_list
    # Мы пока не знаем budget_level в этой функции, 
    # но можем попробовать извлечь его или поставить дефолт.
    shopping_list_data = build_shopping_list(plan_data, budget_level)
    normalized['shopping_list'] = shopping_list_data['items']
    normalized['estimated_cost'] = shopping_list_data['total_estimated_cost_rub']

    return normalized

class UserProfilePayload(BaseModel):
    age: int
    gender: str
    weight: float
    height: float
    target_weight: Optional[float] = None
    target_timeline_weeks: Optional[int] = None
    goal: str
    activity_level: str
    country: Optional[str] = "RU" # Default fallback for legacy apps
    allergies: Optional[List[str]] = []
    restrictions: Optional[List[str]] = []  # Диеты/ограничения (веганство, кето, и т.д.)
    diseases: Optional[List[str]] = []
    symptoms: Optional[List[str]] = []
    city: Optional[str] = ""
    budget_level: Optional[str] = "Средний"
    cooking_time: Optional[str] = "Без разницы"
    fasting_type: Optional[str] = None  # none | daily | periodic
    daily_format: Optional[str] = None
    daily_start: Optional[str] = None
    daily_meals: Optional[int] = None
    daily_window_end: Optional[str] = None
    periodic_format: Optional[str] = None
    periodic_freq: Optional[str] = None
    periodic_days: Optional[List[int]] = []
    periodic_start: Optional[str] = None
    meal_pattern: Optional[str] = "3 приема (завтрак, обед, ужин)"
    ai_personality: Optional[str] = "premium"  # premium | buddy | strict | sassy
    training_schedule: Optional[str] = "Без регулярных тренировок"
    sleep_schedule: Optional[str] = "8 часов"
    medications: Optional[str] = "Нет"
    supplements: Optional[str] = "Нет"
    supplement_openness: Optional[str] = None  # Отношение к БАДам
    liked_foods: Optional[List[str]] = []
    disliked_foods: Optional[List[str]] = []
    excluded_meal_types: Optional[List[str]] = []
    motivation_barriers: Optional[List[str]] = []  # Барьеры прошлого
    tier: str = "T1"
    activity_multiplier: Optional[float] = None  # Точный коэффициент активности (1.2 — 1.725)
    # Медицинские данные, которые раньше не передавались
    womens_health: Optional[List[str]] = None  # Беременность, СПКЯ, менопауза (массив)
    takes_contraceptives: Optional[str] = None  # Гормональные препараты/КОК
    bmi: Optional[str] = None  # ИМТ
    bmi_class: Optional[str] = None  # Классификация ИМТ
    waist: Optional[str] = None  # Обхват талии
    body_type: Optional[str] = None  # Телосложение
    fat_distribution: Optional[str] = None  # Распределение жира
    blood_tests: Optional[str] = None  # Анализы (JSON string)
    diets: Optional[List[str]] = []  # Алиас для restrictions (из Flutter)
    activity_types: Optional[List[str]] = []  # Виды активности (Бег, Йога, ...)
    activity_duration: Optional[str] = None  # Длительность тренировки (30min, 45min, ...)
    pace_classification: Optional[str] = None  # safe | accelerated | aggressive
    sleep_pattern: Optional[str] = None  # regular | shift_work | irregular
    target_daily_fiber: Optional[float] = None  # WHO/AHA fiber target (g/day), calculated on device
    custom_condition: Optional[str] = None  # Свободный текст состояния от пользователя
    extra_snacks: Optional[List[Dict[str, Any]]] = []  # Логи перекусов за сегодня
    beverages: Optional[List[Dict[str, Any]]] = []  # Логи напитков за сегодня

    cooking_style: Optional[str] = None  # daily | batch_2_3_days | batch_weekly | none
    shopping_frequency: Optional[str] = None  # daily | few_days | weekly
    
    # Логи для корректировки плана
    # (already defined above)
    
    # Тренировочные параметры

    fitness_level: Optional[str] = "Новичок"
    workout_location: Optional[str] = "Дома"
    equipment_available: Optional[List[str]] = []
    physical_limitations: Optional[List[str]] = []
    training_days: Optional[int] = 3

    # Вычисляемые на бэкенде из Flutter-данных
    @property
    def fasting_status(self) -> bool:
        """Вычисляется из fasting_type — не требует отдельного поля."""
        return bool(self.fasting_type and self.fasting_type != 'none')

    @property 
    def effective_restrictions(self) -> List[str]:
        """Объединяет diets + restrictions — Flutter шлёт diets, API-клиенты — restrictions.
        Renamed from `restrictions` to avoid Pydantic field/property conflict."""
        combined = list(self.diets or [])
        combined.extend([r for r in (self.restrictions or []) if r not in combined])
        return combined

    # ═══ Input Validators ═══
    @field_validator('age')
    @classmethod
    def validate_age(cls, v):
        if not 10 <= v <= 120:
            raise ValueError(f'Age must be 10-120, got {v}')
        return v

    @field_validator('weight')
    @classmethod
    def validate_weight(cls, v):
        if not 20 <= v <= 400:
            raise ValueError(f'Weight must be 20-400 kg, got {v}')
        return v

    @field_validator('height')
    @classmethod
    def validate_height(cls, v):
        if not 100 <= v <= 260:
            raise ValueError(f'Height must be 100-260 cm, got {v}')
        return v

    @field_validator('gender')
    @classmethod
    def validate_gender(cls, v):
        allowed = {'male', 'female', 'Мужской', 'Женский'}
        if v not in allowed:
            raise ValueError(f'Gender must be one of {allowed}, got {v}')
        # Normalize to English to prevent BMR miscalculation (BUG-04)
        if v == 'Женский':
            return 'female'
        if v == 'Мужской':
            return 'male'
        return v

    @field_validator('goal')
    @classmethod
    def validate_goal(cls, v):
        if len(v) > 200:
            raise ValueError('Goal too long (max 200 chars)')
        return v.strip()

    @field_validator('allergies', 'diseases', 'liked_foods', 'disliked_foods')
    @classmethod
    def validate_list_length(cls, v):
        if v and len(v) > 50:
            raise ValueError(f'List too long (max 50 items, got {len(v)})')
        return v

from fastapi import BackgroundTasks

@router.post("/generate")
@limiter.limit("10/minute")
async def generate_plan(request: Request, profile: UserProfilePayload, background_tasks: BackgroundTasks, db: Session = Depends(get_db), user_id: str = Depends(get_current_user)):
    # 1. Формируем "Поисковый запрос" для векторной БД на основе болезней/целей
    search_query = f"Диета, питание и ограничения для цели: {profile.goal}."
    if profile.diseases:
        search_query += f" Болезни: {', '.join(profile.diseases)}."
    if profile.symptoms:
        search_query += f" Симптомы: {', '.join(profile.symptoms)}."
    if profile.effective_restrictions:
        search_query += f" Ограничения: {', '.join(profile.effective_restrictions)}."
    if profile.womens_health:
        wh_val = ", ".join(profile.womens_health) if isinstance(profile.womens_health, list) else str(profile.womens_health)
        search_query += f" Женское здоровье: {wh_val}."

        
    print(f"🔍 Ищем медицинский контекст для: {search_query}")
    contexts = search_knowledge(db, search_query, limit=5)
    context_text = "\\n\\n".join([f"Совет от {c.doctor_name} ({c.specialization}): {c.content}" for c in contexts])
    if not context_text:
        context_text = "Специфических медицинских рекомендаций не найдено (база пуста)."

    # 2. Расчет BMR и Цели
    if profile.gender == 'female':
        bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age - 161
        floor_calories = 1200
    else:
        bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5
        floor_calories = 1500
        
    tdee = bmr * (profile.activity_multiplier or 1.375)
    target_kcal = tdee
    goal_lower = profile.goal.lower() if profile.goal else ''
    
    is_weight_loss = any(k in goal_lower for k in ['снизить вес', 'снижение веса', 'похудеть', 'lose_weight', 'weight_loss'])
    
    if is_weight_loss and profile.target_weight and profile.target_timeline_weeks:
        delta_weight = profile.weight - profile.target_weight
        if delta_weight > 0:
            # 7700 kcal per kg of fat
            daily_deficit = (delta_weight * 7700) / (profile.target_timeline_weeks * 7)
            # Guardrail: Deficit shouldn't exceed 25% of TDEE unless aggressive pace
            max_safe_deficit = tdee * 0.25
            if profile.pace_classification != 'aggressive' and daily_deficit > max_safe_deficit:
                daily_deficit = max_safe_deficit
            target_kcal = tdee - daily_deficit
    elif is_weight_loss:
        # Fallback if specific target info is missing
        target_kcal = tdee * 0.8
    elif any(k in goal_lower for k in ['набрать', 'набор мышечной', 'gain_muscle', 'muscle_gain']):
        target_kcal = tdee * 1.15
        
    if target_kcal < floor_calories:
        target_kcal = floor_calories

    # ── Pregnancy / Breastfeeding calorie guardrail ──────────────
    # Перекрывает любой дефицит для безопасности мамы и ребёнка
    from app.services.archetypes import ArchetypePromptFactory
    is_pregnant = ArchetypePromptFactory._is_pregnant(profile.womens_health)
    is_bf = ArchetypePromptFactory._is_breastfeeding(profile.womens_health)
    if is_pregnant:
        # Запрет дефицита. Минимум = TDEE + 340 (2-й триместр по умолчанию)
        target_kcal = max(target_kcal, tdee + 340)
    elif is_bf:
        # Мягкий дефицит допустим, но минимум 1800 ккал и не ниже TDEE - 500
        target_kcal = max(target_kcal, max(1800, tdee - 500))

    days_to_generate = 3 if profile.tier.lower() == 't1' or profile.tier == 'free' else 7
    meal_pattern = (profile.meal_pattern or '').lower()
    if '4' in meal_pattern or '5' in meal_pattern or 'перекус' in meal_pattern:
        meals_per_day = 4
    elif '2' in meal_pattern:
        meals_per_day = 2
    else:
        meals_per_day = 3

    # ЭТАП 1: Попытка собрать план через Smart Router (Hybrid Cache)
    from app.services.plan_router import PlanRouter
    
    final_plan = {}
    missing_days = False
    
    for day_index in range(1, days_to_generate + 1):
        day_key = f"day_{day_index}"
        day_plan = PlanRouter.assemble_day(db, day_index, profile, target_kcal)
        if day_plan:
            final_plan[day_key] = day_plan
        else:
            missing_days = True
            break
            
    # Если собрали весь план из БД - пропускаем Gemini
    matrix_data = {}
    if not missing_days:
        print("✅ План успешно собран из Smart Router Cache (0 вызовов LLM).")
        matrix_data = final_plan
    else:
        print("⚠️ Cache Miss в Smart Router. Включаем генерацию Gemini...")
        # Генерируем матрицу (Скелет)
        matrix_prompt = PromptAssembler.build_matrix_prompt(
            profile=profile, context_text=context_text, bmr=bmr, tdee=tdee,
            target_kcal=target_kcal, days=days_to_generate, meals_per_day=meals_per_day
        )
        
        GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
        client = genai.Client(api_key=GEMINI_API_KEY)
        
        # Helper для Retry при 503 ошибке от Gemini (High Demand)
        async def generate_with_retry(prompt_contents, max_retries=3):
            for attempt in range(max_retries):
                try:
                    return await asyncio.to_thread(client.models.generate_content, model='gemini-2.5-flash', contents=prompt_contents)
                except Exception as e:
                    err_str = str(e).lower()
                    if "503" in err_str or "high demand" in err_str or "servererror" in err_str:
                        if attempt == max_retries - 1:
                            raise e
                        wait_time = 2 ** attempt
                        print(f"⚠️ Gemini High Demand. Retrying in {wait_time}s (Attempt {attempt+1}/{max_retries})...")
                        await asyncio.sleep(wait_time)
                    else:
                        raise
        
        try:
            print("🤖 Отправляем запрос на Матрицу...")
            response = await generate_with_retry(matrix_prompt)
            matrix_text = response.text.replace("```json", "").replace("```", "").strip()
            matrix_data = json.loads(matrix_text)
            final_plan = {} # Сбрасываем кэш, используем то, что дал LLM
        except Exception as e:
            print("GEMINI ERROR OR 503:", e)
            print("⚠️ Запускаем Hardcoded Fallback JSON...")
            # Fallback 503 strategy
            fallback_path = os.path.join(os.path.dirname(__file__), "..", "data", "fallback_plan.json")
            if os.path.exists(fallback_path):
                with open(fallback_path, "r", encoding="utf-8") as f:
                    matrix_data = json.load(f)
                    final_plan = {}
            else:
                raise HTTPException(status_code=500, detail="Ошибка генерации и резервный план недоступен.")

    # ЭТАП 2: Поиск в Кэше
    from app.models.recipe_cache import MealCache
    missing_meals = []
    final_plan = {}
    
    # Собираем уникальные названия для поиска
    all_names = set()
    for day_key, day_data in matrix_data.items():
        if not day_key.startswith('day_'): continue
        final_plan[day_key] = {"meals": []}
        meals = day_data.get('meals', []) if isinstance(day_data, dict) else day_data
        for meal in meals:
            all_names.add(meal.get('name', ''))

    # Ищем в базе
    cached = db.query(MealCache).filter(MealCache.name.in_(list(all_names))).all()
    cache_map = {c.name: c for c in cached}
    
    for day_key, day_data in matrix_data.items():
        if not day_key.startswith('day_'): continue
        meals = day_data.get('meals', []) if isinstance(day_data, dict) else day_data
        for meal in meals:
            name = meal.get('name')
            if name in cache_map:
                c = cache_map[name]
                meal.update({
                    'calories': c.calories, 'protein': c.protein, 'fat': c.fat, 'carbs': c.carbs, 'fiber': c.fiber,
                    'ingredients': c.ingredients, 'steps': c.steps, 'image_url': c.image_url
                })
                final_plan[day_key]['meals'].append(meal)
            else:
                missing_meals.append(name)
                final_plan[day_key]['meals'].append(meal) # Placeholder

    # ЭТАП 3: Генерация недостающих рецептов
    new_recipes = {}
    if missing_meals:
        print(f"🤖 Генерируем недостающие рецепты: {len(missing_meals)} шт...")
        recipe_prompt = PromptAssembler.build_recipe_prompt(profile, missing_meals, target_kcal)
        resp_recipes = await generate_with_retry(recipe_prompt)
        rec_text = resp_recipes.text.replace("```json", "").replace("```", "").strip()
        try:
            new_recipes = json.loads(rec_text)
        except:
            print("⚠️ Ошибка парсинга новых рецептов")

        # Запускаем генерацию картинок в фоне для новых рецептов
        from app.services.image_generator import generate_meal_image
        import hashlib
        
        async def save_new_meals(recipes_dict):
            from app.scripts.seed_meal_images import get_pexels_url
            
            # Шаг 1: Сохраняем все рецепты СРАЗУ с fallback картинками (FORCE-SAVE)
            saved_meals = []
            for r_name, r_data in recipes_dict.items():
                ing_text = ", ".join([i.get("name", "") for i in r_data.get("ingredients", [])])
                h = hashlib.sha256(ing_text.encode()).hexdigest()
                
                # Заглушка, чтобы рецепт не потерялся
                fallback_url = get_pexels_url(r_name)
                
                new_meal = MealCache(
                    ingredients_hash=h, name=r_name, image_url=fallback_url,
                    calories=r_data.get('calories',0), protein=r_data.get('proteins',0),
                    fat=r_data.get('fats',0), carbs=r_data.get('carbs',0), fiber=r_data.get('fiber',0),
                    ingredients=r_data.get('ingredients',[]), steps=r_data.get('steps',[])
                )
                db.add(new_meal)
                saved_meals.append((new_meal, ing_text, r_name))
            
            try:
                db.commit()
            except Exception as e:
                print(f"⚠️ Ошибка FORCE-SAVE рецептов: {e}")
                db.rollback()
                return

            # Шаг 2: Асинхронно генерируем качественные картинки
            excluded_items = []
            if profile:
                excluded_items.extend(profile.allergies or [])
                excluded_items.extend(profile.disliked_foods or [])
                if hasattr(profile, 'effective_restrictions'):
                    excluded_items.extend(profile.effective_restrictions or [])
            excluded_items = list(set([item.strip() for item in excluded_items if item.strip()]))

            for meal_obj, ing_text, r_name in saved_meals:
                try:
                    img_url = await generate_meal_image(r_name, ing_text, excluded_items)
                    meal_obj.image_url = img_url
                    db.commit()
                except Exception as e:
                    print(f"⚠️ Ошибка Imagen для {r_name}: {e}")
                    db.rollback()
            
        background_tasks.add_task(save_new_meals, new_recipes)
    
    # Вливаем новые рецепты в план
    allergen_warnings = []
    allergens_lower = [a.lower().strip() for a in profile.allergies if a] if profile.allergies else []
    
    for day_key, day_data in final_plan.items():
        for meal in day_data['meals']:
            name = meal.get('name')
            if name in new_recipes:
                r = new_recipes[name]
                meal.update({
                    'calories': r.get('calories',0), 'protein': r.get('proteins',0), 'fat': r.get('fats',0),
                    'carbs': r.get('carbs',0), 'fiber': r.get('fiber',0), 'ingredients': r.get('ingredients',[]),
                    'steps': r.get('steps',[])
                })
            
            # Post-validation аллергенов
            for ing in meal.get('ingredients', []):
                ing_name = (ing.get('name') or '').lower()
                for allergen in allergens_lower:
                    if allergen and allergen in ing_name:
                        allergen_warnings.append(f"{day_key}: '{ing.get('name')}' содержит '{allergen}'")

    # ЭТАП 3.3: Post-LLM Macro Sanity Check (ingredients_reference)
    macro_warnings = []
    try:
        from app.models.safety_tables import IngredientReference
        ref_all = db.query(IngredientReference).all()
        ref_map = {r.name_ru.lower(): r for r in ref_all}
        
        for day_key, day_data in final_plan.items():
            if not day_key.startswith('day_'):
                continue
            for meal in day_data.get('meals', []):
                meal_cal = meal.get('calories', 0)
                if not meal_cal or meal_cal == 0:
                    continue
                # Estimate expected calories from ingredients
                estimated_cal = 0
                matched_ingredients = 0
                for ing in meal.get('ingredients', []):
                    ing_name = (ing.get('name') or '').lower()
                    amount_g = ing.get('amount', 0)
                    unit = (ing.get('unit') or '').lower()
                    # Convert шт to approximate grams
                    if 'шт' in unit:
                        amount_g = amount_g * 60  # rough: 1 egg ~ 60g
                    # Find reference
                    for ref_name, ref in ref_map.items():
                        if ref_name in ing_name or ing_name in ref_name:
                            estimated_cal += (ref.calories * amount_g / 100)
                            matched_ingredients += 1
                            break
                
                if matched_ingredients >= 2 and estimated_cal > 0:
                    deviation = abs(meal_cal - estimated_cal) / estimated_cal
                    if deviation > 0.30:
                        macro_warnings.append(
                            f"{day_key}/{meal.get('name')}: LLM={int(meal_cal)}kcal vs Ref={int(estimated_cal)}kcal (Δ{int(deviation*100)}%)"
                        )
    except Exception as e:
        print(f"⚠️ Macro validation skipped: {e}")

    # ЭТАП 3.5: Привязка безопасных тренировок
    from app.services.workout_router import WorkoutRouter
    try:
        training_days_count = profile.training_days or 3
        if training_days_count > 0 and profile.training_schedule != "Без регулярных тренировок":
            workout_schedule = await WorkoutRouter.assign_workouts(
                db=db,
                training_days=training_days_count,
                location=profile.workout_location or "Дома",
                equipment=profile.equipment_available or [],
                limitations=profile.physical_limitations or [],
                plan_days=days_to_generate
            )
            # Вливаем тренировки в план дней
            for day_key, workout_obj in workout_schedule.items():
                if day_key in final_plan and workout_obj is not None:
                    final_plan[day_key]['workout'] = workout_obj
    except Exception as we:
        print(f"⚠️ Ошибка маршрутизации тренировок: {we}")

    # ЭТАП 4: Нормализация
    normalized_data = normalize_plan_for_frontend(final_plan, profile.budget_level)
    
    return {
        "status": "success",
        "data": normalized_data,
        "target_kcal": int(target_kcal),
        "target_daily_fiber": int(profile.target_daily_fiber or (25 if profile.gender == 'female' else 30)),
        "bmr": int(bmr),
        "tdee": int(tdee),
        "days_generated": days_to_generate,
        "meals_per_day": meals_per_day,
        "rag_context_used": len(contexts),
        "model_used": 'gemini-2.5-flash (2-step)',
        "archetype_used": PromptAssembler._last_archetype_code,
        "allergen_warnings": allergen_warnings,
        "macro_warnings": macro_warnings
    }


from app.models.knowledge_base import KnowledgeChunk
from sqlalchemy import func

@router.get("/stats")
def get_knowledge_base_stats(db: Session = Depends(get_db)):
    """
    Возвращает статистику по заполняемости базы знаний 
    для Live-дашборда администратора.
    """
    try:
        total_chunks = db.query(KnowledgeChunk).count()
        doctor_stats_raw = db.query(KnowledgeChunk.doctor_name, func.count()).group_by(KnowledgeChunk.doctor_name).all()
        
        doctor_stats = [{"name": row[0], "count": row[1]} for row in doctor_stats_raw]
        doctor_stats.sort(key=lambda x: x["count"], reverse=True)
        
        return {
            "status": "success",
            "total_chunks": total_chunks,
            "experts": doctor_stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
