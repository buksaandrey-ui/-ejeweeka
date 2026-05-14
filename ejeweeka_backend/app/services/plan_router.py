import json
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import cast, func
from sqlalchemy.dialects.postgresql import JSONB

from app.models.recipe_cache import MealCache
from app.api.plan import UserProfilePayload

# Растительные аналоги, которые содержат слова "молоко", "сливки", "масло"
# но НЕ являются животными продуктами
VEGAN_SAFE_PREFIXES = [
    'растительн', 'овсян', 'соев', 'миндальн', 'кокосов', 'рисов',
    'кедров', 'конопля', 'льнян', 'гречневое', 'банановое',
    'оливков', 'подсолнечн', 'кунжутн', 'горчичн', 'кукурузн',
    'рапсов', 'арахисов', 'тыквенн', 'виноградн',
]

def _is_vegan_safe(ingredient_name: str) -> bool:
    """Проверяет, является ли ингредиент растительным аналогом."""
    name = ingredient_name.lower()
    return any(prefix in name for prefix in VEGAN_SAFE_PREFIXES)


class PlanRouter:
    """
    Алгоритмический маршрутизатор (Hybrid Engine) для сборки плана питания.
    Заменяет 90% запросов к LLM детерминированным SQL-поиском.
    """

    @staticmethod
    def get_safe_recipes(db: Session, meal_type: str, profile: UserProfilePayload, limit: int = 7) -> List[MealCache]:
        """
        Фильтрует рецепты по:
        1. Аллергиям (исключает рецепты с аллергенами)
        2. Болезням (исключает рецепты, явно помеченные как опасные)
        3. Нелюбимым продуктам (исключает рецепты с нелюбимыми ингредиентами)
        4. Диетическим ограничениям (веганство, халяль и т.д.)
        """
        # Map country to region string
        country = getattr(profile, 'country', 'RU') or 'RU'
        region_map = {
            'RU': 'СНГ (Россия, Беларусь, Казахстан)',
            'BY': 'СНГ (Россия, Беларусь, Казахстан)',
            'KZ': 'СНГ (Россия, Беларусь, Казахстан)',
            'TH': 'Азия (Таиланд, Бали)',
            'ID': 'Азия (Таиланд, Бали)',
            'AE': 'Азия (Таиланд, Бали)', # Fallback for now
        }
        target_region = region_map.get(country.upper(), 'Европа')
        target_budget = getattr(profile, 'budget_level', 'Средний') or 'Средний'
        
        # Базовая выборка по типу приема пищи
        query = db.query(MealCache).filter(
            MealCache.meal_type == meal_type
        )
        
        # Если в базе уже есть региональная матрица (JSON)
        # Мы фильтруем: JSON ключи содержат target_region, и значение равно target_budget
        # SQL equivalent: WHERE regional_availability->>'СНГ' = 'Средний'
        query = query.filter(
            func.jsonb_extract_path_text(
                cast(MealCache.regional_availability, JSONB), 
                target_region
            ) == target_budget
        )
        
        # Если готовка раз в неделю, отдаем предпочтение рецептам с freezable=True или batch_friendly
        if (profile.cooking_style or '').lower() in ['раз в неделю', 'batch_weekly']:
            # Пытаемся сначала найти замораживаемые или подходящие для длительного хранения
            batch_query = query.filter(MealCache.freezable == True)
            all_meals = batch_query.all()
            if not all_meals:
                all_meals = query.all()
        else:
            all_meals = query.all()
        
        
        safe_meals = []
        allergens_lower = [a.lower() for a in (profile.allergies or [])]
        diseases_lower = [d.lower() for d in (profile.diseases or [])]
        disliked_lower = [d.lower() for d in (profile.disliked_foods or [])]
        restrictions_lower = [r.lower() for r in (profile.effective_restrictions or [])]
        
        # Проверяем "Не готовлю" или "Минимум готовки"
        no_cooking = (profile.cooking_style or '').lower() == 'none' or 'минимум' in (profile.cooking_time or '').lower()
        
        recent_hashes = profile.recent_meal_hashes or []
        favorite_hashes = profile.favorite_meal_hashes or []
        
        for meal in all_meals:
            # -1. Проверка горизонта разнообразия (14 дней)
            if meal.ingredients_hash in recent_hashes:
                if meal.ingredients_hash not in favorite_hashes:
                    continue  # Пропускаем, так как недавно ели и это не любимое блюдо
                    
            # 0. Проверка на сложность готовки
            if no_cooking and meal.steps:
                if isinstance(meal.steps, list) and len(meal.steps) > 2:
                    continue  # Пропускаем сложные блюда
            # 1. Проверка аллергенов (АБСОЛЮТНЫЙ ЗАПРЕТ)
            meal_allergens = [a.lower() for a in (meal.allergens_present or [])]
            has_allergen = any(a in meal_allergens for a in allergens_lower)
            if has_allergen:
                continue
            
            # Дополнительно: проверяем ингредиенты на наличие аллергенов
            if allergens_lower and meal.ingredients:
                ingredient_names = ' '.join([
                    (ing.lower() if isinstance(ing, str) else (ing.get('name') or '').lower()) for ing in (meal.ingredients or [])
                ])
                has_allergen_in_ingredients = any(
                    allergen in ingredient_names for allergen in allergens_lower
                )
                if has_allergen_in_ingredients:
                    continue
                
            # 2. Проверка болезней (ИНВЕРТИРОВАННАЯ ЛОГИКА)
            # Рецепт без тегов safe_for_diseases считается НЕЙТРАЛЬНЫМ (безопасным)
            # Блокируем только если рецепт явно помечен как опасный
            meal_safe_for = [d.lower() for d in (meal.safe_for_diseases or [])]
            is_safe = True
            if meal_safe_for:
                # Если у рецепта ЕСТЬ теги — проверяем что болезни пользователя в них
                for d in diseases_lower:
                    if d not in meal_safe_for and f"не_{d}" in meal_safe_for:
                        is_safe = False
                        break
            # Если тегов нет — рецепт нейтральный, пропускаем
            
            if not is_safe:
                continue
            
            # 3. Проверка нелюбимых продуктов (МЯГКИЙ ЗАПРЕТ)
            if disliked_lower and meal.ingredients:
                ingredient_names = ' '.join([
                    (ing.lower() if isinstance(ing, str) else (ing.get('name') or '').lower()) for ing in (meal.ingredients or [])
                ])
                has_disliked = any(
                    disliked in ingredient_names for disliked in disliked_lower
                )
                if has_disliked:
                    continue
            
            # Также проверяем название блюда на нелюбимые продукты
            if disliked_lower:
                meal_name_lower = (meal.name or '').lower()
                has_disliked_in_name = any(
                    disliked in meal_name_lower for disliked in disliked_lower
                )
                if has_disliked_in_name:
                    continue
            
            # 4. Проверка диетических ограничений
            if restrictions_lower and meal.ingredients:
                ingredient_names = ' '.join([
                    (ing.lower() if isinstance(ing, str) else (ing.get('name') or '').lower()) for ing in (meal.ingredients or [])
                ])
                blocked = False
                
                # Веганство: блокируем любые животные продукты
                if any(r in ['веганство', 'vegan'] for r in restrictions_lower):
                    animal_keywords = ['курица', 'говядина', 'свинина', 'рыба', 'лосось', 'форель',
                                       'яйцо', 'яйца', 'молоко', 'кефир', 'творог', 'сыр', 'сливки',
                                       'сметана', 'масло сливочное', 'мёд', 'мед', 'желатин',
                                       'индейка', 'баранина', 'креветки', 'кальмар']
                    # Проверяем каждый ингредиент отдельно (не строку целиком)
                    for ing in (meal.ingredients or []):
                        ing_name = (ing.lower() if isinstance(ing, str) else (ing.get('name') or '')).lower()
                        if _is_vegan_safe(ing_name):
                            continue  # растительный аналог — пропускаем
                        if any(kw in ing_name for kw in animal_keywords):
                            blocked = True
                            break
                
                # Халяль: блокируем свинину и алкоголь
                if any(r in ['халяль', 'halal'] for r in restrictions_lower):
                    haram_keywords = ['свинина', 'бекон', 'сало', 'вино', 'пиво', 'коньяк']
                    if any(kw in ingredient_names for kw in haram_keywords):
                        blocked = True
                
                # Без молочки
                if any(r in ['без молочки', 'no_dairy', 'без лактозы'] for r in restrictions_lower):
                    dairy_keywords = ['молоко', 'кефир', 'творог', 'сыр', 'сливки', 'сметана',
                                      'йогурт', 'масло сливочное']
                    for ing in (meal.ingredients or []):
                        ing_name = (ing.lower() if isinstance(ing, str) else (ing.get('name') or '')).lower()
                        if _is_vegan_safe(ing_name):
                            continue
                        if any(kw in ing_name for kw in dairy_keywords):
                            blocked = True
                            break
                
                # Без глютена
                if any(r in ['без глютена', 'gluten_free'] for r in restrictions_lower):
                    gluten_keywords = ['пшеница', 'ячмень', 'рожь', 'хлеб', 'макароны', 'мука пшеничная']
                    if any(kw in ingredient_names for kw in gluten_keywords):
                        blocked = True
                
                if blocked:
                    continue
                    
            # Проверка стиля готовки
            cooking_style = (getattr(profile, 'cooking_style', '') or '').lower()
            if 'none' in cooking_style or 'не готовлю' in cooking_style:
                # Мягкий фильтр: отбрасываем блюда с явными глаголами готовки в шагах
                cooking_verbs = ['варить', 'жарить', 'запекать', 'тушить', 'вскипятить', 'обжарить', 'отварить']
                steps_text = ' '.join(meal.steps or []).lower()
                if any(verb in steps_text for verb in cooking_verbs):
                    continue
                    
            safe_meals.append(meal)
            
        # 6. Приоритизация по микроэлементам (Анализы крови / Дефициты)
        desired_microelements = []
        blood_tests_str = getattr(profile, 'blood_tests', '') or ''
        blood_tests_lower = blood_tests_str.lower()
        if 'анемия' in blood_tests_lower or 'железо' in blood_tests_lower or 'ферритин' in blood_tests_lower:
            desired_microelements.append('железо')
        if 'микрофлора' in blood_tests_lower or 'кишечник' in blood_tests_lower or 'дисбактериоз' in blood_tests_lower:
            desired_microelements.extend(['пребиотики', 'пробиотики'])
        if 'витамин d' in blood_tests_lower:
            desired_microelements.append('витамин d')
        if 'кальций' in blood_tests_lower:
            desired_microelements.append('кальций')
            
        if desired_microelements:
            def _score_meal(m: MealCache) -> int:
                score = 0
                rich_in = [r.lower() for r in (m.rich_in_microelements or [])]
                for req in desired_microelements:
                    if req in rich_in:
                        score += 1
                return score
            safe_meals.sort(key=_score_meal, reverse=True)
            
        return safe_meals[:limit]

    @staticmethod
    def scale_recipe(recipe: MealCache, target_kcal: float, variant_num: int = 1) -> Dict[str, Any]:
        """
        Масштабирует рецепт под нужную калорийность приема пищи.
        Например, в базе котлеты на 300 ккал, а юзеру нужно 450. Коэффициент 1.5.
        """
        if not recipe.calories or recipe.calories <= 0:
            scale_factor = 1.0
        else:
            scale_factor = target_kcal / recipe.calories
            
        scaled_ingredients = []
        for ing in (recipe.ingredients or []):
            if isinstance(ing, str):
                scaled_ingredients.append({
                    "name": ing,
                    "amount": 100,
                    "unit": "г"
                })
                continue
                
            base_amount = ing.get("amount", ing.get("grams", 100))
            try:
                # Попытка масштабировать, если это число
                scaled_amount = round(float(base_amount) * scale_factor)
            except (ValueError, TypeError):
                # Если это строка типа "по вкусу"
                scaled_amount = base_amount
                
            scaled_ingredients.append({
                "name": ing.get("name", "Ингредиент"),
                "amount": scaled_amount,
                "unit": ing.get("unit", "г")
            })
            
        return {
            "meal": recipe.meal_type or "Прием пищи",
            "variant_name": f"Вариант {variant_num}",
            "name": recipe.name,
            "calories": round(recipe.calories * scale_factor),
            "protein": round(recipe.protein * scale_factor, 1),
            "fat": round(recipe.fat * scale_factor, 1),
            "carbs": round(recipe.carbs * scale_factor, 1),
            "fiber": round(recipe.fiber * scale_factor, 1),
            "ingredients": scaled_ingredients,
            "steps": recipe.steps,
            "wellness_rationale": recipe.wellness_rationale or "Сбалансированный прием пищи для достижения твоей цели."
        }

    @staticmethod
    def assemble_plan(db: Session, profile: UserProfilePayload, target_kcal: float, days: int, meals_per_day: int, variants_per_meal: int = 3) -> Optional[Dict[str, Any]]:
        """
        Собирает план на N дней с M вариантами для каждого приема пищи.
        Возвращает None, если недостаточно кэша (Cache Miss) хотя бы для одного приема пищи.
        """
        # Определяем распределение калорий
        if meals_per_day == 2:
            meal_targets = {"Завтрак": target_kcal * 0.40, "Ужин": target_kcal * 0.60}
        elif meals_per_day == 3:
            meal_targets = {"Завтрак": target_kcal * 0.30, "Обед": target_kcal * 0.40, "Ужин": target_kcal * 0.30}
        elif meals_per_day == 5:
            meal_targets = {"Завтрак": target_kcal * 0.25, "Перекус 1": target_kcal * 0.10, "Обед": target_kcal * 0.30, "Перекус 2": target_kcal * 0.10, "Ужин": target_kcal * 0.25}
        else:
            meal_targets = {"Завтрак": target_kcal * 0.25, "Обед": target_kcal * 0.35, "Перекус": target_kcal * 0.15, "Ужин": target_kcal * 0.25}
        
        final_plan = {}
        
        # Для каждого типа приема пищи нужно days * variants_per_meal УНИКАЛЬНЫХ рецептов
        required_per_type = days * variants_per_meal
        
        type_recipes = {}
        for m_type in meal_targets.keys():
            safe_recipes = PlanRouter.get_safe_recipes(db, m_type, profile, limit=100)
            if len(safe_recipes) < required_per_type:
                # Cache miss! Мы должны вернуть None, чтобы api/plan.py вызвал Auto-Seeding
                print(f"⚠️ Cache Miss для '{m_type}': нужно {required_per_type}, найдено {len(safe_recipes)}.")
                return None
            type_recipes[m_type] = safe_recipes

        # Сборка плана
        fasting_type = (getattr(profile, 'fasting_type', '') or '').lower()
        periodic_days = getattr(profile, 'periodic_days', []) or []
        
        for d in range(1, days + 1):
            day_key = f"day_{d}"
            
            # Логика периодического 36-часового голодания
            if fasting_type == 'periodic' and d in periodic_days:
                final_plan[day_key] = {
                    "meals": [],
                    "fasting_day": True,
                    "tip": "День отдыха для ЖКТ. Рекомендуется пить много воды, травяные чаи или костный бульон."
                }
                continue
                
            day_meals = []
            
            for m_type, m_kcal in meal_targets.items():
                # Берем нужный срез рецептов для этого дня
                start_idx = (d - 1) * variants_per_meal
                end_idx = start_idx + variants_per_meal
                day_variants = type_recipes[m_type][start_idx:end_idx]
                
                for v_idx, recipe in enumerate(day_variants):
                    scaled_meal = PlanRouter.scale_recipe(recipe, m_kcal, variant_num=v_idx + 1)
                    day_meals.append(scaled_meal)
                    
            final_plan[day_key] = {"meals": day_meals}
            
        return final_plan
