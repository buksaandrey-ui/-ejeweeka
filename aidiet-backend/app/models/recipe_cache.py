from sqlalchemy import Column, Integer, String, Float
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
    
    # JSON arrays
    ingredients = Column(JSONB, nullable=False)
    steps = Column(JSONB, nullable=False)

class RecipeImageCache(Base):
    __tablename__ = "recipe_image_cache"
    id = Column(Integer, primary_key=True, index=True)
    ingredients_hash = Column(String(64), unique=True, index=True, nullable=False)
    title = Column(String(255), nullable=False)
    image_url = Column(String(500), nullable=True)
