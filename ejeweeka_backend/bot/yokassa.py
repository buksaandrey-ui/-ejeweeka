"""
ЮKassa payment integration for ejeweeka TG Concierge.

Flow:
1. User selects tier in Telegram → create_payment() → returns payment_url
2. User pays via ЮKassa → ЮKassa sends webhook → handle_webhook()
3. handle_webhook() activates subscription in DB
4. Bot notifies user

Environment:
- YOKASSA_SHOP_ID
- YOKASSA_SECRET_KEY
- WEBHOOK_BASE_URL (for return_url and webhook registration)
"""

import os
import uuid
import logging
import hashlib
import hmac
from typing import Optional

import httpx

logger = logging.getLogger("tg_concierge.yokassa")

YOKASSA_SHOP_ID = os.getenv("YOKASSA_SHOP_ID", "")
YOKASSA_SECRET_KEY = os.getenv("YOKASSA_SECRET_KEY", "")
YOKASSA_API_URL = "https://api.yookassa.ru/v3"
WEBHOOK_BASE_URL = os.getenv("WEBHOOK_BASE_URL", "https://ejeweeka-api.onrender.com")

# Tier → price mapping (RUB)
TIER_PRICES = {
    "black": {"amount": "490.00", "description": "ejeweeka Status Black (1 месяц)"},
    "gold": {"amount": "990.00", "description": "ejeweeka Status Gold (1 месяц)"},
}


async def create_payment(tier: str, anonymous_uuid: str, telegram_user_id: int) -> Optional[str]:
    """
    Create ЮKassa payment and return payment URL.
    
    Returns:
        Payment URL for user to complete payment, or None on error.
    """
    if tier not in TIER_PRICES:
        logger.error(f"Unknown tier: {tier}")
        return None

    price = TIER_PRICES[tier]
    idempotency_key = str(uuid.uuid4())

    payload = {
        "amount": {
            "value": price["amount"],
            "currency": "RUB"
        },
        "confirmation": {
            "type": "redirect",
            "return_url": f"{WEBHOOK_BASE_URL}/api/v1/payment/success?uuid={anonymous_uuid}"
        },
        "capture": True,
        "description": price["description"],
        "metadata": {
            "anonymous_uuid": anonymous_uuid,
            "telegram_user_id": str(telegram_user_id),
            "tier": tier,
        }
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{YOKASSA_API_URL}/payments",
                json=payload,
                auth=(YOKASSA_SHOP_ID, YOKASSA_SECRET_KEY),
                headers={
                    "Idempotence-Key": idempotency_key,
                    "Content-Type": "application/json",
                },
                timeout=10.0,
            )

        if response.status_code == 200:
            data = response.json()
            payment_url = data.get("confirmation", {}).get("confirmation_url")
            payment_id = data.get("id")
            logger.info(f"✅ Payment created: {payment_id} for {anonymous_uuid} → {tier}")
            return payment_url
        else:
            logger.error(f"ЮKassa error {response.status_code}: {response.text}")
            return None

    except Exception as e:
        logger.error(f"ЮKassa request failed: {e}")
        return None


def verify_webhook_signature(body: bytes, signature: str) -> bool:
    """
    Verify ЮKassa webhook signature (if configured).
    ЮKassa uses IP-based validation by default, but signature is recommended.
    """
    if not YOKASSA_SECRET_KEY:
        return True  # Skip validation in dev
    
    expected = hmac.new(
        YOKASSA_SECRET_KEY.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected, signature)


def parse_webhook_event(data: dict) -> Optional[dict]:
    """
    Parse ЮKassa webhook notification.
    
    Returns dict with:
        - event_type: "payment.succeeded" | "payment.canceled" | etc.
        - payment_id: str
        - anonymous_uuid: str (from metadata)
        - tier: str (from metadata)
        - telegram_user_id: str (from metadata)
    """
    try:
        event_type = data.get("event")
        payment = data.get("object", {})
        metadata = payment.get("metadata", {})

        return {
            "event_type": event_type,
            "payment_id": payment.get("id", ""),
            "anonymous_uuid": metadata.get("anonymous_uuid", ""),
            "tier": metadata.get("tier", "black"),
            "telegram_user_id": metadata.get("telegram_user_id", ""),
            "amount": payment.get("amount", {}).get("value", "0"),
            "status": payment.get("status", ""),
        }
    except Exception as e:
        logger.error(f"Webhook parse error: {e}")
        return None
