"""
Web Billing API — ЮKassa endpoints for Russian web checkout (ejeweeka.ru).
NOT accessible from iOS app. Web-only.

Endpoints: apply-promo, create-payment, webhook, subscription management, restore.
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session
from app.db import get_db
from app.models.billing import (
    BillingAccount, Entitlement, WebOrder, WebSubscription,
    PromoCode, MagicLoginToken, BillingEvent,
)

import uuid
import hashlib
import hmac
import secrets
import logging
import os

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/web", tags=["web-billing"])

YOOKASSA_SECRET = os.getenv("YOOKASSA_SECRET_KEY", "")

# Price table (RUB)
PRICES = {
    ("black", "month"): 490,
    ("black", "year"): 4900,
    ("gold", "month"): 990,
    ("gold", "year"): 9990,
}


def _hash(value: str) -> str:
    return hashlib.sha256(value.strip().lower().encode()).hexdigest()


# ── Schemas ──────────────────────────────────────────────────────

class ApplyPromoRequest(BaseModel):
    code: str
    tier: str
    period: str

class ApplyPromoResponse(BaseModel):
    valid: bool
    discount_type: Optional[str] = None
    discount_value: Optional[float] = None
    amount_original: float
    amount_final: float

class CreatePaymentRequest(BaseModel):
    email: str
    tier: str
    period: str
    promo_code: Optional[str] = None

class RestoreStartRequest(BaseModel):
    email: str

class RestoreConfirmRequest(BaseModel):
    email: str
    code: str

class SubscriptionStatusResponse(BaseModel):
    status: str
    tier: str
    period: str
    expires_at: Optional[str] = None
    next_charge_at: Optional[str] = None

class CancelRequest(BaseModel):
    email: str


# ── Endpoints ────────────────────────────────────────────────────

@router.post("/checkout/apply-promo", response_model=ApplyPromoResponse)
def apply_promo(req: ApplyPromoRequest, db: Session = Depends(get_db)):
    """Apply promo code to calculate discount. Web-only."""
    base_price = PRICES.get((req.tier, req.period))
    if not base_price:
        raise HTTPException(status_code=400, detail="Invalid tier/period")

    code_h = _hash(req.code)
    promo = db.query(PromoCode).filter(
        PromoCode.code_hash == code_h,
        PromoCode.is_active == True,
    ).first()

    now = datetime.now(timezone.utc)
    if not promo:
        return ApplyPromoResponse(valid=False, amount_original=base_price, amount_final=base_price)

    if promo.ends_at and promo.ends_at < now:
        return ApplyPromoResponse(valid=False, amount_original=base_price, amount_final=base_price)

    if promo.usage_limit and promo.used_count >= promo.usage_limit:
        return ApplyPromoResponse(valid=False, amount_original=base_price, amount_final=base_price)

    # Check tier applicability
    if promo.applies_to_tiers and req.tier not in promo.applies_to_tiers:
        return ApplyPromoResponse(valid=False, amount_original=base_price, amount_final=base_price)

    # Calculate discount
    if promo.discount_type == "percent":
        discount = base_price * float(promo.discount_value) / 100
    else:
        discount = float(promo.discount_value)

    final = max(base_price - discount, 0)

    return ApplyPromoResponse(
        valid=True,
        discount_type=promo.discount_type,
        discount_value=float(promo.discount_value),
        amount_original=base_price,
        amount_final=final,
    )


@router.post("/checkout/create-payment")
def create_payment(req: CreatePaymentRequest, db: Session = Depends(get_db)):
    """Create ЮKassa payment for web checkout."""
    base_price = PRICES.get((req.tier, req.period))
    if not base_price:
        raise HTTPException(status_code=400, detail="Invalid tier/period")

    email_h = _hash(req.email)

    # Find or create billing account
    ba = db.query(BillingAccount).filter(BillingAccount.email_hash == email_h).first()
    if not ba:
        ba = BillingAccount(email_hash=email_h, encrypted_email=req.email)  # TODO: encrypt
        db.add(ba)
        db.flush()

    # Apply promo if provided
    discount = 0
    promo_id = None
    if req.promo_code:
        code_h = _hash(req.promo_code)
        promo = db.query(PromoCode).filter(PromoCode.code_hash == code_h, PromoCode.is_active == True).first()
        if promo:
            if promo.discount_type == "percent":
                discount = base_price * float(promo.discount_value) / 100
            else:
                discount = float(promo.discount_value)
            promo_id = promo.id
            promo.used_count += 1

    final_amount = max(base_price - discount, 0)

    # Create web order
    order = WebOrder(
        billing_account_id=ba.id,
        status="pending",
        tier=req.tier,
        period=req.period,
        amount_original=base_price,
        discount_amount=discount,
        amount_final=final_amount,
        currency="RUB",
        promo_code_id=promo_id,
    )
    db.add(order)
    db.commit()

    # TODO: Call ЮKassa API to create payment
    # yookassa_response = yookassa_client.create_payment(...)
    # order.yookassa_payment_id = yookassa_response.id

    logger.info(f"[Web] Payment created: order={order.id}, amount={final_amount} RUB")
    return {
        "order_id": str(order.id),
        "amount": float(final_amount),
        "currency": "RUB",
        # "confirmation_url": yookassa_response.confirmation.confirmation_url,
    }


@router.post("/webhooks/yookassa")
async def yookassa_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle ЮKassa webhook (idempotent). Updates entitlement on payment.succeeded."""
    body = await request.json()
    event_type = body.get("event", "")
    obj = body.get("object", {})
    payment_id = obj.get("id", "")

    # Idempotency check
    existing_event = db.query(BillingEvent).filter(
        BillingEvent.provider == "yookassa",
        BillingEvent.provider_event_id == payment_id,
    ).first()
    if existing_event:
        return {"status": "already_processed"}

    # Log event
    event = BillingEvent(
        provider="yookassa",
        event_type=event_type,
        provider_event_id=payment_id,
        payload=body,
        processed_at=datetime.now(timezone.utc),
    )
    db.add(event)

    if event_type == "payment.succeeded":
        # Find order by yookassa_payment_id
        order = db.query(WebOrder).filter(WebOrder.yookassa_payment_id == payment_id).first()
        if order:
            order.status = "succeeded"
            order.paid_at = datetime.now(timezone.utc)

            # Create/update entitlement
            now = datetime.now(timezone.utc)
            if order.period == "month":
                expires = now + timedelta(days=30)
            else:
                expires = now + timedelta(days=365)

            # Deactivate old entitlements
            old_ents = db.query(Entitlement).filter(
                Entitlement.billing_account_id == order.billing_account_id,
                Entitlement.is_active == True,
            ).all()
            for oe in old_ents:
                oe.is_active = False

            ent = Entitlement(
                billing_account_id=order.billing_account_id,
                status=order.tier,
                source="web",
                is_active=True,
                started_at=now,
                expires_at=expires,
            )
            db.add(ent)
            logger.info(f"[Webhook] Payment succeeded: {order.tier} for billing_account {order.billing_account_id}")

    elif event_type == "refund.succeeded":
        order = db.query(WebOrder).filter(WebOrder.yookassa_payment_id == payment_id).first()
        if order:
            order.status = "refunded"
            # Deactivate entitlement
            ents = db.query(Entitlement).filter(
                Entitlement.billing_account_id == order.billing_account_id,
                Entitlement.source == "web",
                Entitlement.is_active == True,
            ).all()
            for e in ents:
                e.is_active = False

    db.commit()
    return {"status": "ok"}


