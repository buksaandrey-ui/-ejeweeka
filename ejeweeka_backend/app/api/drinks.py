from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.db import get_db
from app.models.drink_cache import DrinkCache
from typing import List

router = APIRouter()

@router.get("/drinks", tags=["drinks"])
def get_drinks(region: str = Query("GLOBAL"), db: Session = Depends(get_db)):
    """Получает список напитков для конкретного региона (с fallback на GLOBAL) без обращения к ИИ."""
    # MVP: просто отдаем все напитки, где region_tags содержит region или GLOBAL
    # В SQLAlchemy JSON это можно сделать через text() или jsonb операторы
    # Для простоты SQLite-совместимости отдадим все и отфильтруем в питоне
    all_drinks = db.query(DrinkCache).all()
    filtered = []
    for d in all_drinks:
        tags = d.region_tags or ["GLOBAL"]
        if region in tags or "GLOBAL" in tags:
            filtered.append({
                "id": d.id,
                "name": d.name,
                "calories": d.calories,
                "protein": d.protein,
                "fat": d.fat,
                "carbs": d.carbs,
                "is_alcoholic": d.is_alcoholic,
                "has_caffeine": d.has_caffeine
            })
    return {"status": "success", "drinks": filtered}
