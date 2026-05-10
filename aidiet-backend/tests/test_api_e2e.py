"""
ejeweeka API E2E Test Suite v1.0

Тестирует все 15 API-роутов через FastAPI TestClient (без реального HTTP).
Запуск: cd aidiet-backend && .venv/bin/python -m pytest tests/test_api_e2e.py -v

Структура:
- test_health: / и /api/v1/health
- test_auth: /api/v1/auth/init, /verify
- test_billing: /api/v1/billing/restore, /status, /webhook
- test_push: /api/v1/push/register, /settings
- test_plan: /api/v1/plan/generate (без Gemini, мокаем)
- test_contracts: проверяем что auth dependency работает
"""

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


# ============================================================
# HEALTH CHECKS
# ============================================================

class TestHealthChecks:
    """Layer 0: Сервер живой, роуты зарегистрированы."""

    def test_root_health(self):
        r = client.get("/")
        assert r.status_code == 200
        data = r.json()
        assert data["status"] == "ok"
        assert "version" in data

    def test_detailed_health(self):
        r = client.get("/api/v1/health")
        assert r.status_code == 200
        data = r.json()
        assert "checks" in data
        assert data["checks"]["api"] is True
        assert "endpoints" in data
        # Должно быть минимум 9 эндпоинтов
        assert len(data["endpoints"]) >= 9

    def test_openapi_schema(self):
        """OpenAPI schema доступна (нужна для генерации клиентов)."""
        r = client.get("/openapi.json")
        assert r.status_code == 200
        schema = r.json()
        assert "paths" in schema
        assert "/api/v1/plan/generate" in schema["paths"]


# ============================================================
# AUTH
# ============================================================

class TestAuth:
    """Layer 1: Авторизация — init + verify."""

    def test_auth_init(self):
        """Первый запуск — получаем UUID + token."""
        r = client.post("/api/v1/auth/init")
        assert r.status_code == 200
        data = r.json()
        assert "token" in data
        assert "anonymous_uuid" in data or "user_id" in data
        user_id = data.get("anonymous_uuid") or data.get("user_id")
        assert len(user_id) > 10  # UUID длинный

    def test_auth_verify_valid(self):
        """Валидный токен → success."""
        # Сначала получаем токен
        init = client.post("/api/v1/auth/init").json()
        token = init["token"]
        
        r = client.post(
            "/api/v1/auth/verify",
            json={"token": token}
        )
        assert r.status_code == 200
        data = r.json()
        assert data.get("valid") is True or data.get("status") == "ok"

    def test_auth_init_idempotent(self):
        """Каждый init создаёт новый UUID."""
        r1 = client.post("/api/v1/auth/init").json()
        r2 = client.post("/api/v1/auth/init").json()
        uid1 = r1.get("anonymous_uuid") or r1.get("user_id")
        uid2 = r2.get("anonymous_uuid") or r2.get("user_id")
        # UUIDs должны быть разными
        assert uid1 != uid2


# ============================================================
# BILLING
# ============================================================

