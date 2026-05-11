"""
E2E Tests for Payload Parameter Matrix.
Covers fasting logic, activity multipliers, diets, and BMR/TDEE calculations.
Run: pytest tests/test_e2e_payload_matrix.py -v
"""

import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.api.plan import UserProfilePayload
from app.services.assembler import PromptAssembler
from metrics_helper import calculate_metrics
from app.services.archetypes import ArchetypePromptFactory

def make_payload(**kwargs) -> dict:
    payload = {
        "age": 30,
        "gender": "male",
        "weight": 80,
        "height": 180,
        "goal": "Поддержание веса",
        "activity_level": "Не готов(а) сейчас",
        "meal_pattern": "3 приема (завтрак, обед, ужин)",
        "budget_level": "Средний",
        "cooking_time": "До 15 мин",
        "country": "Россия",
        "city": "Москва",
    }
    payload.update(kwargs)
    return payload


# ============================================================
# A. Fasting matrix (18 tests simulated)
# ============================================================

class TestFastingMatrix:
    
    @pytest.mark.parametrize("fast_type,fmt,meals", [
        ("daily", "14:10", "2 приема (обед, ужин)"),
        ("daily", "16:8", "2 приема (обед, ужин)"),
        ("daily", "18:6", "2 приема (обед, ужин)"),
        ("daily", "20:4", "2 приема (обед, ужин)"),
    ])
    def test_daily_fasting(self, fast_type, fmt, meals):
        p = make_payload(fasting_type=fast_type, daily_format=fmt, meal_pattern=meals)
        model = UserProfilePayload(**p)
        assert model.fasting_type == "daily"
        prompt = PromptAssembler.build_prompt(
            profile=model, context_text="",
            bmr=1500, tdee=1800, target_kcal=1800, days=3
        )
        assert fmt in prompt or fmt.replace(":", "_") in prompt or "голодани" in prompt.lower()
        
    @pytest.mark.parametrize("fast_type,fmt,days", [
        ("periodic", "5:2", [1, 4]),
        ("periodic", "24h", [2]),
    ])
    def test_periodic_fasting(self, fast_type, fmt, days):
        p = make_payload(fasting_type=fast_type, periodic_format=fmt, periodic_days=days)
        model = UserProfilePayload(**p)
        assert model.fasting_type == "periodic"
        assert len(model.periodic_days) == len(days)


# ============================================================
# B. Activity multiplier matrix
# ============================================================

class TestActivityMultipliers:

    @pytest.mark.parametrize("level,expected_tdee_ratio", [
        ("Не готов(а) сейчас", 1.2),
        ("1 раз", 1.375),
        ("2 раза", 1.375),
        ("3 раза", 1.55),
        ("4 и более", 1.725),
    ])
    def test_activity_tdee(self, level, expected_tdee_ratio):
        p = make_payload(activity_level=level)
        model = UserProfilePayload(**p)
        bmr, tdee, target = calculate_metrics(model)
        assert abs(tdee - (bmr * expected_tdee_ratio)) < 1.0


# ============================================================
# C. Budget & Cooking matrix
# ============================================================

class TestBudgetCooking:

    @pytest.mark.parametrize("budget", ["Экономный", "Средний", "Премиум"])
    @pytest.mark.parametrize("cooking", ["Готовлю каждый день", "Готовлю заранее", "Почти не готовлю"])
    def test_budget_cooking_combinations(self, budget, cooking):
        p = make_payload(budget_level=budget, cooking_time=cooking)
        model = UserProfilePayload(**p)
        assert model.budget_level == budget
        assert model.cooking_time == cooking


# ============================================================
# D. Diet restrictions matrix
# ============================================================

class TestDietRestrictions:

    def test_empty_restrictions(self):
        p = make_payload(restrictions=[], allergies=[])
        model = UserProfilePayload(**p)
        assert len(model.restrictions) == 0
        assert len(model.allergies) == 0
        
    def test_multiple_diets_allergies(self):
        p = make_payload(
            restrictions=["Веганство", "Без глютена"],
            allergies=["Орехи", "Молоко"]
        )
        model = UserProfilePayload(**p)
        prompt = PromptAssembler.build_prompt(
            profile=model, context_text="",
            bmr=1500, tdee=1800, target_kcal=1800, days=3
        )
        assert "Веганство" in prompt
        assert "Без глютена" in prompt
        assert "Орехи" in prompt


# ============================================================
# E. Tier mapping (tests days logic)
# ============================================================

class TestTierDaysMapping:

    # The days are usually passed from the billing endpoint, but we can verify
    # how prompt assembler handles days.
    @pytest.mark.parametrize("days", [3, 7])
    def test_prompt_days_instruction(self, days):
        p = make_payload()
        model = UserProfilePayload(**p)
        prompt = PromptAssembler.build_prompt(
            profile=model, context_text="",
            bmr=1500, tdee=1800, target_kcal=1800, days=days
        )
        assert f"Выдай рацион на {days} дн" in prompt or f"на {days} дней" in prompt or f"для {days} дней" in prompt


# ============================================================
# F. BMR/TDEE/Target calculations
# ============================================================

class TestMetricsCalculations:

    def test_male_maintenance(self):
        # M, 25, 80kg, 180cm, 1.55 (3 times/wk)
        p = make_payload(gender="male", age=25, weight=80, height=180, activity_level="3 раза", goal="Поддержание веса")
        model = UserProfilePayload(**p)
        bmr, tdee, target = calculate_metrics(model)
        # BMR = 10*80 + 6.25*180 - 5*25 + 5 = 800 + 1125 - 125 + 5 = 1805
        assert bmr == 1805
        assert tdee == int(1805 * 1.55)
        assert target == tdee

    def test_female_weight_loss(self):
        # F, 25, 60kg, 165cm, 1.375
        p = make_payload(gender="female", age=25, weight=60, height=165, activity_level="1 раз", goal="Снизить вес", target_weight=55)
        model = UserProfilePayload(**p)
        bmr, tdee, target = calculate_metrics(model)
        # BMR = 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25 -> 1345
        assert bmr == 1345
        assert tdee == int(1345 * 1.375)
        assert target < tdee
        assert target >= 1200 # Female floor

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
