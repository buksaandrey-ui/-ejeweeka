from sqlalchemy import Column, Integer, String, Text, JSON
from sqlalchemy.dialects.postgresql import JSONB
from app.db import Base

class WorkoutCache(Base):
    """
    Таблица для хранения проверенных тренировок (Workout Library).
    Вместо того чтобы ИИ выдумывал упражнения (что травмоопасно), 
    ИИ просто выбирает наиболее подходящую тренировку из этой базы 
    на основе профиля пользователя.
    """
    __tablename__ = "workouts_library"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    workout_type = Column(String(50), nullable=True) # aerobic, bodyweight, free_weights
    
    # Метаданные для роутинга (ИИ использует их для подбора)
    target_goal = Column(String(255), index=True) # похудение, набор массы, тонус
    difficulty_level = Column(String(100), index=True) # новичок, средний, про
    location = Column(String(100), index=True) # дома, зал
    
    description = Column(Text, nullable=True)
    
    # Целевые группы мышц: ["Ноги", "Ягодицы", "Кор"] или ["Верх", "Грудь", "Спина"]
    muscle_groups = Column(JSON, nullable=True, default=[])
    
    # Реальная длительность тренировки в минутах
    estimated_minutes = Column(Integer, nullable=True, default=45)
    
    # Необходимый инвентарь: ["гантели", "коврик"] или []
    equipment_required = Column(JSON, nullable=True, default=[])
    
    # Противопоказания: ["грыжа", "варикоз", "колени"]
    contraindications = Column(JSON, nullable=True, default=[])
    
    # Полная программа тренировки в формате JSON
    # Ожидаемая структура: [{"name": "...", "sets": 3, "reps_or_time": "12 раз", "rest_seconds": 60}]
    exercises = Column(JSON, nullable=False)
    
    # Дополнительные метки для безопасности (например, "без_прыжков", "для_грыжи")
    safety_tags = Column(JSON, nullable=True)