@router.get("/subscription/status", response_model=SubscriptionStatusResponse)
def subscription_status(email: str, db: Session = Depends(get_db)):
    """Check web subscription status by email."""
    email_h = _hash(email)
    ba = db.query(BillingAccount).filter(BillingAccount.email_hash == email_h).first()
    if not ba:
        raise HTTPException(status_code=404, detail="Account not found")

    ent = db.query(Entitlement).filter(
        Entitlement.billing_account_id == ba.id,
        Entitlement.is_active == True,
    ).order_by(Entitlement.created_at.desc()).first()

    if not ent:
        return SubscriptionStatusResponse(status="inactive", tier="white", period="none")

    return SubscriptionStatusResponse(
        status="active" if ent.is_active else "inactive",
        tier=ent.status,
        period="month",  # TODO: store period on entitlement
        expires_at=ent.expires_at.isoformat() if ent.expires_at else None,
    )


@router.post("/restore/start")
def restore_start(req: RestoreStartRequest, db: Session = Depends(get_db)):
    """Start web restore flow — send magic code to email."""
    email_h = _hash(req.email)
    ba = db.query(BillingAccount).filter(BillingAccount.email_hash == email_h).first()
    if not ba:
        raise HTTPException(status_code=404, detail="No account found for this email")

    code = f"{secrets.randbelow(1000000):06d}"
    token = MagicLoginToken(
        billing_account_id=ba.id,
        token_hash=_hash(code),
        purpose="restore",
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(token)
    db.commit()
    logger.info(f"[Restore] Code sent to {email_h[:8]}...")
    return {"status": "code_sent", "expires_in_seconds": 600}


@router.post("/restore/confirm")
def restore_confirm(req: RestoreConfirmRequest, db: Session = Depends(get_db)):
    """Confirm restore code and return current entitlement."""
    email_h = _hash(req.email)
    code_h = _hash(req.code)

    ba = db.query(BillingAccount).filter(BillingAccount.email_hash == email_h).first()
    if not ba:
        raise HTTPException(status_code=404, detail="Account not found")

    token = db.query(MagicLoginToken).filter(
        MagicLoginToken.billing_account_id == ba.id,
        MagicLoginToken.token_hash == code_h,
        MagicLoginToken.used_at == None,
        MagicLoginToken.purpose == "restore",
    ).first()

    if not token or token.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=401, detail="Invalid or expired code")

    token.used_at = datetime.now(timezone.utc)
    db.commit()

    ent = db.query(Entitlement).filter(
        Entitlement.billing_account_id == ba.id,
        Entitlement.is_active == True,
    ).order_by(Entitlement.created_at.desc()).first()

    return {
        "status": "restored",
        "entitlement_status": ent.status if ent else "white",
        "expires_at": ent.expires_at.isoformat() if ent and ent.expires_at else None,
    }
