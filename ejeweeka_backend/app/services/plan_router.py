import json
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import cast
from sqlalchemy.dialects.postgresql import JSONB

from app.models.recipe_cache import MealCache
from app.api.plan import UserProfilePayload

class PlanRouter:
    """
    Алгоритмический маршрутизатор (Hybrid Engine) для сборки плана питания.
    Заменяет 90% запросов к LLM детерминированным SQL-поиском.
    """

    @staticmethod
    def get_safe_recipes(db: Session, meal_type: str, profile: UserProfilePayload, limit: int = 7) -> List[MealCache]:
        """
        Фильтрует рецепты по аллергиям (исключает) и болезням (требует наличия тега).
        Если в базе используется SQLite (в тестах JSONB ведет себя как JSON), мы используем базовую фильтрацию в памяти.
        В продакшене (PostgreSQL) можно использовать операторы JSONB.
        Для универсальности MVP сделаем выборку и фильтрацию в Python, если записей мало,
        или гибридно.
        """
        # Базовая выборка по типу приема пищи
        query = db.query(MealCache).filter(MealCache.meal_type == meal_type)
        all_meals = query.all()
        
        safe_meals = []
        allergens_lower = [a.lower() for a in (profile.allergies or [])]
        diseases_lower = [d.lower() for d in (profile.diseases or [])]
        
        for meal in all_meals:
            # 1. Проверка аллергенов (NOT IN)
            meal_allergens = [a.lower() for a in (meal.allergens_present or [])]
            has_allergen = any(a in meal_allergens for a in allergens_lower)
            if has_allergen:
                continue
                
            # 2. Проверка болезней (MUST HAVE tags)
            # Если у пользователя есть Гастрит, рецепт должен иметь тег "Гастрит"
            # Если у рецепта нет тега "Гастрит", мы его бракуем.
            # Если профиль без болезней, подходят любые безопасные рецепты.
            meal_safe_for = [d.lower() for d in (meal.safe_for_diseases or [])]
            is_safe = True
            for d in diseases_lower:
                if d not in meal_safe_for:
                    is_safe = False
                    break
                    
            if not is_safe:
                continue
                
            safe_meals.append(meal)
            
            if len(safe_meals) >= limit:
                break
                
        return safe_meals

    @staticmethod
    def scale_recipe(recipe: MealCache, target_kcal: float) -> Dict[str, Any]:
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
            base_grams = ing.get("grams", 100) # Если не указано, берем 100 как дефолт
            scaled_ingredients.append({
                "name": ing.get("name", "Ингредиент"),
                "grams": round(base_grams * scale_factor)
            })
            
        return {
            "meal": recipe.meal_type or "Прием пищи",
            "variant_name": "Основной",
            "name": recipe.name,
            "calories": round(recipe.calories * scale_factor),
            "protein": round(recipe.protein * scale_factor, 1),
            "fat": round(recipe.fat * scale_factor, 1),
            "carbs": round(recipe.carbs * scale_factor, 1),
            "fiber": round(recipe.fiber * scale_factor, 1),
            "ingredients": scaled_ingredients,
            "steps": recipe.steps,
            "wellness_rationale": recipe.wellness_rationale or "Сбалансированный прием пищи для достижения вашей цели."
        }

    @staticmethod
    def assemble_day(db: Session, day_index: int, profile: UserProfilePayload, target_kcal: float) -> Optional[Dict[str, Any]]:
        """
        Собирает 1 полный день. Возвращает None, если недостаточно кэша (Cache Miss).
        Разбивка калорий: Завтрак 25%, Обед 35%, Перекус 15%, Ужин 25%.
        """
        meal_targets = {
            "Завтрак": target_kcal * 0.25,
            "Обед": target_kcal * 0.35,
            "Перекус": target_kcal * 0.15,
            "Ужин": target_kcal * 0.25
        }
        
        day_meals = []
        for m_type, m_kcal in meal_targets.items():
            # Запрашиваем с небольшим оффсетом/рандомом, чтобы дни отличались.
            # Для MVP берем с offset = day_index (циклично)
            safe_recipes = PlanRouter.get_safe_recipes(db, m_type, profile, limit=20)
            if not safe_recipes:
                return None # Упс, кэш пуст для данного типа или болезни!
                
            selected_recipe = safe_recipes[day_index % len(safe_recipes)]
            scaled_meal = PlanRouter.scale_recipe(selected_recipe, m_kcal)
            day_meals.append(scaled_meal)
            
        return {"meals": day_meals}

