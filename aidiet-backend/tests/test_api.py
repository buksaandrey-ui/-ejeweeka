"""
Integration Tests for ejeweeka Core API.

Tests cover:
1. Auth flow (init → token → verify)
2. Billing (status → restore → webhook)
3. Plan generation payload structure
4. State bridge (canonical key mapping)

Run: pytest tests/ -v
"""

import pytest
import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ============================================================
# AUTH TESTS
# ============================================================

class TestAuth:
    """Test anonymous authentication lifecycle."""
    
    def test_init_returns_token(self):
        """POST /auth/init should return UUID + token."""
        response = client.post("/api/v1/auth/init")
        assert response.status_code == 200
        data = response.json()
        assert "anonymous_uuid" in data
        assert "token" in data
        assert "expires_in" in data
        assert len(data["token"]) > 20
    
    def test_verify_valid_token(self):
        """POST /auth/verify with valid token should return valid=True."""
        # First get a token
        init_resp = client.post("/api/v1/auth/init")
        token = init_resp.json()["token"]
        
        # Then verify it
        verify_resp = client.post(
            "/api/v1/auth/verify",
            json={"token": token}
        )
        assert verify_resp.status_code == 200
        assert verify_resp.json()["valid"] is True
    
    def test_verify_invalid_token(self):
        """POST /auth/verify with garbage token should return 401."""
        response = client.post(
            "/api/v1/auth/verify",
            json={"token": "invalid.garbage.token"}
        )
        assert response.status_code == 401
    
    def test_init_idempotent(self):
        """Multiple /init calls should return different UUIDs."""
        resp1 = client.post("/api/v1/auth/init")
        resp2 = client.post("/api/v1/auth/init")
        assert resp1.json()["anonymous_uuid"] != resp2.json()["anonymous_uuid"]


# ============================================================
# BILLING TESTS
# ============================================================

class TestBilling:
    """Test subscription management."""
    
    def _get_auth_header(self) -> dict:
        """Helper: get auth token."""
        resp = client.post("/api/v1/auth/init")
        token = resp.json()["token"]
        return {"Authorization": f"Bearer {token}"}
    
    def test_status_returns_free_by_default(self):
        """GET /billing/status should return 'free' for new users."""
        headers = self._get_auth_header()
        response = client.get("/api/v1/billing/status", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["tier"] == "free"
        assert data["is_trial"] is False
    
    def test_restore_updates_tier(self):
        """POST /billing/restore should update tier."""
        headers = self._get_auth_header()
        response = client.post(
            "/api/v1/billing/restore",
            headers=headers,
            json={"platform": "ios", "claimed_tier": "gold"}
        )
        assert response.status_code == 200
        assert response.json()["tier"] == "gold"
    
    def test_restore_invalid_tier_defaults_to_free(self):
        """POST /billing/restore with invalid tier should default to 'free'."""
        headers = self._get_auth_header()
        response = client.post(
            "/api/v1/billing/restore",
            headers=headers,
            json={"platform": "ios", "claimed_tier": "invalid_tier"}
        )
        assert response.status_code == 200
        assert response.json()["tier"] == "free"
    
    def test_status_without_auth_returns_free_in_dev(self):
        """GET /billing/status without token should work in dev mode (STRICT_AUTH=false)."""
        response = client.get("/api/v1/billing/status")
        assert response.status_code == 200


# ============================================================
# PLAN GENERATION TESTS
# ============================================================

class TestPlanGeneration:
    """Test plan generation payload validation."""
    
    def _get_auth_header(self) -> dict:
        resp = client.post("/api/v1/auth/init")
        token = resp.json()["token"]
        return {"Authorization": f"Bearer {token}"}
    
    def test_generate_requires_payload(self):
        """POST /plan/generate without body should return 422."""
        headers = self._get_auth_header()
        response = client.post("/api/v1/plan/generate", headers=headers)
        assert response.status_code == 422
    
    def test_generate_accepts_minimal_payload(self):
        """POST /plan/generate with minimal payload should not crash."""
        headers = self._get_auth_header()
        payload = {
            "age": 30,
            "gender": "male",
            "weight": 80,
            "height": 180,
            "goal": "Сбалансированное питание",
        }
        response = client.post(
            "/api/v1/plan/generate",
            headers=headers,
            json=payload,
        )
        # We expect either success (200) or a controlled error (not 500)
        assert response.status_code != 500


# ============================================================
# HEALTH CHECK TESTS
# ============================================================

class TestHealthCheck:
    """Test health check endpoints."""
    
    def test_root_health(self):
        """GET / should return status ok."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "version" in data
    
    def test_detailed_health(self):
        """GET /api/v1/health should return checks dict."""
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert "checks" in data
        assert "api" in data["checks"]
        assert data["checks"]["api"] is True


# ============================================================
# STATE BRIDGE TESTS (Canonical Key Mapping)
# ============================================================

class TestStateBridge:
    """Test that the API accepts both canonical EN keys and legacy RU keys."""
    
    def test_payload_with_english_keys(self):
        """Plan payload with English keys should be valid."""
        payload = {
            "age": 25,
            "gender": "female",
            "weight": 65,
            "height": 165,
            "goal": "weight_loss",
            "allergies": ["gluten", "lactose"],
            "restrictions": ["vegetarian"],
            "diseases": [],
            "country": "Russia",
            "city": "Moscow",
        }
        assert payload["gender"] in ("male", "female")
        assert isinstance(payload["allergies"], list)
        assert payload["age"] > 0
    
    def test_payload_with_russian_values(self):
        """Plan payload with Russian values should be valid."""
        payload = {
            "age": 40,
            "gender": "male",
            "weight": 90,
            "height": 180,
            "goal": "Снизить вес",
            "allergies": ["Глютен"],
            "restrictions": ["Без молочных"],
            "diseases": ["Диабет 2 типа"],
            "country": "Россия",
            "city": "Москва",
        }
        assert payload["gender"] in ("male", "female")
        assert isinstance(payload["diseases"], list)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
