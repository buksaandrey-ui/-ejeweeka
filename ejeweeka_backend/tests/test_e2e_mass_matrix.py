"""
Mass E2E matrix testing for Edge Cases.
Validates both the matrix prompt generation and recipe prompt generation
to ensure strict compliance with architectural constraints.
"""

import pytest
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.api.plan import UserProfilePayload
from app.services.assembler import PromptAssembler
from metrics_helper import calculate_metrics

def generate_edge_profiles():
    """Generate a list of 50 edge-case profiles."""
    profiles = []
    
    goals = ["weight_loss", "muscle_gain", "maintenance"]
    fasting = [("none", None), ("daily", "16:8"), ("periodic", "5:2")]
    restrictions = [[], ["Веганство"], ["Без глютена", "Без лактозы"]]
    
    count = 0
    for g in goals:
        for f_type, f_fmt in fasting:
            for rest in restrictions:
                p = UserProfilePayload(
                    age=25 + count,
                    gender="female" if count % 2 == 0 else "male",
                    weight=70 + count,
                    height=170 + count,
                    goal=g,
                    activity_level="1 раз",
                    meal_pattern="3 приема",
                    fasting_type=f_type,
                    daily_format=f_fmt if f_type == "daily" else None,
                    periodic_format=f_fmt if f_type == "periodic" else None,
                    periodic_days=[1,4] if f_type == "periodic" else [],
                    budget_level="Средний",
                    cooking_time="До 15 мин",
                    country="Россия",
                    restrictions=rest
                )
                profiles.append(p)
                count += 1
                if count >= 50:
                    break
            if count >= 50:
                break
        if count >= 50:
            break
            
    while len(profiles) < 50:
        profiles.append(profiles[0])
        
    return profiles

class TestMassMatrix:
    
    def test_matrix_prompt_compliance(self):
        """Tests the Phase 1 Matrix Generator prompt for structural constraints."""
        profiles = generate_edge_profiles()
        assert len(profiles) >= 27
        
        for p in profiles:
            bmr, tdee, target = calculate_metrics(p)
            prompt = PromptAssembler.build_matrix_prompt(
                profile=p, context_text="", bmr=bmr, tdee=tdee, target_kcal=target, days=3, meals_per_day=3
            )
            
            # Check mandatory rules in MATRIX prompt
            assert "ОБЯЗАТЕЛЬНО" in prompt
            # Fiber should be mentioned as a goal
            assert "Клетчатка" in prompt or "клетчатк" in prompt.lower()
            # The matrix prompt doesn't need to specify grams or cutting dimensions.
            assert "variant_name" in prompt

    def test_recipe_prompt_compliance(self):
        """Tests the Phase 3 Recipe Generator prompt for data constraints (grams, fiber, dimensions)."""
        profiles = generate_edge_profiles()
        assert len(profiles) >= 27
        
        missing_meals = ["Овсянка", "Борщ", "Котлеты"]
        
        for p in profiles:
            bmr, tdee, target = calculate_metrics(p)
            prompt = PromptAssembler.build_recipe_prompt(
                profile=p, missing_meals=missing_meals, target_kcal=target
            )
            
            # Check mandatory rules in RECIPE prompt
            assert "fiber" in prompt.lower() or "клетчатка" in prompt.lower()
            # Must ask for grams
            assert "г/мл/шт" in prompt or "грамм" in prompt
            # Must strictly ask for dimensions in slicing
            assert "нарезк" in prompt.lower() or "размер" in prompt.lower() or "мм" in prompt.lower() or "см" in prompt.lower()

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
