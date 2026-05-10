"""
Auth dependencies for FastAPI endpoints.
Extracts and validates the JWT token from the Authorization header.

Provides:
- get_current_user: extracts anonymous_uuid from Bearer token
- require_tier: factory for tier-checking dependencies
"""

from fastapi import Header, HTTPException, Depends
from typing import Optional, List
from sqlalchemy.orm import Session

import hmac
import hashlib
import json
import time
import os

from app.db import get_db
from app.models import User
import uuid

JWT_SECRET = os.getenv("JWT_SECRET", "aidiet-mvp-secret-change-in-production")
STRICT_AUTH = os.getenv("STRICT_AUTH", "false").lower() == "true"


def _verify_token(token: str) -> Optional[str]:
    """Verifies HMAC token, returns anonymous_uuid or None."""
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


async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """
    FastAPI dependency — extracts anonymous_uuid from Bearer token.
    
    Usage:
        @router.post("/endpoint")
        def my_endpoint(user_id: str = Depends(get_current_user)):
            ...
    
    Auth mode controlled by STRICT_AUTH env variable:
    - STRICT_AUTH=false (default): allow unauthenticated requests (dev/testing)
    - STRICT_AUTH=true (production): reject unauthenticated requests with 401
    """
    if not authorization:
        if STRICT_AUTH:
            raise HTTPException(
                status_code=401,
                detail="Authorization header required. Call POST /api/v1/auth/init to get a token."
            )
        return "anonymous"

    # Extract token from "Bearer <token>"
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=401,
            detail="Invalid Authorization header. Expected: Bearer <token>"
        )

    user_id = _verify_token(token)
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Token expired or invalid. Call POST /api/v1/auth/init to get a new token."
        )

    return user_id


def require_tier(*allowed_tiers: str):
    """
    Factory for tier-checking dependency.
    
    Usage:
        @router.post("/premium-feature")
        def premium_endpoint(
            user_id: str = Depends(get_current_user),
            _tier: str = Depends(require_tier("black", "gold", "group_gold")),
        ):
            ...
    
    Returns the user's current tier if it's in the allowed list.
    Raises 403 if the user's tier is not sufficient.
    """
    async def _check_tier(
        user_id: str = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> str:
        # In dev mode, skip tier checking
        if not STRICT_AUTH and user_id == "anonymous":
            return "gold"  # Default to gold in dev mode
        
        try:
            anon_uuid = uuid.UUID(user_id)
            user = db.query(User).filter(User.anonymous_uuid == anon_uuid).first()
            if user and user.subscription_status in allowed_tiers:
                return user.subscription_status
        except (ValueError, AttributeError):
            pass

        raise HTTPException(
            status_code=403,
            detail=f"This feature requires one of: {', '.join(allowed_tiers)}. "
                   f"Upgrade your subscription to access this feature."
        )
    
    return _check_tier
