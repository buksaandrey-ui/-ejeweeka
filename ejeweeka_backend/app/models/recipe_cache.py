from sqlalchemy import Column, Integer, String, Float, JSON, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from app.db import Base

class MealCache(Base):
    """
    Таблица для хранения уже сгенерированных блюд и фотографий.
    Защищает от лишних трат на LLM и Image API.
    """
    __tablename__ = "meals_library"

    id = Column(Integer, primary_key=True, index=True)
    ingredients_hash = Column(String(64), unique=True, index=True, nullable=False)
    name = Column(String(255), nullable=False)
    image_url = Column(String(500), nullable=True)
    
    # Macros
    calories = Column(Float, nullable=False)
    protein = Column(Float, nullable=False)
    fat = Column(Float, nullable=False)
    carbs = Column(Float, nullable=False)
    fiber = Column(Float, nullable=False)
    
    # Smart Router Routing Fields
    meal_type = Column(String(50), index=True, nullable=True) # Завтрак, Обед, Ужин, Перекус
    regional_availability = Column(JSON, default={}) # {"СНГ": "Премиум", "Европа": "Средний"}
    cooking_time_minutes = Column(Integer, nullable=True, default=30)
    
    allergens_present = Column(JSON, default=[]) # ["Лактоза", "Орехи"]
    safe_for_diseases = Column(JSON, default=[]) # ["Гастрит", "Диабет 2 типа"]
    rich_in_microelements = Column(JSON, default=[]) # ["Железо", "Пребиотики", "Витамин C", "Омега-3"]
    wellness_rationale = Column(String(500), nullable=True) # Обоснование для плана
    
    # Batch Cooking & Storage
    storage_instructions = Column(String(500), nullable=True)
    reheating_instructions = Column(String(500), nullable=True)
    freezable = Column(Boolean, default=False)
    
    # JSON arrays
    ingredients = Column(JSON, nullable=False)
    steps = Column(JSON, nullable=False)

class RecipeImageCache(Base):
    __tablename__ = "recipe_image_cache"
    id = Column(Integer, primary_key=True, index=True)
    ingredients_hash = Column(String(64), unique=True, index=True, nullable=False)
    recipe_title = Column(String(255), nullable=False)
    image_url = Column(String(500), nullable=True)

class CheatSheetCache(Base):
    __tablename__ = "cheat_sheet_cache"
    profile_hash = Column(String(64), primary_key=True, index=True)
    prohibited_foods = Column(JSON, nullable=False)
