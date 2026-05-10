from sqlalchemy import Column, Integer, String, Text
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
    
    # Метаданные для роутинга (ИИ использует их для подбора)
    target_goal = Column(String(50), index=True) # похудение, набор массы, тонус
    difficulty_level = Column(String(50), index=True) # новичок, средний, про
    location = Column(String(50), index=True) # дома, зал
    
    description = Column(Text, nullable=True)
    
    # Полная программа тренировки в формате JSON
    # Ожидаемая структура: [{"exercise_name": "...", "sets": 3, "reps": 12, "video_url": "...", "rest_sec": 60}]
    exercises = Column(JSONB, nullable=False)
    
    # Дополнительные метки для безопасности (например, "без_прыжков", "для_грыжи")
    safety_tags = Column(JSONB, nullable=True)
