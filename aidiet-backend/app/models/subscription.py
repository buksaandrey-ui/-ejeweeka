"""
Subscription ORM Models for ejeweeka.
Manages Web-to-App activations and YooKassa payment methods.
"""

from sqlalchemy import Column, String, Integer, DateTime, func, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from app.db import Base
import uuid


class ActivationCode(Base):
    """Standalone activation codes generated on the web before app install."""
    __tablename__ = "activation_codes"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String(10), unique=True, index=True, nullable=False)
    tier = Column(String(20), default="gold")  # free, trial, gold
    is_used = Column(Boolean, default=False)
    
    # YooKassa Data (to tie the code to a payment)
    yookassa_payment_id = Column(String(128), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    used_at = Column(DateTime(timezone=True), nullable=True)
    
    # Once activated, store the user who claimed it
    claimed_by_user = Column(PG_UUID(as_uuid=True), ForeignKey("users.anonymous_uuid"), nullable=True)


class Subscription(Base):
    """Stores active subscriptions and YooKassa payment methods for users."""
    __tablename__ = "subscriptions"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(PG_UUID(as_uuid=True), ForeignKey("users.anonymous_uuid"), nullable=False, unique=True)
    
    # YooKassa billing data
    yookassa_payment_method_id = Column(String(128), nullable=True) # Token for recurring payments
    
    # Status
    status = Column(String(20), default="inactive") # inactive, trial, active, past_due, canceled
    current_period_end = Column(DateTime(timezone=True), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationship to user
    user = relationship("User", backref="subscription", foreign_keys=[user_id])
