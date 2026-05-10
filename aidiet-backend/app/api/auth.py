"""
Auth API — anonymous authentication lifecycle.
Creates anonymous sessions, issues HMAC tokens, verifies tokens.

Zero-Knowledge: Server stores only anonymous_uuid + tier. No PII.
Production TODO: Replace HMAC with PyJWT RS256 for proper key rotation.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone

from sqlalchemy.orm import Session
from app.db import get_db
from app.models import User

import uuid
import hashlib
import hmac
import time
import json
import os
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# JWT-like token (без зависимости от PyJWT для MVP)
# В продакшне заменить на PyJWT с RS256
JWT_SECRET = os.getenv("JWT_SECRET", "aidiet-mvp-secret-change-in-production")


def _create_token(anonymous_uuid: str) -> str:
    """Создаёт простой HMAC-токен для MVP. В продакшне — PyJWT."""
    payload = {
        "sub": anonymous_uuid,
        "iat": int(time.time()),
        "exp": int(time.time()) + 30 * 24 * 3600  # 30 дней
    }
    payload_b64 = json.dumps(payload, separators=(',', ':'))
    signature = hmac.new(
        JWT_SECRET.encode(), payload_b64.encode(), hashlib.sha256
    ).hexdigest()[:32]
    return f"{payload_b64}.{signature}"


def _verify_token(token: str) -> Optional[str]:
    """Проверяет токен, возвращает anonymous_uuid или None."""
    try:
        parts = token.rsplit('.', 1)
        if len(parts) != 2:
            return None
        payload_str, signature = parts
        expected_sig = hmac.new(
            JWT_SECRET.encode(), payload_str.encode(), hashlib.sha256
        ).hexdigest()[:32]
        if not hmac.compare_digest(signature, expected_sig):
            return None
        payload = json.loads(payload_str)
        if payload.get("exp", 0) < time.time():
            return None
        return payload.get("sub")
    except Exception:
        return None


class InitResponse(BaseModel):
    anonymous_uuid: str
    token: str
    expires_in: int = 30 * 24 * 3600  # 30 дней в секундах


class TokenVerifyRequest(BaseModel):
    token: str


@router.post("/init", response_model=InitResponse)
def anonymous_init(db: Session = Depends(get_db)):
    """
    Создаёт анонимный UUID, сохраняет в PostgreSQL, и возвращает токен.
    Zero-Knowledge: сервер хранит ТОЛЬКО anonymous_uuid + tier.
    Токен используется для rate-limiting и идентификации тарифа.
    """
    anon_uuid = uuid.uuid4()
    token = _create_token(str(anon_uuid))

    # Persist user in PostgreSQL
    user = User(
        anonymous_uuid=anon_uuid,
        subscription_status="free",
    )
    db.add(user)
    try:
        db.commit()
        logger.info(f"[Auth] Created new anonymous user: {anon_uuid}")
    except Exception as e:
        db.rollback()
        logger.warning(f"[Auth] Failed to persist user (may be duplicate): {e}")
        # If somehow this UUID already exists, just continue
        pass

    return InitResponse(
        anonymous_uuid=str(anon_uuid),
        token=token
    )


@router.post("/verify")
def verify_token(request: TokenVerifyRequest, db: Session = Depends(get_db)):
    """Проверяет валидность токена и обновляет last_seen_at."""
    user_id = _verify_token(request.token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Token expired or invalid")

    # Update last_seen_at in DB
    try:
        anon_uuid = uuid.UUID(user_id)
        user = db.query(User).filter(User.anonymous_uuid == anon_uuid).first()
        if user:
            user.last_seen_at = datetime.now(timezone.utc)
            db.commit()
    except Exception:
        pass  # Non-critical — don't fail verification on DB issues

    return {"valid": True, "anonymous_uuid": user_id}
