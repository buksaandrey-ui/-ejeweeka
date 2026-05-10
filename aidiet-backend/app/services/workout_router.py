from typing import List, Dict, Any
from sqlalchemy.orm import Session
from app.models.workout_cache import WorkoutCache

class WorkoutRouter:
    """
    Математический движок (Router) для безопасного подбора тренировок.
    Использует детерминированные алгоритмы периодизации (сплиты) 
    и исключает тренировки с противопоказаниями.
    """

    @staticmethod
    def assign_workouts(
        db: Session,
        training_days: int,
        location: str,
        equipment: List[str],
        limitations: List[str],
        plan_days: int = 7
    ) -> Dict[str, Any]:
        """
        Возвращает словарь, где ключи - "day_1", "day_2", а значения - объекты тренировок (или None).
        """
        # 1. Загружаем подходящие тренировки из базы (фильтр по локации)
        # В реальном production здесь будет сложный векторный/SQL поиск, пока имитируем базовую логику.
        query = db.query(WorkoutCache).filter(WorkoutCache.location == location)
        available_workouts = query.all()
        
        # 2. Фильтрация безопасности (Guardrails)
        safe_workouts = []
        limitations_lower = [lim.lower() for lim in limitations]
        
        for w in available_workouts:
            is_safe = True
            # Проверяем на противопоказания
            for tag in (w.safety_tags or []):
                if tag.lower() in limitations_lower:
                    is_safe = False
                    break
            if is_safe:
                safe_workouts.append(w)
                
        # Если база пуста или все отфильтровалось - возвращаем пустой план
        # (в MVP мы можем отдавать fallback тренировку без инвентаря)
        if not safe_workouts:
            print("⚠️ Нет безопасных тренировок для данного профиля!")
            return {f"day_{i}": None for i in range(1, plan_days + 1)}

        # 3. Алгоритм сплитования (Периодизация)
        # Упрощенная логика распределения дней
        schedule = {}
        
        if training_days == 2:
            # 2 дня: тренировки на 1 и 4 день (чтобы было ~48-72 часа восстановления)
            workout_days = [1, 4]
        elif training_days == 3:
            # 3 дня: 1, 3, 5 день
            workout_days = [1, 3, 5]
        elif training_days == 4:
            # 4 дня: 1, 2, 4, 5 день
            workout_days = [1, 2, 4, 5]
        elif training_days >= 5:
            workout_days = [1, 2, 3, 5, 6]
        else:
            workout_days = []

        # 4. Сборка итогового JSON
        assigned_index = 0
        for i in range(1, plan_days + 1):
            day_key = f"day_{i}"
            if i in workout_days and safe_workouts:
                # Берем тренировки по кругу (Round Robin)
                w = safe_workouts[assigned_index % len(safe_workouts)]
                assigned_index += 1
                
                schedule[day_key] = {
                    "id": w.id,
                    "title": w.name,
                    "target_goal": w.target_goal,
                    "difficulty": w.difficulty_level,
                    "muscle_group": "FullBody", # Заглушка, позже брать из БД
                    "estimated_minutes": 45,
                    "exercises": w.exercises or []
                }
            else:
                schedule[day_key] = None
                
        return schedule
