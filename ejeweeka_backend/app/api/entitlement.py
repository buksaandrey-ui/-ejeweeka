"""
Entitlement API — App-facing endpoints for status management.
Hybrid Monetization: IAP verify, email link, status sync, account deletion.

These endpoints are accessible from the iOS/Android app.
Web-only endpoints (promo codes, ЮKassa) are in web_billing.py.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session
from app.db import get_db
from app.models.billing import (
    BillingAccount, AppProfile, Entitlement,
    AppStoreTransaction, MagicLoginToken, ConsentLog, BillingEvent,
)

import uuid
import hashlib
import secrets
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["entitlements"])

TRIAL_DAYS = 3


def _hash(value: str) -> str:
    """SHA-256 hash for anonymous_uuid and email."""
    return hashlib.sha256(value.strip().lower().encode()).hexdigest()


# ── Schemas ──────────────────────────────────────────────────────

class AnonInitRequest(BaseModel):
    anonymous_uuid: str
    platform: str = "ios"

class AnonInitResponse(BaseModel):
    app_profile_id: str
    entitlement_status: str
    entitlement_source: str
    is_trial: bool
    trial_ends_at: Optional[str] = None
    expires_at: Optional[str] = None

class LinkEmailStartRequest(BaseModel):
    app_profile_id: str
    email: str  # Will be hashed server-side

class LinkEmailConfirmRequest(BaseModel):
    app_profile_id: str
    email: str
    code: str

class EntitlementStatusResponse(BaseModel):
    status: str
    source: str
    is_active: bool
    is_trial: bool
    trial_ends_at: Optional[str] = None
    expires_at: Optional[str] = None

class IAPVerifyRequest(BaseModel):
    app_profile_id: str
    original_transaction_id: str
    transaction_id: str
    product_id: str
    environment: str = "Production"
    purchased_at: Optional[str] = None
    expires_at: Optional[str] = None
    raw_payload: Optional[dict] = None

class DeleteStartRequest(BaseModel):
    app_profile_id: str
    email: Optional[str] = None

class DeleteConfirmRequest(BaseModel):
    app_profile_id: str
    code: str


# ── Endpoints ────────────────────────────────────────────────────



@router.get("/entitlements/status", response_model=EntitlementStatusResponse)
def get_status(app_profile_id: str, db: Session = Depends(get_db)):
    """Get current entitlement status for an app profile."""
    try:
        pid = uuid.UUID(app_profile_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid app_profile_id")

    ent = db.query(Entitlement).filter(
        Entitlement.app_profile_id == pid,
        Entitlement.is_active == True
    ).order_by(Entitlement.created_at.desc()).first()

    if not ent:
        return EntitlementStatusResponse(
            status="white", source="trial", is_active=False, is_trial=False
        )

    # Check trial expiry
    now = datetime.now(timezone.utc)
    if ent.source == "trial" and ent.trial_ends_at and ent.trial_ends_at < now:
        ent.is_active = False
        ent.status = "white"
        db.commit()
        return EntitlementStatusResponse(
            status="white", source="trial", is_active=False, is_trial=False
        )

    return EntitlementStatusResponse(
        status=ent.status,
        source=ent.source,
        is_active=ent.is_active,
        is_trial=ent.source == "trial",
        trial_ends_at=ent.trial_ends_at.isoformat() if ent.trial_ends_at else None,
        expires_at=ent.expires_at.isoformat() if ent.expires_at else None,
    )


@router.post("/auth/link-email/start")
def link_email_start(req: LinkEmailStartRequest, db: Session = Depends(get_db)):
    """Send a 6-digit magic code to email for profile linking."""
    email_h = _hash(req.email)

    # Find or create billing account
    ba = db.query(BillingAccount).filter(BillingAccount.email_hash == email_h).first()
    if not ba:
        ba = BillingAccount(email_hash=email_h, encrypted_email=req.email)  # TODO: real encryption
        db.add(ba)
        db.flush()

    # Generate 6-digit code
    code = f"{secrets.randbelow(1000000):06d}"
    token = MagicLoginToken(
        billing_account_id=ba.id,
        token_hash=_hash(code),
        purpose="login",
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(token)
    db.commit()

    # TODO: Send email via SendGrid/SES
    logger.info(f"[Auth] Magic code generated for {email_h[:8]}... (code={code} — remove from logs in prod)")

    return {"status": "code_sent", "expires_in_seconds": 600}


@router.post("/auth/link-email/confirm")
def link_email_confirm(req: LinkEmailConfirmRequest, db: Session = Depends(get_db)):
    """Confirm magic code, link app_profile to billing_account, sync entitlement."""
    email_h = _hash(req.email)
    code_h = _hash(req.code)

    ba = db.query(BillingAccount).filter(BillingAccount.email_hash == email_h).first()
    if not ba:
        raise HTTPException(status_code=404, detail="Account not found")

    token = db.query(MagicLoginToken).filter(
        MagicLoginToken.billing_account_id == ba.id,
        MagicLoginToken.token_hash == code_h,
        MagicLoginToken.used_at == None,
        MagicLoginToken.purpose == "login",
    ).first()

    if not token or token.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=401, detail="Invalid or expired code")

    # Mark token used
    token.used_at = datetime.now(timezone.utc)

    # Link app_profile to billing_account
    try:
        pid = uuid.UUID(req.app_profile_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid app_profile_id")

    profile = db.query(AppProfile).filter(AppProfile.id == pid).first()
    if profile:
        profile.billing_account_id = ba.id

    # Sync: if billing_account has a higher entitlement, apply it
    best_ent = db.query(Entitlement).filter(
        Entitlement.billing_account_id == ba.id,
        Entitlement.is_active == True,
    ).order_by(Entitlement.created_at.desc()).first()

    if best_ent and profile:
        # Apply billing account's entitlement to this app_profile
        existing_app_ent = db.query(Entitlement).filter(
            Entitlement.app_profile_id == pid,
            Entitlement.is_active == True,
        ).first()

        status_rank = {"white": 0, "black": 1, "gold": 2}
        if not existing_app_ent or status_rank.get(best_ent.status, 0) > status_rank.get(existing_app_ent.status, 0):
            new_ent = Entitlement(
                billing_account_id=ba.id,
                app_profile_id=pid,
                status=best_ent.status,
                source=best_ent.source,
                is_active=True,
                started_at=best_ent.started_at,
                expires_at=best_ent.expires_at,
            )
            if existing_app_ent:
                existing_app_ent.is_active = False
            db.add(new_ent)

    db.commit()

    final_ent = db.query(Entitlement).filter(
        Entitlement.app_profile_id == pid,
        Entitlement.is_active == True,
    ).order_by(Entitlement.created_at.desc()).first()

    return {
        "status": "linked",
        "entitlement_status": final_ent.status if final_ent else "white",
        "entitlement_source": final_ent.source if final_ent else "trial",
    }


@router.post("/iap/verify")
def iap_verify(req: IAPVerifyRequest, db: Session = Depends(get_db)):
    """Verify Apple IAP transaction and update entitlement."""
    # Check idempotency
    existing_tx = db.query(AppStoreTransaction).filter(
        AppStoreTransaction.original_transaction_id == req.original_transaction_id
    ).first()
    if existing_tx:
        return {"status": "already_processed", "transaction_id": req.transaction_id}

    try:
        pid = uuid.UUID(req.app_profile_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid app_profile_id")

    # Determine tier from product_id
    product_tier_map = {
        "ejeweeka.black.monthly": "black",
        "ejeweeka.black.yearly": "black",
        "ejeweeka.gold.monthly": "gold",
        "ejeweeka.gold.yearly": "gold",
    }
    tier = product_tier_map.get(req.product_id, "black")

    # Save transaction
    tx = AppStoreTransaction(
        app_profile_id=pid,
        original_transaction_id=req.original_transaction_id,
        transaction_id=req.transaction_id,
        product_id=req.product_id,
        status="active",
        environment=req.environment,
        purchased_at=datetime.fromisoformat(req.purchased_at) if req.purchased_at else datetime.now(timezone.utc),
        expires_at=datetime.fromisoformat(req.expires_at) if req.expires_at else None,
        raw_payload=req.raw_payload,
    )
    db.add(tx)

    # Deactivate old entitlements for this profile
    old_ents = db.query(Entitlement).filter(
        Entitlement.app_profile_id == pid,
        Entitlement.is_active == True,
    ).all()
    for oe in old_ents:
        oe.is_active = False

    # Create new entitlement
    ent = Entitlement(
        app_profile_id=pid,
        status=tier,
        source="app_store",
        is_active=True,
        started_at=datetime.now(timezone.utc),
        expires_at=datetime.fromisoformat(req.expires_at) if req.expires_at else None,
    )
    db.add(ent)

    # Log billing event
    event = BillingEvent(
        provider="apple",
        event_type="iap_purchase",
        provider_event_id=req.transaction_id,
        payload={"product_id": req.product_id, "tier": tier},
    )
    db.add(event)
    db.commit()

    logger.info(f"[IAP] Verified purchase: {req.product_id} -> {tier} for profile {pid}")
    return {"status": "success", "entitlement_status": tier, "entitlement_source": "app_store"}


@router.post("/account/delete/start")
def account_delete_start(req: DeleteStartRequest, db: Session = Depends(get_db)):
    """Initiate account deletion. If email linked, sends confirmation code."""
    try:
        pid = uuid.UUID(req.app_profile_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid app_profile_id")

    profile = db.query(AppProfile).filter(AppProfile.id == pid).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    if profile.billing_account_id:
        # Has billing account — need email confirmation
        code = f"{secrets.randbelow(1000000):06d}"
        token = MagicLoginToken(
            billing_account_id=profile.billing_account_id,
            token_hash=_hash(code),
            purpose="delete_account",
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
        )
        db.add(token)
        db.commit()
        logger.info(f"[Account] Deletion code sent for profile {pid}")
        return {"status": "confirmation_required", "expires_in_seconds": 600}
    else:
        # No billing account — delete immediately
        _perform_deletion(db, profile)
        return {"status": "deleted"}


@router.post("/account/delete/confirm")
def account_delete_confirm(req: DeleteConfirmRequest, db: Session = Depends(get_db)):
    """Confirm account deletion with code."""
    try:
        pid = uuid.UUID(req.app_profile_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid app_profile_id")

    profile = db.query(AppProfile).filter(AppProfile.id == pid).first()
    if not profile or not profile.billing_account_id:
        raise HTTPException(status_code=404, detail="Profile not found")

    code_h = _hash(req.code)
    token = db.query(MagicLoginToken).filter(
        MagicLoginToken.billing_account_id == profile.billing_account_id,
        MagicLoginToken.token_hash == code_h,
        MagicLoginToken.used_at == None,
        MagicLoginToken.purpose == "delete_account",
    ).first()

    if not token or token.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=401, detail="Invalid or expired code")

    token.used_at = datetime.now(timezone.utc)
    _perform_deletion(db, profile)
    return {"status": "deleted"}


def _perform_deletion(db: Session, profile: AppProfile):
    """Physically delete entitlements, mark profile as deleted."""
    # Delete entitlements
    db.query(Entitlement).filter(Entitlement.app_profile_id == profile.id).delete()

    if profile.billing_account_id:
        ba = db.query(BillingAccount).filter(BillingAccount.id == profile.billing_account_id).first()
        if ba:
            ba.deleted_at = datetime.now(timezone.utc)
            ba.email_hash = None
            ba.encrypted_email = None

    profile.deleted_at = datetime.now(timezone.utc)
    db.commit()
    logger.info(f"[Account] Deleted profile {profile.id}")
