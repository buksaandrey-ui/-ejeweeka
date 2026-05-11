import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db import Base
from app.models.recipe_cache import MealCache
from app.services.plan_router import PlanRouter
from app.api.plan import UserProfilePayload
import json

# Setup in-memory SQLite DB
engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    
    # Populate mock data
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
    session.add_all(meals)
    session.commit()
    
    yield session
    
    session.close()
    Base.metadata.drop_all(bind=engine)


def test_allergen_filtration(db):
    profile = UserProfilePayload(
        gender="male", weight=80, height=180, age=30, goal="снизить вес",
        allergies=["Лактоза"]
    )
    
    recipes = PlanRouter.get_safe_recipes(db, "Завтрак", profile)
    names = [r.name for r in recipes]
    
    assert "Овсянка" in names
    assert "Сырники" not in names, "Аллерген (Лактоза) не отфильтровался!"


def test_disease_filtration(db):
    profile = UserProfilePayload(
        gender="male", weight=80, height=180, age=30, goal="снизить вес",
        diseases=["Гастрит"]
    )
    
    recipes = PlanRouter.get_safe_recipes(db, "Обед", profile)
    names = [r.name for r in recipes]
    
    assert "Паровые котлеты" in names
    assert "Жареная картошка" not in names, "Блюдо без тега 'Гастрит' прошло фильтрацию!"


def test_scale_recipe():
    # Mock recipe: 200 kcal
    recipe = MealCache(
        name="Салат", meal_type="Перекус",
        calories=200, protein=10, fat=5, carbs=25, fiber=10,
        ingredients=[{"name": "Огурец", "grams": 100}]
    )
    
    # Target: 400 kcal (Scale factor = 2.0)
    scaled = PlanRouter.scale_recipe(recipe, 400)
    
    assert scaled["calories"] == 400
    assert scaled["protein"] == 20.0
    assert scaled["ingredients"][0]["grams"] == 200, "Граммовки не удвоились!"


def test_cache_miss(db):
    profile = UserProfilePayload(
        gender="male", weight=80, height=180, age=30, goal="снизить вес",
        diseases=["Редкая Болезнь"] # В базе нет блюд с таким тегом
    )
    
    # Пытаемся собрать день
    day_plan = PlanRouter.assemble_day(db, 1, profile, 2000)
    
    # Должен вернуть None, сигнализируя о необходимости Cache Miss (вызов Gemini)
    assert day_plan is None

