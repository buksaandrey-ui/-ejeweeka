"""
PushDevice ORM model — Push notification device registration.

Stores FCM/APNs tokens and per-user notification preferences.
"""

from sqlalchemy import Column, String, Boolean, DateTime, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from app.db import Base
import uuid


class PushDevice(Base):
    """Push notification device registration."""
    __tablename__ = "push_devices"
    __table_args__ = {"extend_existing": True}

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    anonymous_uuid = Column(String(255), nullable=False, index=True)
    device_token = Column(String(500), nullable=False)
    platform = Column(String(10), default="ios")  # "ios" | "android"
    
    # Notification preferences
    pref_meals = Column(Boolean, default=True)
    pref_water = Column(Boolean, default=True)
    pref_vitamins = Column(Boolean, default=True)
    pref_medications = Column(Boolean, default=True)
    pref_workouts = Column(Boolean, default=True)
    pref_weekly_report = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
