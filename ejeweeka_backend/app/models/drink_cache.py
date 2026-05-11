from sqlalchemy import Column, Integer, String, Float, Boolean, JSON
from app.db import Base

class DrinkCache(Base):
    __tablename__ = "drinks_library"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)
    
    # Макронутриенты на 100 мл
    calories = Column(Float, nullable=False, default=0.0)
    protein = Column(Float, nullable=False, default=0.0)
    fat = Column(Float, nullable=False, default=0.0)
    carbs = Column(Float, nullable=False, default=0.0)
    
    # Метаданные
    is_alcoholic = Column(Boolean, default=False)
    has_caffeine = Column(Boolean, default=False)
    
    # Региональная доступность: ["RU", "UAE", "GLOBAL", "SA"]
    region_tags = Column(JSON, default=["GLOBAL"])
