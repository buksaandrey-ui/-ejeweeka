"""
SQLAlchemy ORM Models for ejeweeka.
Maps to the existing PostgreSQL schema defined in 02_database/schema.sql.

Zero-Knowledge: No PII fields. Only anonymous UUIDs, subscription state, and analytics.
"""

from sqlalchemy import Column, String, Integer, DateTime, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from app.db import Base
import uuid


class User(Base):
    """Anonymous user record — zero-knowledge (no PII stored)."""
    __tablename__ = "users"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    anonymous_uuid = Column(PG_UUID(as_uuid=True), unique=True, nullable=False)
    subscription_status = Column(String(20), default="free")
    subscription_expires_at = Column(DateTime(timezone=True), nullable=True)
    revenuecat_user_id = Column(String(255), nullable=True)
    plan_generation_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_seen_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def to_subscription_dict(self) -> dict:
        """Convert to subscription status response."""
        is_trial = self.subscription_status == "trial"
        return {
            "tier": self.subscription_status or "free",
            "is_trial": is_trial,
            "trial_expires_at": self.subscription_expires_at.isoformat() if is_trial and self.subscription_expires_at else None,
            "subscription_expires_at": self.subscription_expires_at.isoformat() if not is_trial and self.subscription_expires_at else None,
            "can_restore": True,
        }


class PlanGenerationLog(Base):
    """Log of plan generation events (no medical data stored)."""
    __tablename__ = "plan_generation_log"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    anonymous_uuid = Column(PG_UUID(as_uuid=True), nullable=False)
    generated_at = Column(DateTime(timezone=True), server_default=func.now())
    climate_zone = Column(String(20), nullable=True)
    plan_hash = Column(String(64), nullable=True)
