"""
Push Notification API — device token registration & preferences.

Production Implementation:
- Stores FCM/APNs tokens in PostgreSQL (survives server restarts)
- Manages per-user notification preferences
- Ready for Firebase Cloud Messaging integration

Zero-Knowledge: Only device tokens and preferences stored, no PII.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

from sqlalchemy.orm import Session

from app.db import get_db
from app.api.dependencies import get_current_user
from app.models.push_device import PushDevice

import logging

logger = logging.getLogger(__name__)

router = APIRouter()



# ============================================================
# REQUEST/RESPONSE MODELS
# ============================================================

class PushRegisterRequest(BaseModel):
    """Register a device for push notifications."""
    device_token: str  # FCM token (Android) or APNs device token (iOS)
    platform: str = "ios"  # "ios" | "android"


class PushSettingsRequest(BaseModel):
    """Update notification preferences."""
    meals: bool = True
    water: bool = True
    vitamins: bool = True
    medications: bool = True
    workouts: bool = True
    weekly_report: bool = True


# ============================================================
# ENDPOINTS
# ============================================================

@router.post("/register")
def register_push_token(
    request: PushRegisterRequest,
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Register device for push notifications.
    Called on app launch after permissions are granted.
    
    Upserts: if token already exists for this user, updates it.
    """
    # Check if user already has a device registered
    existing = db.query(PushDevice).filter(
        PushDevice.anonymous_uuid == user_id
    ).first()
    
    if existing:
        existing.device_token = request.device_token
        existing.platform = request.platform
        db.commit()
        logger.info(f"📱 Push token updated for {user_id} ({request.platform})")
    else:
        device = PushDevice(
            anonymous_uuid=user_id,
            device_token=request.device_token,
            platform=request.platform,
        )
        db.add(device)
        db.commit()
        logger.info(f"📱 Push token registered for {user_id} ({request.platform})")
    
    return {"status": "ok", "message": "Push notifications enabled"}


@router.put("/settings")
def update_push_settings(
    request: PushSettingsRequest,
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update notification preferences.
    Persisted in PostgreSQL — survives server restarts.
    """
    device = db.query(PushDevice).filter(
        PushDevice.anonymous_uuid == user_id
    ).first()
    
    if not device:
        raise HTTPException(
            status_code=404,
            detail="Device not registered for push. Call POST /register first."
        )
    
    device.pref_meals = request.meals
    device.pref_water = request.water
    device.pref_vitamins = request.vitamins
    device.pref_medications = request.medications
    device.pref_workouts = request.workouts
    device.pref_weekly_report = request.weekly_report
    
    db.commit()
    
    return {
        "status": "ok",
        "settings": {
            "meals": device.pref_meals,
            "water": device.pref_water,
            "vitamins": device.pref_vitamins,
            "medications": device.pref_medications,
            "workouts": device.pref_workouts,
            "weekly_report": device.pref_weekly_report,
        }
    }


@router.get("/settings")
def get_push_settings(
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get current notification preferences."""
    device = db.query(PushDevice).filter(
        PushDevice.anonymous_uuid == user_id
    ).first()
    
    if not device:
        # Return defaults if not registered
        return {
            "registered": False,
            "settings": {
                "meals": True,
                "water": True,
                "vitamins": True,
                "medications": True,
                "workouts": True,
                "weekly_report": True,
            }
        }
    
    return {
        "registered": True,
        "platform": device.platform,
        "settings": {
            "meals": device.pref_meals,
            "water": device.pref_water,
            "vitamins": device.pref_vitamins,
            "medications": device.pref_medications,
            "workouts": device.pref_workouts,
            "weekly_report": device.pref_weekly_report,
        }
    }
