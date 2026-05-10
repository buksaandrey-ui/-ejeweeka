"""
Test Assembler Logic — unit tests for prompt construction, medical guardrails,
allergen detection, drug-food interactions, blood norms, and normalization.

Run: pytest tests/test_assembler.py -v
"""

import pytest
from unittest.mock import MagicMock
from app.services.assembler import PromptAssembler
from app.api.plan import normalize_plan_for_frontend


# ============================================================
# HELPER: Create mock profile
# ============================================================

def make_profile(**overrides):
    """Create a mock profile with defaults matching a typical onboarding output."""
    p = MagicMock()
    defaults = {
        'gender': 'male', 'age': 30, 'weight': 80, 'height': 180,
        'goal': 'Сбалансированное питание', 'target_weight': None,
        'target_timeline_weeks': None, 'diseases': [], 'allergies': [],
        'medications': 'Нет', 'supplements': 'Нет', 'country': 'Россия',
        'city': 'Москва', 'budget_level': 'Средний', 'cooking_time': '30 минут',
        'fasting_status': False, 'meal_pattern': '3 приёма',
        'training_schedule': 'Без тренировок', 'sleep_schedule': '8 часов',
        'liked_foods': [], 'disliked_foods': [], 'excluded_meal_types': [],
        'restrictions': [], 'effective_restrictions': [], 'symptoms': [],
        'motivation_barriers': [], 'womens_health': None,
        'bmi': None, 'waist': None, 'body_type': None,
        'blood_tests': None, 'supplement_openness': None,
        'activity_level': 'Умеренная', 'tier': 'T1',
        'target_daily_fiber': 30,
    }
    defaults.update(overrides)
    for k, v in defaults.items():
        setattr(p, k, v)
    return p


# ============================================================
# GROUP 1: Prompt Construction — basic output validation
# ============================================================

class TestBuildPrompt:
    """Test build_prompt returns valid, complete prompts."""

    def test_returns_nonempty_string(self):
        profile = make_profile()
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="test context",
            bmr=1800, tdee=2200, target_kcal=1800, days=7, meals_per_day=3
        )
        assert isinstance(prompt, str)
        assert len(prompt) > 200

    def test_contains_calorie_target(self):
        profile = make_profile()
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1800, tdee=2200, target_kcal=1760, days=7
        )
        assert '1760' in prompt

    def test_contains_user_gender(self):
        profile = make_profile(gender='female')
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1300, tdee=1600, target_kcal=1300, days=3
        )
        assert 'female' in prompt

    def test_contains_rag_context(self):
        profile = make_profile()
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="Шпинат — источник железа",
            bmr=1800, tdee=2200, target_kcal=1800, days=7
        )
        assert 'Шпинат — источник железа' in prompt

    def test_days_in_system_role(self):
        profile = make_profile()
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1800, tdee=2200, target_kcal=1800, days=3
        )
        assert '3 дн' in prompt or 'на 3' in prompt


# ============================================================
# GROUP 2: Medical Guardrails — diseases, allergies, pregnancy
# ============================================================

class TestMedicalGuardrails:
    """Test medical safety blocks in the prompt."""

    def test_allergies_included(self):
        profile = make_profile(allergies=['Глютен', 'Лактоза'])
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1800, tdee=2200, target_kcal=1800, days=7
        )
        assert 'Глютен' in prompt
        assert 'Лактоза' in prompt

    def test_diseases_included(self):
        profile = make_profile(diseases=['Диабет 2 типа', 'Гипертония'])
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1800, tdee=2200, target_kcal=1800, days=7
        )
        assert 'Диабет 2 типа' in prompt
        assert 'Гипертония' in prompt

    def test_pregnancy_guardrail(self):
        profile = make_profile(
            gender='female',
            womens_health=['Беременность (1-й триместр)']
        )
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1500, tdee=1800, target_kcal=1800, days=7
        )
        assert 'БЕРЕМЕННОСТЬ' in prompt
        assert 'сырая рыба' in prompt or 'фолиевую' in prompt

    def test_pcos_guardrail(self):
        profile = make_profile(
            gender='female',
            womens_health=['СПКЯ']
        )
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1400, tdee=1700, target_kcal=1400, days=7
        )
        assert 'СПКЯ' in prompt
        assert 'Инсулин' in prompt or 'ГИ' in prompt

    def test_vlcd_warning(self):
        """Low calorie target should trigger VLCD protocol warning."""
        profile = make_profile()
        prompt = PromptAssembler.build_prompt(
            profile=profile, context_text="",
            bmr=1100, tdee=1300, target_kcal=1100, days=7
        )
        assert 'VLCD' in prompt


# ============================================================
# GROUP 3: Drug-Food Interactions
# ============================================================

class TestDrugFoodRules:
    """Test drug-food interaction database."""

    def test_rules_exist(self):
        assert hasattr(PromptAssembler, 'DRUG_FOOD_RULES')
        assert len(PromptAssembler.DRUG_FOOD_RULES) > 0

    def test_warfarin_rule(self):
        """Warfarin should have interaction rules."""
        rules = PromptAssembler.DRUG_FOOD_RULES
        # DRUG_FOOD_RULES is a dict: drug_name → rule_text
        warfarin_found = any(
            'варфарин' in key.lower()
            for key in rules.keys()
        )
        assert warfarin_found, "Warfarin rule missing from DRUG_FOOD_RULES"


# ============================================================
# GROUP 4: Blood Norms
# ============================================================

