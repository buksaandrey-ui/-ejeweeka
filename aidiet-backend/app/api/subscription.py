"""
Subscription API — handles Web-to-App monetization via YooKassa.

Endpoints:
1. POST /api/v1/subscription/payments/create — Called by Web Landing to create a YooKassa payment link.
2. POST /api/v1/subscription/yokassa-webhook — Called by YooKassa. Generates activation code on success.
3. POST /api/v1/subscription/activate-code — Called by iOS app to activate Premium via code.
"""

from fastapi import APIRouter, Request, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session
import logging
import os
import random
import string
import uuid

from app.db import get_db
from app.models.user import User
from app.models.subscription import Subscription, ActivationCode
from app.api.dependencies import get_current_user

logger = logging.getLogger("subscription")

router = APIRouter()


# ============================================================
# MODELS
# ============================================================

class PaymentCreateRequest(BaseModel):
    tier: str = "gold"
    amount: float = 1.00 # 1 Ruble trial
    anonymous_uuid: str = "anonymous"

class PaymentCreateResponse(BaseModel):
    payment_url: str
    payment_id: str

class ActivateCodeRequest(BaseModel):
    code: str

class ActivateCodeResponse(BaseModel):
    status: str
    tier: str


# ============================================================
# UTILS
# ============================================================

def generate_activation_code() -> str:
    """Generates a 6-character alphanumeric code like 'AX8-92B'"""
    p1 = ''.join(random.choices(string.ascii_uppercase + string.digits, k=3))
    p2 = ''.join(random.choices(string.ascii_uppercase + string.digits, k=3))
    return f"{p1}-{p2}"


# ============================================================
# ENDPOINTS
# ============================================================

@router.post("/payments/create", response_model=PaymentCreateResponse)
async def create_payment(request: PaymentCreateRequest, db: Session = Depends(get_db)):
    """
    Called by Web Landing Page.
    Creates a YooKassa payment and returns the URL.
    """
    # In production, use yookassa SDK. Here we mock for architecture scaffolding.
    # payment = Payment.create({...})
    
    payment_id = str(uuid.uuid4())
    payment_url = f"https://yookassa.ru/checkout/{payment_id}"
    
    
    claimed_user_id = None
    if request.anonymous_uuid and request.anonymous_uuid != "anonymous":
        try:
            claimed_user_id = uuid.UUID(request.anonymous_uuid)
        except ValueError:
            pass

    # Pre-create an ActivationCode record with no code yet, to store the payment_id
    activation_record = ActivationCode(
        code="PENDING_" + payment_id[:4], # Temporary placeholder
        yookassa_payment_id=payment_id,
        tier=request.tier,
        claimed_by_user=claimed_user_id
    )
    db.add(activation_record)
    db.commit()
    
    # In a mock scenario for local testing without real YooKassa, we can instantly trigger the success logic:
    if os.getenv("MOCK_PAYMENT") == "true":
        activation_record.code = generate_activation_code()
        db.commit()
    
    return PaymentCreateResponse(payment_url=payment_url, payment_id=payment_id)


@router.get("/payments/{payment_id}/code")
async def get_payment_code(payment_id: str, db: Session = Depends(get_db)):
    """
    Polled by Web Landing Page after redirect from YooKassa.
    Returns the activation code if payment was successful.
    """
    record = db.query(ActivationCode).filter(ActivationCode.yookassa_payment_id == payment_id).first()
    if not record or record.code.startswith("PENDING_"):
        return {"status": "pending"}
        
    return {"status": "success", "code": record.code}


@router.post("/yokassa-webhook")
async def yokassa_webhook(request: Request, db: Session = Depends(get_db)):
    """
    ЮKassa payment notification webhook.
    On success: generates activation_code.
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    event_type = body.get("event", "")
    payment = body.get("object", {})
    payment_id = payment.get("id", "")

    logger.info(f"💳 ЮKassa webhook: {event_type} | id={payment_id}")

    if event_type == "payment.succeeded" and payment_id:
        record = db.query(ActivationCode).filter(ActivationCode.yookassa_payment_id == payment_id).first()
        if record and record.code.startswith("PENDING_"):
            # Generate real code for Web-to-App funnel
            record.code = generate_activation_code()
            
            # If we know the user, activate directly
            if record.claimed_by_user:
                user = db.query(User).filter(User.anonymous_uuid == record.claimed_by_user).first()
                if user:
                    user.subscription_status = record.tier
                    user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
                    record.is_used = True
                    record.used_at = datetime.now(timezone.utc)
                    logger.info(f"✨ Direct activation for user {user.anonymous_uuid} to {record.tier}")
            
            db.commit()
            logger.info(f"✅ Code generated for payment {payment_id}: {record.code}")
            
    return {"status": "ok"}


@router.post("/activate-code", response_model=ActivateCodeResponse)
async def activate_code(
    request: ActivateCodeRequest, 
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Called by iOS app when user enters code.
    Validates code, activates subscription for the user.
    """
    user = db.query(User).filter(User.anonymous_uuid == uuid.UUID(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    code = request.code.strip().upper()
    
    record = db.query(ActivationCode).filter(
        ActivationCode.code == code,
        ActivationCode.is_used == False
    ).first()
    
    if not record:
        raise HTTPException(status_code=400, detail="Invalid or already used code")
        
    # Mark as used
    record.is_used = True
    record.used_at = datetime.now(timezone.utc)
    record.claimed_by_user = user.anonymous_uuid
    
    # Create or update Subscription for this user
    sub = db.query(Subscription).filter(Subscription.user_id == user.anonymous_uuid).first()
    if not sub:
        sub = Subscription(user_id=user.anonymous_uuid)
        db.add(sub)
        
    sub.status = "trial"
    sub.current_period_end = datetime.now(timezone.utc) + timedelta(days=3)
    
    user.subscription_status = record.tier
    user.subscription_expires_at = sub.current_period_end
    
    db.commit()
    
    return ActivateCodeResponse(status="success", tier=record.tier)

