"""
Tests for Backend Hardening (Phase 3):
- Input validation (Pydantic field validators)
- Assembler safety guardrails
- Rate limiting setup
- Health check structure

Run: pytest tests/test_hardening.py -v
"""

import pytest
import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ============================================================
# INPUT VALIDATION TESTS
# ============================================================

class TestInputValidation:
    """Test Pydantic field validators on UserProfilePayload."""

    def _get_auth_header(self) -> dict:
        resp = client.post("/api/v1/auth/init")
        token = resp.json()["token"]
        return {"Authorization": f"Bearer {token}"}

    def _make_payload(self, **overrides):
        base = {
            "age": 30,
            "gender": "male",
            "weight": 80,
            "height": 180,
            "goal": "Сбалансированное питание",
            "activity_level": "Умеренная",
        }
        base.update(overrides)
        return base

    def test_reject_age_too_low(self):
        """Age < 10 should be rejected with 422."""
        headers = self._get_auth_header()
        payload = self._make_payload(age=5)
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_reject_age_too_high(self):
        """Age > 120 should be rejected with 422."""
        headers = self._get_auth_header()
        payload = self._make_payload(age=150)
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_reject_weight_negative(self):
        """Weight < 20 should be rejected."""
        headers = self._get_auth_header()
        payload = self._make_payload(weight=-5)
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_reject_height_zero(self):
        """Height = 0 should be rejected."""
        headers = self._get_auth_header()
        payload = self._make_payload(height=0)
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_reject_invalid_gender(self):
        """Gender 'robot' should be rejected."""
        headers = self._get_auth_header()
        payload = self._make_payload(gender="robot")
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_accept_valid_female_russian(self):
        """Gender 'Женский' should be accepted."""
        headers = self._get_auth_header()
        payload = self._make_payload(gender="Женский")
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        # Should not be 422 (validation error)
        assert response.status_code != 422

    def test_reject_goal_too_long(self):
        """Goal > 200 chars should be rejected."""
        headers = self._get_auth_header()
        payload = self._make_payload(goal="x" * 300)
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_reject_too_many_allergies(self):
        """More than 50 allergies should be rejected."""
        headers = self._get_auth_header()
        payload = self._make_payload(allergies=[f"allergy_{i}" for i in range(60)])
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code == 422

    def test_accept_valid_edge_cases(self):
        """Edge case: age=10, weight=20, height=100 should pass validation."""
        headers = self._get_auth_header()
        payload = self._make_payload(age=10, weight=20, height=100)
        response = client.post("/api/v1/plan/generate", headers=headers, json=payload)
        assert response.status_code != 422


# ============================================================
# ASSEMBLER GUARDRAILS TESTS
# ============================================================

class TestAssemblerGuardrails:
    """Test that assembler.py produces correct safety constraints."""

    def test_drug_food_rules_exist(self):
        """DRUG_FOOD_RULES should be defined in assembler."""
        from app.services.assembler import PromptAssembler
        assert hasattr(PromptAssembler, 'DRUG_FOOD_RULES')

    def test_warfarin_blocks_greens(self):
        """Warfarin should flag vitamin K-rich foods."""
        from app.services.assembler import PromptAssembler
        rules = PromptAssembler.DRUG_FOOD_RULES
        # DRUG_FOOD_RULES is a dict: {drug_name: rule_text}
        assert 'варфарин' in rules, "Warfarin rule missing from DRUG_FOOD_RULES"
        assert 'витамин' in rules['варфарин'].lower() or 'шпинат' in rules['варфарин'].lower()

    def test_blood_norms_defined(self):
        """BLOOD_NORMS should be defined for clinical parsing."""
        from app.services.assembler import PromptAssembler
        assert hasattr(PromptAssembler, 'BLOOD_NORMS')
        norms = PromptAssembler.BLOOD_NORMS
        assert 'vitamin_d' in norms or 'Витамин D' in str(norms)

    def test_build_prompt_returns_string(self):
        """build_prompt should return a non-empty string."""
        from app.services.assembler import PromptAssembler
        from unittest.mock import MagicMock

        profile = MagicMock()
        profile.gender = 'male'
        profile.age = 30
        profile.weight = 80
        profile.height = 180
        profile.goal = 'weight_loss'
        profile.diseases = []
        profile.allergies = []
        profile.medications = 'Нет'
        profile.supplements = 'Нет'
        profile.country = 'Россия'
        profile.city = 'Москва'
        profile.budget_level = 'Средний'
        profile.cooking_time = 'Без разницы'
        profile.fasting_status = False
        profile.meal_pattern = '3 приёма'
        profile.training_schedule = 'Без тренировок'
        profile.sleep_schedule = '8 часов'
        profile.liked_foods = []
        profile.disliked_foods = []
        profile.excluded_meal_types = []
        profile.restrictions = []
        profile.symptoms = []
        profile.motivation_barriers = []
        profile.womens_health = None
        profile.bmi = None
        profile.waist = None
        profile.body_type = None
        profile.blood_tests = None
        profile.supplement_openness = None
        profile.activity_level = 'Умеренная'
        profile.tier = 'T1'

        prompt = PromptAssembler.build_prompt(
            profile=profile,
            context_text="Тестовый контекст",
            bmr=1800,
            tdee=2200,
            target_kcal=1800,
            days=7,
            meals_per_day=3
        )
        assert isinstance(prompt, str)
        assert len(prompt) > 100


# ============================================================
# HEALTH CHECK STRUCTURE TESTS
# ============================================================

class TestHealthCheckHardened:
    """Test hardened health check responses."""

    def test_health_has_version(self):
        """GET /api/v1/health should return version 2.2.0."""
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        assert response.json()["version"] == "2.2.0"

    def test_health_has_environment(self):
        """GET /api/v1/health should return environment field."""
        response = client.get("/api/v1/health")
        data = response.json()
        assert "environment" in data

    def test_health_has_sentry_check(self):
        """GET /api/v1/health should include sentry in checks."""
        response = client.get("/api/v1/health")
        data = response.json()
        assert "sentry" in data["checks"]

    def test_root_returns_correct_version(self):
        """GET / should return version 2.2.0."""
        response = client.get("/")
        assert response.json()["version"] == "2.2.0"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
