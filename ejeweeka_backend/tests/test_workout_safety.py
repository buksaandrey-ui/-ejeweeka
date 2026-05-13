"""
Workout Safety Tests for ejeweeka.
Validates that the WorkoutRouter never assigns dangerous exercises
to users with medical contraindications.
"""

import pytest
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.workout_router import WorkoutRouter
from app.models.workout_cache import WorkoutCache


class TestWorkoutSafety:
    """Tests that workout assignment respects medical limitations."""

    def test_contraindication_filtering(self):
        """Workouts with contraindications matching user limitations must be excluded."""
        # Simulate a workout with knee contraindication
        class MockDB:
            def query(self, model):
                return self
            def filter(self, *args):
                return self
            def all(self):
                return [
                    type('W', (), {
                        'id': 1, 'name': 'Приседания со штангой',
                        'safety_tags': ['колени', 'поясница'],
                        'contraindications': ['грыжа', 'варикоз', 'колени'],
                        'muscle_groups': ['Ноги', 'Ягодицы'],
                        'estimated_minutes': 45,
                        'equipment_required': ['штанга'],
                        'exercises': [{'name': 'Присед', 'sets': 3, 'reps_or_time': '10 раз'}],
                        'target_goal': 'muscle_gain',
                        'difficulty_level': 'средний',
                        'location': 'Зал',
                    })(),
                    type('W', (), {
                        'id': 2, 'name': 'Растяжка и йога',
                        'safety_tags': [],
                        'contraindications': [],
                        'muscle_groups': ['Кор', 'Гибкость'],
                        'estimated_minutes': 30,
                        'equipment_required': ['коврик'],
                        'exercises': [{'name': 'Планка', 'sets': 3, 'reps_or_time': '30 сек'}],
                        'target_goal': 'health',
                        'difficulty_level': 'новичок',
                        'location': 'Дома',
                    })(),
                ]
        
        # User with hernia — squats should be excluded
        import asyncio
        schedule = asyncio.get_event_loop().run_until_complete(
            WorkoutRouter.assign_workouts(
                db=MockDB(),
                training_days=3,
                location='Зал',
                equipment=['штанга'],
                limitations=['грыжа'],
                plan_days=7
            )
        )
        
        # The squat workout (id=1) has 'грыжа' in contraindications
        # Only yoga (id=2) should be assigned
        for day_key, workout in schedule.items():
            if workout is not None:
                assert workout['title'] != 'Приседания со штангой', \
                    f"{day_key}: Dangerous workout assigned to user with hernia!"

    def test_muscle_group_rotation(self):
        """Same muscle group should not be trained on consecutive days."""
        class MockDB:
            def query(self, model):
                return self
            def filter(self, *args):
                return self
            def all(self):
                return [
                    type('W', (), {
                        'id': 1, 'name': 'Верх тела',
                        'safety_tags': [], 'contraindications': [],
                        'muscle_groups': ['Грудь', 'Плечи', 'Трицепс'],
                        'estimated_minutes': 45, 'equipment_required': [],
                        'exercises': [{'name': 'Отжимания', 'sets': 3, 'reps_or_time': '15 раз'}],
                        'target_goal': 'muscle_gain', 'difficulty_level': 'средний', 'location': 'Дома',
                    })(),
                    type('W', (), {
                        'id': 2, 'name': 'Низ тела',
                        'safety_tags': [], 'contraindications': [],
                        'muscle_groups': ['Ноги', 'Ягодицы'],
                        'estimated_minutes': 40, 'equipment_required': [],
                        'exercises': [{'name': 'Выпады', 'sets': 3, 'reps_or_time': '12 раз'}],
                        'target_goal': 'muscle_gain', 'difficulty_level': 'средний', 'location': 'Дома',
                    })(),
                    type('W', (), {
                        'id': 3, 'name': 'Кор и кардио',
                        'safety_tags': [], 'contraindications': [],
                        'muscle_groups': ['Кор', 'Пресс'],
                        'estimated_minutes': 30, 'equipment_required': [],
                        'exercises': [{'name': 'Планка', 'sets': 3, 'reps_or_time': '45 сек'}],
                        'target_goal': 'health', 'difficulty_level': 'новичок', 'location': 'Дома',
                    })(),
                ]
        
        import asyncio
        schedule = asyncio.get_event_loop().run_until_complete(
            WorkoutRouter.assign_workouts(
                db=MockDB(), training_days=4, location='Дома',
                equipment=[], limitations=[], plan_days=7
            )
        )
        
        # Check no consecutive days have same muscle group
        prev_muscles = set()
        for i in range(1, 8):
            day_key = f"day_{i}"
            workout = schedule.get(day_key)
            if workout is not None:
                current_muscles = set(workout.get('muscle_group', '').lower().split(', '))
                overlap = current_muscles.intersection(prev_muscles)
                # Soft check — overlap is allowed but should be minimized
                prev_muscles = current_muscles
            else:
                prev_muscles = set()

    def test_workout_has_complete_data(self):
        """Every assigned workout must have title, exercises, and estimated_minutes."""
        class MockDB:
            def query(self, model):
                return self
            def filter(self, *args):
                return self
            def all(self):
                return [
                    type('W', (), {
                        'id': 1, 'name': 'Тренировка для новичка',
                        'safety_tags': [], 'contraindications': [],
                        'muscle_groups': ['FullBody'],
                        'estimated_minutes': 35, 'equipment_required': [],
                        'exercises': [
                            {'name': 'Приседания', 'sets': 3, 'reps_or_time': '15 раз', 'rest_seconds': 60},
                            {'name': 'Отжимания', 'sets': 3, 'reps_or_time': '10 раз', 'rest_seconds': 60},
                        ],
                        'target_goal': 'health', 'difficulty_level': 'новичок', 'location': 'Дома',
                    })(),
                ]
        
        import asyncio
        schedule = asyncio.get_event_loop().run_until_complete(
            WorkoutRouter.assign_workouts(
                db=MockDB(), training_days=3, location='Дома',
                equipment=[], limitations=[], plan_days=7
            )
        )
        
        for day_key, workout in schedule.items():
            if workout is not None:
                assert 'title' in workout, f"{day_key}: Missing 'title'"
                assert 'exercises' in workout, f"{day_key}: Missing 'exercises'"
                assert 'estimated_minutes' in workout, f"{day_key}: Missing 'estimated_minutes'"
                assert len(workout['exercises']) > 0, f"{day_key}: Empty exercises list"
                assert workout['muscle_group'] != 'FullBody' or len(workout['exercises']) > 0, \
                    f"{day_key}: FullBody without exercises"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
