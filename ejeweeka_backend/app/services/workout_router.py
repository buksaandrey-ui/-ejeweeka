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
        plan_days: int = 7,
        activity_types: List[str] = None,
        fasting_days: List[int] = None,
        fitness_level: str = "Новичок",
        target_goal: str = "Похудение"
    ) -> Dict[str, Any]:
        """
        Возвращает словарь, где ключи - "day_1", "day_2", а значения - объекты тренировок (или None).
        Логика:
        1. Если локация "на улице" или активность кардио (ходьба, бег) - выдается заглушка активности.
        2. Иначе: Загрузка из базы + фильтрация по безопасности
        3. Если база пуста — fallback на AI с автосохранением
        4. Сплит-распределение по группам мышц (без повторов подряд)
        5. Guardrail: Если день разгрузочный (fasting_days), заменять тяжелые тренировки на йогу/растяжку.
        """
        import json
        import asyncio
        import os
        from google import genai
        
        GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
        activity_types = activity_types or []
        fasting_days = fasting_days or []
        
        # 0. БЫСТРАЯ ЗАГЛУШКА ДЛЯ КАРДИО И УЛИЦЫ
        # Если юзер просто ходит, бегает, плавает или занимается на улице, мы не генерируем сеты/повторения.
        location_lower = location.lower()
        activity_str = ' '.join(activity_types).lower()
        is_cardio_only = any(act in activity_str for act in ['ходьба', 'бег', 'плавание', 'единоборства', 'свой спорт', 'вело', 'танцы'])
        
        if location_lower in ['outside', 'на улице'] or is_cardio_only:
            schedule = {}
            # Равномерно распределяем дни
            if training_days == 2: workout_days = [1, 4]
            elif training_days == 3: workout_days = [1, 3, 5]
            elif training_days == 4: workout_days = [1, 2, 4, 5]
            elif training_days >= 5: workout_days = [1, 2, 3, 5, 6]
            else: workout_days = []
                
            primary_activity = activity_types[0] if activity_types else "Твоя активность"
            for i in range(1, plan_days + 1):
                if i in workout_days:
                    # Guardrail: если день голодания, рекомендуем легкую активность
                    if i in fasting_days:
                        schedule[f"day_{i}"] = {
                            "title": f"Легкая активность (Голодание)",
                            "target_goal": "health",
                            "difficulty": "adaptive",
                            "muscle_group": "Общая",
                            "estimated_minutes": 30,
                            "exercises": [{"name": "Пешая прогулка", "sets": 1, "reps_or_time": "30 минут"}]
                        }
                    else:
                        schedule[f"day_{i}"] = {
                            "title": f"Твоя тренировка: {primary_activity}",
                            "target_goal": "health",
                            "difficulty": "adaptive",
                            "muscle_group": "Общая",
                            "estimated_minutes": 45,
                            "exercises": [] # Нет конкретных упражнений
                        }
                else:
                    schedule[f"day_{i}"] = None
            return schedule

        # 1. Загружаем подходящие тренировки из базы (фильтр по локации, уровню и цели)
        query = db.query(WorkoutCache).filter(
            WorkoutCache.location == location,
            WorkoutCache.difficulty_level == fitness_level,
            WorkoutCache.target_goal == target_goal
        )
        available_workouts = query.all()
        
        # Если ничего не найдено для строгих параметров, смягчаем цель
        if not available_workouts:
            query = db.query(WorkoutCache).filter(
                WorkoutCache.location == location,
                WorkoutCache.difficulty_level == fitness_level
            )
            available_workouts = query.all()
            
        # Если всё ещё пусто, игнорируем уровень (Fall-back)
        if not available_workouts:
            query = db.query(WorkoutCache).filter(WorkoutCache.location == location)
            available_workouts = query.all()
        
        # 2. Фильтрация безопасности (Guardrails)
        safe_workouts = []
        limitations_lower = [lim.lower() for lim in limitations]
        
        for w in available_workouts:
            is_safe = True
            # Проверяем safety_tags (старый формат)
            for tag in (w.safety_tags or []):
                if tag.lower() in limitations_lower:
                    is_safe = False
                    break
            # Проверяем contraindications (новый формат)
            if is_safe:
                for ci in (w.contraindications or []):
                    if ci.lower() in limitations_lower:
                        is_safe = False
                        break
            if is_safe:
                safe_workouts.append(w)
                
        # [FALLBACK TO AI + FORCE-SAVE]: Если база пуста или все отфильтровалось
        if not safe_workouts:
            print(f"⚠️ Нет безопасных тренировок для {location} с ограничениями {limitations}. Генерация...")
            client = genai.Client(api_key=GEMINI_API_KEY)
            
            # Генерируем несколько тренировок на разные группы мышц
            muscle_split = ["Верх (грудь, плечи, трицепс)", "Низ (ноги, ягодицы)", "Кор + кардио"]
            generated_workouts = []
            
            for muscle_focus in muscle_split:
                prompt = f"""
                Ты - фитнес-тренер реабилитолог. Сгенерируй 1 тренировку для пользователя.
                Локация: {location}. Инвентарь: {', '.join(equipment) if equipment else 'без инвентаря'}.
                Ограничения/Болезни: {', '.join(limitations) if limitations else 'нет'}.
                Уровень: {fitness_level}. Цель: {target_goal}.
                Фокус: {muscle_focus}.
                
                Тренировка должна быть абсолютно безопасна с учетом ограничений.
                Верни ТОЛЬКО валидный JSON:
                {{
                    "name": "Название тренировки",
                    "difficulty_level": "{fitness_level}",
                    "target_goal": "{target_goal}",
                    "muscle_groups": ["Группа1", "Группа2"],
                    "estimated_minutes": 40,
                    "equipment_required": [],
                    "contraindications": [],
                    "exercises": [
                        {{"name": "Упражнение 1", "sets": 3, "reps_or_time": "15 раз", "rest_seconds": 60,
                          "muscle_target": "Целевая мышца", "technique_notes": "Спина прямая, колени не выходят за носки"}}
                    ],
                    "safety_tags": ["tag1"]
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
                        muscle_groups=w_data.get("muscle_groups", []),
                        estimated_minutes=w_data.get("estimated_minutes", 40),
                        equipment_required=w_data.get("equipment_required", []),
                        contraindications=w_data.get("contraindications", []),
                        safety_tags=w_data.get("safety_tags", []),
                        exercises=w_data.get("exercises", [])
                    )
                    db.add(new_w)
                    db.commit()
                    db.refresh(new_w)
                    generated_workouts.append(new_w)
                except Exception as e:
                    print(f"⚠️ Ошибка генерации тренировки ({muscle_focus}): {e}")
                    db.rollback()
            
            if not generated_workouts:
                return {f"day_{i}": None for i in range(1, plan_days + 1)}
            safe_workouts = generated_workouts

        # 3. Алгоритм сплитования с учётом мышечных групп
        schedule = {}
        
        if training_days == 2:
            workout_days = [1, 4]
        elif training_days == 3:
            workout_days = [1, 3, 5]
        elif training_days == 4:
            workout_days = [1, 2, 4, 5]
        elif training_days >= 5:
            workout_days = [1, 2, 3, 5, 6]
        else:
            workout_days = []

        # Группируем тренировки по muscle_groups для сплит-ротации
        # Цель: не ставить две тренировки на одну группу мышц подряд
        used_muscle_groups = set()
        assigned_index = 0
        
        for i in range(1, plan_days + 1):
            day_key = f"day_{i}"
            if i in workout_days and safe_workouts:
                # Ищем тренировку, у которой мышечные группы не совпадают с предыдущим днём
                best_workout = None
                best_idx = assigned_index % len(safe_workouts)
                
                for offset in range(len(safe_workouts)):
                    candidate_idx = (assigned_index + offset) % len(safe_workouts)
                    candidate = safe_workouts[candidate_idx]
                    candidate_muscles = set(mg.lower() for mg in (candidate.muscle_groups or []))
                    
                    # Если нет пересечения с предыдущим днём — идеально
                    if not candidate_muscles.intersection(used_muscle_groups):
                        best_workout = candidate
                        best_idx = candidate_idx
                        break
                
                # Если все пересекаются — берём по кругу (лучше чем ничего)
                if best_workout is None:
                    best_workout = safe_workouts[assigned_index % len(safe_workouts)]
                
                assigned_index = best_idx + 1
                used_muscle_groups = set(mg.lower() for mg in (best_workout.muscle_groups or []))
                
                
                # GUARDRAIL: Если день голодания, заменяем тяжелую тренировку на йогу
                if i in fasting_days:
                    schedule[day_key] = {
                        "id": best_workout.id, # сохраняем id для совместимости
                        "title": "Восстановительная растяжка (Голодание)",
                        "target_goal": "recovery",
                        "difficulty": "beginner",
                        "muscle_group": "Всё тело",
                        "estimated_minutes": 20,
                        "equipment_required": ["Коврик"],
                        "exercises": [
                            {"name": "Мягкая суставная разминка", "sets": 1, "reps_or_time": "5 мин", "rest_seconds": 0, "muscle_target": "Суставы"},
                            {"name": "Растяжка спины и ног", "sets": 1, "reps_or_time": "10 мин", "rest_seconds": 0, "muscle_target": "Связки"},
                            {"name": "Дыхательная практика", "sets": 1, "reps_or_time": "5 мин", "rest_seconds": 0, "muscle_target": "ЦНС"}
                        ]
                    }
                else:
                    schedule[day_key] = {
                        "id": best_workout.id,
                        "title": best_workout.name,
                        "target_goal": best_workout.target_goal,
                        "difficulty": best_workout.difficulty_level,
                        "muscle_group": ", ".join(best_workout.muscle_groups) if best_workout.muscle_groups else "Общая",
                        "estimated_minutes": best_workout.estimated_minutes or 45,
                        "equipment_required": best_workout.equipment_required or [],
                        "exercises": best_workout.exercises or []
                    }
            else:
                schedule[day_key] = None
                used_muscle_groups = set()  # Сброс при дне отдыха
                
        return schedule