class TestBloodNorms:
    """Test blood test reference ranges."""

    def test_norms_exist(self):
        assert hasattr(PromptAssembler, 'BLOOD_NORMS')
        norms = PromptAssembler.BLOOD_NORMS
        assert len(norms) > 0

    def test_vitamin_d_in_norms(self):
        norms_str = str(PromptAssembler.BLOOD_NORMS).lower()
        assert 'витамин d' in norms_str or 'vitamin_d' in norms_str


# ============================================================
# GROUP 5: Normalize plan for frontend
# ============================================================

class TestNormalizePlan:
    """Test normalize_plan_for_frontend function."""

    def test_converts_meal_to_meal_type(self):
        plan = {
            'day_1': [
                {'meal': 'Завтрак', 'name': 'Каша', 'calories': 350, 'ingredients': []}
            ]
        }
        result = normalize_plan_for_frontend(plan)
        assert result['day_1'][0]['meal_type'] == 'breakfast'

    def test_lunch_mapping(self):
        plan = {
            'day_1': [
                {'meal': 'Обед', 'name': 'Суп', 'calories': 400, 'ingredients': []}
            ]
        }
        result = normalize_plan_for_frontend(plan)
        assert result['day_1'][0]['meal_type'] == 'lunch'

    def test_dinner_mapping(self):
        plan = {
            'day_1': [
                {'meal': 'Ужин', 'name': 'Рыба', 'calories': 380, 'ingredients': []}
            ]
        }
        result = normalize_plan_for_frontend(plan)
        assert result['day_1'][0]['meal_type'] == 'dinner'

    def test_snack_default(self):
        plan = {
            'day_1': [
                {'meal': 'Полдник', 'name': 'Йогурт', 'calories': 150, 'ingredients': []}
            ]
        }
        result = normalize_plan_for_frontend(plan)
        assert result['day_1'][0]['meal_type'] == 'snack'

    def test_nested_meals_format(self):
        """Plan with nested {meals: [...]} format should be flattened."""
        plan = {
            'day_1': {
                'meals': [
                    {'meal': 'Завтрак', 'name': 'Каша', 'calories': 300, 'ingredients': []}
                ]
            }
        }
        result = normalize_plan_for_frontend(plan)
        assert isinstance(result['day_1'], list)

    def test_steps_string_to_object(self):
        """Steps should be converted from strings to {title, text} objects."""
        plan = {
            'day_1': [
                {'meal': 'Обед', 'name': 'Суп', 'calories': 400,
                 'ingredients': [], 'steps': ['Нарезать овощи', 'Варить 20 минут']}
            ]
        }
        result = normalize_plan_for_frontend(plan)
        steps = result['day_1'][0]['steps']
        assert isinstance(steps[0], dict)
        assert 'title' in steps[0]
        assert 'text' in steps[0]


# ============================================================
# GROUP 6: Allergen Post-Validation (inline test of detection logic)
# ============================================================

class TestAllergenDetection:
    """Test the allergen detection logic extracted from plan.py."""

    @staticmethod
    def detect_allergens(plan_data: dict, allergies: list) -> list:
        """Replicate allergen detection from plan.py for unit testing."""
        warnings = []
        allergens_lower = [a.lower().strip() for a in allergies if a]
        for day_key, day_data in plan_data.items():
            if not day_key.startswith('day_'):
                continue
            meals_list = day_data.get('meals', day_data) if isinstance(day_data, dict) else day_data
            if not isinstance(meals_list, list):
                continue
            for meal in meals_list:
                if not isinstance(meal, dict):
                    continue
                for ing in (meal.get('ingredients') or []):
                    ing_name = (ing.get('name') or '').lower()
                    for allergen in allergens_lower:
                        if allergen and allergen in ing_name:
                            warnings.append(
                                f"{day_key}/{meal.get('meal', '?')}: '{ing.get('name')}' → '{allergen}'"
                            )
        return warnings

    def test_detects_gluten_in_bread(self):
        plan = {
            'day_1': [
                {'meal': 'Завтрак', 'ingredients': [
                    {'name': 'Хлеб пшеничный глютеновый', 'amount': 50, 'unit': 'г'}
                ]}
            ]
        }
        warnings = self.detect_allergens(plan, ['глютен'])
        assert len(warnings) == 1
        assert 'глютен' in warnings[0]

    def test_no_false_positive(self):
        plan = {
            'day_1': [
                {'meal': 'Обед', 'ingredients': [
                    {'name': 'Гречка', 'amount': 200, 'unit': 'г'}
                ]}
            ]
        }
        warnings = self.detect_allergens(plan, ['глютен'])
        assert len(warnings) == 0

    def test_multiple_allergens(self):
        plan = {
            'day_1': [
                {'meal': 'Завтрак', 'ingredients': [
                    {'name': 'Молоко коровье', 'amount': 200, 'unit': 'мл'},
                    {'name': 'Орехи грецкие', 'amount': 30, 'unit': 'г'},
                ]}
            ]
        }
        warnings = self.detect_allergens(plan, ['молоко', 'орех'])
        assert len(warnings) == 2

    def test_no_allergies_returns_empty(self):
        plan = {
            'day_1': [
                {'meal': 'Обед', 'ingredients': [
                    {'name': 'Рис', 'amount': 200, 'unit': 'г'}
                ]}
            ]
        }
        warnings = self.detect_allergens(plan, [])
        assert len(warnings) == 0

    def test_nested_meals_format(self):
        """Allergen detection should work with nested {meals: [...]} format."""
        plan = {
            'day_1': {
                'meals': [
                    {'meal': 'Ужин', 'ingredients': [
                        {'name': 'Креветки (морепродукты)', 'amount': 150, 'unit': 'г'}
                    ]}
                ]
            }
        }
        warnings = self.detect_allergens(plan, ['морепродукт'])
        assert len(warnings) == 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
