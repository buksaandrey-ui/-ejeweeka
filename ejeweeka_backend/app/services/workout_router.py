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
    async def assign_workouts(
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
        import json
        import asyncio
        import os
        from google import genai
        
        GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
        
        # 1. Загружаем подходящие тренировки из базы (фильтр по локации)
        query = db.query(WorkoutCache).filter(WorkoutCache.location == location)
        available_workouts = query.all()
        
        # 2. Фильтрация безопасности (Guardrails)
        safe_workouts = []
        limitations_lower = [lim.lower() for lim in limitations]
        
        for w in available_workouts:
            is_safe = True
            for tag in (w.safety_tags or []):
                if tag.lower() in limitations_lower:
                    is_safe = False
                    break
            if is_safe:
                safe_workouts.append(w)
                
        # [FALLBACK TO AI + FORCE-SAVE]: Если база пуста или все отфильтровалось
        if not safe_workouts:
            print(f"⚠️ Нет безопасных тренировок для {location} с ограничениями {limitations}. Генерация...")
            client = genai.Client(api_key=GEMINI_API_KEY)
            prompt = f"""
            Ты - фитнес-тренер реабилитолог. Сгенерируй 1 тренировку для пользователя.
            Локация: {location}. Инвентарь: {', '.join(equipment) if equipment else 'без инвентаря'}.
            Ограничения/Болезни: {', '.join(limitations) if limitations else 'нет'}.
            
            Тренировка должна быть абсолютно безопасна с учетом ограничений.
            Верни ТОЛЬКО валидный JSON:
            {{
                "name": "Название тренировки",
                "difficulty_level": "beginner",
                "target_goal": "health",
                "exercises": [
                    {{"name": "Упражнение 1", "sets": 3, "reps_or_time": "15 раз", "rest_seconds": 60}}
                ],
                "safety_tags": ["tag1", "tag2"]
            }}
            """
            try:
                response = await asyncio.to_thread(
                    client.models.generate_content, 
                    model='gemini-2.5-flash', 
                    contents=prompt
                )
                text = response.text.replace('```json', '').replace('```', '').strip()
                w_data = json.loads(text)
                
                # Создаем и сохраняем в базу (FORCE-SAVE)
                new_w = WorkoutCache(
                    name=w_data.get("name", "Сгенерированная тренировка"),
                    location=location,
                    workout_type=w_data.get("workout_type", "bodyweight"),
                    difficulty_level=w_data.get("difficulty_level", "beginner"),
                    target_goal=w_data.get("target_goal", "health"),
                    safety_tags=w_data.get("safety_tags", []),
                    exercises=w_data.get("exercises", [])
                )
                db.add(new_w)
                db.commit()
                db.refresh(new_w)
                safe_workouts.append(new_w)
            except Exception as e:
                print(f"⚠️ Ошибка генерации тренировки: {e}")
                db.rollback()
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
