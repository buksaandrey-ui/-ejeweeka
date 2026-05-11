import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.models.recipe_cache import MealCache
from app.services.plan_router import PlanRouter
from app.api.plan import UserProfilePayload

# Mocking a lightweight session
class MockQuery:
    def __init__(self, items):
        self.items = items
    def filter(self, *args, **kwargs):
        return self
    def all(self):
        return self.items

class MockSession:
    def __init__(self, meals):
        self.meals = meals
    def query(self, model):
        # Return all meals, our python side filtering handles the rest in PlanRouter (with our MVP logic)
        return MockQuery(self.meals)

meals = [
    MealCache(
        ingredients_hash="hash1",
        name="Сырники",
        meal_type="Завтрак",
        calories=300, protein=20, fat=10, carbs=30, fiber=2,
        allergens_present=["Лактоза"],
        safe_for_diseases=["Здоровый"],
        ingredients=[{"name": "Творог", "grams": 150}]
    ),
    MealCache(
        ingredients_hash="hash2",
        name="Овсянка",
        meal_type="Завтрак",
        calories=250, protein=10, fat=5, carbs=40, fiber=8,
        allergens_present=[],
        safe_for_diseases=["Гастрит", "Диабет 2 типа", "Здоровый"],
        ingredients=[{"name": "Овсянка", "grams": 50}]
    ),
    MealCache(
        ingredients_hash="hash3",
        name="Жареная картошка",
        meal_type="Обед",
        calories=500, protein=5, fat=30, carbs=60, fiber=4,
        allergens_present=[],
        safe_for_diseases=[], # Нет тегов болезней
        ingredients=[{"name": "Картошка", "grams": 200}]
    ),
    MealCache(
        ingredients_hash="hash4",
        name="Паровые котлеты",
        meal_type="Обед",
        calories=200, protein=25, fat=10, carbs=5, fiber=1,
        allergens_present=[],
        safe_for_diseases=["Гастрит", "Диабет 2 типа"],
        ingredients=[{"name": "Курица", "grams": 150}]
    )
]

db = MockSession(meals)

print("Running Test 1: Allergen Filtration")
profile = UserProfilePayload(
    gender="male", weight=80, height=180, age=30, goal="снизить вес", activity_level="moderate",
    allergies=["Лактоза"]
)
recipes = PlanRouter.get_safe_recipes(db, "Завтрак", profile)
names = [r.name for r in recipes]
assert "Овсянка" in names
assert "Сырники" not in names, "Аллерген (Лактоза) не отфильтровался!"
print("Test 1 PASSED")

print("Running Test 2: Disease Filtration")
profile = UserProfilePayload(
    gender="male", weight=80, height=180, age=30, goal="снизить вес", activity_level="moderate",
    diseases=["Гастрит"]
)
recipes = PlanRouter.get_safe_recipes(db, "Обед", profile)
names = [r.name for r in recipes]
assert "Паровые котлеты" in names
assert "Жареная картошка" not in names, "Блюдо без тега 'Гастрит' прошло фильтрацию!"
print("Test 2 PASSED")

print("Running Test 3: Scale Recipe")
recipe = MealCache(
    name="Салат", meal_type="Перекус",
    calories=200, protein=10, fat=5, carbs=25, fiber=10,
    ingredients=[{"name": "Огурец", "grams": 100}]
)
scaled = PlanRouter.scale_recipe(recipe, 400)
assert scaled["calories"] == 400
assert scaled["protein"] == 20.0
assert scaled["ingredients"][0]["grams"] == 200, "Граммовки не удвоились!"
print("Test 3 PASSED")

print("Running Test 4: Cache Miss")
profile = UserProfilePayload(
    gender="male", weight=80, height=180, age=30, goal="снизить вес", activity_level="moderate",
    diseases=["Редкая Болезнь"]
)
day_plan = PlanRouter.assemble_day(db, 1, profile, 2000)
assert day_plan is None
print("Test 4 PASSED")

print("All tests passed successfully!")