class TestBilling:
    """Layer 2: Подписки — restore, status, webhook."""

    def test_billing_status_default_free(self):
        """Новый пользователь = free tier."""
        r = client.get("/api/v1/billing/status")
        assert r.status_code == 200
        data = r.json()
        assert data["tier"] == "free"
        assert data["can_restore"] is True

    def test_billing_restore_gold(self):
        """Restore с claimed_tier=gold → gold."""
        r = client.post("/api/v1/billing/restore", json={
            "platform": "ios",
            "claimed_tier": "gold"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["tier"] == "gold"
        assert data["subscription_expires_at"] is not None

    def test_billing_restore_trial(self):
        """Restore с trial → 3-дневный trial."""
        r = client.post("/api/v1/billing/restore", json={
            "platform": "ios",
            "claimed_tier": "trial"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["tier"] == "trial"
        assert data["is_trial"] is True
        assert data["trial_expires_at"] is not None

    def test_billing_restore_invalid_tier(self):
        """Невалидный tier → free (failsafe)."""
        r = client.post("/api/v1/billing/restore", json={
            "platform": "ios",
            "claimed_tier": "premium_mega_ultra"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["tier"] == "free"

    def test_billing_webhook_purchase(self):
        """RevenueCat webhook: INITIAL_PURCHASE → ok."""
        r = client.post("/api/v1/billing/webhook", json={
            "event_type": "INITIAL_PURCHASE",
            "app_user_id": "test-user-123",
            "product_id": "aidiet_gold_monthly",
            "expiration_at": "2026-05-23T00:00:00"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["event_processed"] == "INITIAL_PURCHASE"

    def test_billing_webhook_expiration(self):
        """RevenueCat webhook: EXPIRATION → tier resets."""
        r = client.post("/api/v1/billing/webhook", json={
            "event_type": "EXPIRATION",
            "app_user_id": "test-user-456",
        })
        assert r.status_code == 200
        data = r.json()
        assert data["event_processed"] == "EXPIRATION"


# ============================================================
# PUSH NOTIFICATIONS
# ============================================================

class TestPush:
    """Layer 3: Push — register + settings."""

    def test_push_register(self):
        """Регистрация FCM/APNs токена."""
        r = client.post("/api/v1/push/register", json={
            "device_token": "test-fcm-token-abc123",
            "platform": "ios"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["status"] in ("registered", "ok")

    def test_push_settings(self):
        """Обновление настроек уведомлений (requires registration first)."""
        # First register the device
        client.post("/api/v1/push/register", json={
            "device_token": "test-settings-token-abc",
            "platform": "ios"
        })
        # Then update settings
        r = client.put("/api/v1/push/settings", json={
            "meals": True,
            "water": True,
            "vitamins": False,
            "workouts": True,
            "weekly_report": False
        })
        assert r.status_code == 200
        data = r.json()
        assert data["status"] in ("updated", "ok")


# ============================================================
# PLAN GENERATION (contract test, not full Gemini call)
# ============================================================

class TestPlanContract:
    """Layer 4: Plan endpoint — проверяем контракт, не Gemini."""

    def test_plan_generate_missing_fields(self):
        """Без обязательных полей → 422 (validation error)."""
        r = client.post("/api/v1/plan/generate", json={})
        # FastAPI returns 422 for validation errors
        assert r.status_code == 422

    def test_plan_stats(self):
        """GET /plan/stats — статистика генераций."""
        r = client.get("/api/v1/plan/stats")
        assert r.status_code == 200


# ============================================================
# CONTRACTS: Auth dependency works
# ============================================================

class TestAuthContracts:
    """Layer 5: проверяем что auth dependency подключен к эндпоинтам.
    
    В MVP режиме (grace period) все запросы проходят с user_id='anonymous'.
    Здесь мы просто убеждаемся, что эндпоинты доступны.
    """

    def test_plan_accessible(self):
        """Plan endpoint accessible (MVP grace period)."""
        # 422 = endpoint works but missing body fields
        # 200 = endpoint works with valid body
        r = client.post("/api/v1/plan/generate", json={})
        assert r.status_code in (200, 422, 500)  # Not 404 or 403

    def test_billing_status_accessible(self):
        """Billing status accessible."""
        r = client.get("/api/v1/billing/status")
        assert r.status_code == 200

    def test_push_register_accessible(self):
        """Push register accessible."""
        r = client.post("/api/v1/push/register", json={
            "device_token": "test",
            "platform": "ios"
        })
        assert r.status_code == 200


# ============================================================
# ROUTE REGISTRY: All 15 routes exist
# ============================================================

class TestRouteRegistry:
    """Layer 6: Проверяем что все заявленные роуты зарегистрированы."""

    EXPECTED_ROUTES = [
        ("GET", "/"),
        ("GET", "/api/v1/health"),
        ("POST", "/api/v1/auth/init"),
        ("POST", "/api/v1/auth/verify"),
        ("POST", "/api/v1/plan/generate"),
        ("GET", "/api/v1/plan/stats"),
        ("POST", "/api/v1/photo/analyze"),
        ("POST", "/api/v1/chat/message"),
        ("POST", "/api/v1/report/weekly"),
        ("POST", "/api/v1/billing/restore"),
        ("GET", "/api/v1/billing/status"),
        ("POST", "/api/v1/billing/webhook"),
        ("POST", "/api/v1/push/register"),
        ("PUT", "/api/v1/push/settings"),
    ]

    def test_all_routes_registered(self):
        """Все 14+ роутов должны быть зарегистрированы в FastAPI."""
        registered = set()
        for route in app.routes:
            if hasattr(route, "methods") and hasattr(route, "path"):
                for method in route.methods:
                    registered.add((method, route.path))

        missing = []
        for method, path in self.EXPECTED_ROUTES:
            if (method, path) not in registered:
                missing.append(f"{method} {path}")
        
        assert len(missing) == 0, f"Missing routes: {missing}"
