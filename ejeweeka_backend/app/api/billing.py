"""
Billing API — subscription management.
Handles restore purchases, status checks, and RevenueCat webhook stubs.

Production Implementation:
- /restore: validates subscription via DB record (RevenueCat integration ready)
- /status: returns subscription from PostgreSQL
- /webhook: updates DB based on RevenueCat server-to-server events

Zero-Knowledge: Only anonymous_uuid + tier stored. No PII.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session
from app.db import get_db
from app.models import User
from app.api.dependencies import get_current_user

import uuid
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================
# MODELS
# ============================================================

class RestoreRequest(BaseModel):
    """
    Client sends platform + receipt data for subscription restoration.
    In MVP: just trust the client-provided tier (to be replaced by RevenueCat).
    """
    platform: str = "ios"  # "ios" | "android"
    receipt_data: Optional[str] = None  # Apple/Google receipt (for RevenueCat)
    claimed_tier: str = "free"  # What the client claims their tier is


class SubscriptionStatus(BaseModel):
    tier: str  # "free" | "trial" | "black" | "gold" | "group_gold"
    is_trial: bool
    trial_expires_at: Optional[str] = None
    subscription_expires_at: Optional[str] = None
    can_restore: bool = True


class WebhookEvent(BaseModel):
    """RevenueCat webhook payload (simplified)."""
    event_type: str  # "INITIAL_PURCHASE", "RENEWAL", "CANCELLATION", "EXPIRATION"
    app_user_id: str
    product_id: Optional[str] = None
    expiration_at: Optional[str] = None


# ============================================================
# HELPERS
# ============================================================

VALID_TIERS = {"free", "trial", "black", "gold", "group_gold"}


def _get_or_create_user(db: Session, anonymous_uuid_str: str) -> User:
    """Get existing user or create a new record in PostgreSQL."""
    try:
        anon_uuid = uuid.UUID(anonymous_uuid_str)
    except (ValueError, AttributeError):
        # If anonymous_uuid is not a valid UUID (e.g. "anonymous"), generate one
        anon_uuid = uuid.uuid4()

    user = db.query(User).filter(User.anonymous_uuid == anon_uuid).first()
    if not user:
        user = User(
            anonymous_uuid=anon_uuid,
            subscription_status="free",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"[Billing] Created new user record: {anon_uuid}")
    else:
        # Update last_seen_at
        user.last_seen_at = datetime.now(timezone.utc)
        db.commit()

    return user


# ============================================================
# ENDPOINTS
# ============================================================

@router.post("/restore", response_model=SubscriptionStatus)
def restore_purchases(
    request: RestoreRequest,
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Restore purchases after reinstall or device change.
    
    MVP: Trusts client-provided tier (no receipt validation).
    Production: Calls RevenueCat /subscribers/{user_id} to verify.
    
    Apple requires this endpoint to exist — App Store Guideline 3.1.1.
    """
    user = _get_or_create_user(db, user_id)

    # MVP: trust the claimed tier
    # TODO: Replace with RevenueCat API call:
    #   response = requests.get(
    #       f"https://api.revenuecat.com/v1/subscribers/{user_id}",
    #       headers={"Authorization": f"Bearer {REVENUECAT_API_KEY}"}
    #   )
    #   entitlements = response.json()["subscriber"]["entitlements"]
    
    tier = request.claimed_tier if request.claimed_tier in VALID_TIERS else "free"
    
    user.subscription_status = tier
    
    if tier == "trial":
        user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=3)
    elif tier != "free":
        user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
    else:
        user.subscription_expires_at = None
    
    db.commit()
    db.refresh(user)
    
    logger.info(f"[Billing] Restored subscription for {user_id}: {tier}")
    
    return SubscriptionStatus(**user.to_subscription_dict())


@router.get("/status", response_model=SubscriptionStatus)
def get_subscription_status(
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Check current subscription status. Called on every app launch.
    
    Reads from PostgreSQL — persistent across server restarts.
    """
    user = _get_or_create_user(db, user_id)
    
    # Check trial/subscription expiration
    if user.subscription_expires_at and user.subscription_status != "free":
        if datetime.now(timezone.utc) > user.subscription_expires_at.replace(tzinfo=timezone.utc) if user.subscription_expires_at.tzinfo is None else user.subscription_expires_at:
            user.subscription_status = "free"
            user.subscription_expires_at = None
            db.commit()
            logger.info(f"[Billing] Subscription expired for {user_id}, downgraded to free")
    
    return SubscriptionStatus(**user.to_subscription_dict())


@router.post("/webhook")
def revenuecat_webhook(
    event: WebhookEvent,
    db: Session = Depends(get_db),
):
    """
    RevenueCat server-to-server webhook.
    
    Updates subscription status in PostgreSQL based on event_type.
    
    Event types:
    - INITIAL_PURCHASE: New subscription
    - RENEWAL: Subscription renewed
    - CANCELLATION: User cancelled (still active until expiry)
    - EXPIRATION: Subscription expired
    - BILLING_ISSUE: Payment failed
    """
    logger.info(f"📦 RevenueCat webhook: {event.event_type} for user {event.app_user_id}")
    
    user = _get_or_create_user(db, event.app_user_id)
    
    if event.event_type in ("INITIAL_PURCHASE", "RENEWAL"):
        # Determine tier from product_id
        product_id = (event.product_id or "").lower()
        if "gold" in product_id:
            user.subscription_status = "gold"
        elif "black" in product_id:
            user.subscription_status = "black"
        else:
            user.subscription_status = "black"  # default paid tier
        
        if event.expiration_at:
            try:
                user.subscription_expires_at = datetime.fromisoformat(event.expiration_at)
            except ValueError:
                user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
        else:
            user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
        
    elif event.event_type in ("EXPIRATION", "BILLING_ISSUE"):
        user.subscription_status = "free"
        user.subscription_expires_at = None
    
    db.commit()
    
    return {"status": "ok", "event_processed": event.event_type}
