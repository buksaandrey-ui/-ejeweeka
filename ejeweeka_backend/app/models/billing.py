"""
Billing & Entitlement ORM Models for ejeweeka.
Hybrid Monetization: IAP (iOS) + ЮKassa (Web RU) + Unified Entitlement.
Zero-knowledge: NO health data stored. Only billing/account/entitlement.
"""

from sqlalchemy import (
    Column, String, Integer, DateTime, Boolean, Numeric,
    ForeignKey, Text, UniqueConstraint, CheckConstraint, func
)
from sqlalchemy.dialects.postgresql import UUID as PG_UUID, JSONB
from sqlalchemy.orm import relationship
from app.db import Base
import uuid


class BillingAccount(Base):
    """Minimal billing account. Created when user links email or pays on web."""
    __tablename__ = "billing_accounts"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email_hash = Column(Text, unique=True, nullable=True, index=True)
    encrypted_email = Column(Text, nullable=True)
    country_code = Column(String(10), nullable=True)
    locale = Column(String(10), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    deletion_requested_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    app_profiles = relationship("AppProfile", back_populates="billing_account")
    entitlements = relationship("Entitlement", back_populates="billing_account")


class AppProfile(Base):
    """One per app installation. Links anonymous device to optional billing account."""
    __tablename__ = "app_profiles"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    anonymous_uuid_hash = Column(Text, unique=True, nullable=False, index=True)
    platform = Column(String(10), nullable=False)  # ios, android, web
    app_instance_id = Column(Text, nullable=True)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint("platform IN ('ios', 'android', 'web')", name="ck_app_profiles_platform"),
    )

    billing_account = relationship("BillingAccount", back_populates="app_profiles")
    entitlements = relationship("Entitlement", back_populates="app_profile")


class Entitlement(Base):
    """Unified source of truth for user status (white/black/gold)."""
    __tablename__ = "entitlements"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=True)
    app_profile_id = Column(PG_UUID(as_uuid=True), ForeignKey("app_profiles.id"), nullable=True)
    status = Column(String(10), nullable=False, default="white")
    source = Column(String(20), nullable=False)
    is_active = Column(Boolean, default=True)
    started_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)
    trial_started_at = Column(DateTime(timezone=True), nullable=True)
    trial_ends_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        CheckConstraint("status IN ('white', 'black', 'gold')", name="ck_entitlements_status"),
        CheckConstraint(
            "source IN ('trial', 'app_store', 'web', 'reviewer_demo', 'manual_support')",
            name="ck_entitlements_source"
        ),
    )

    billing_account = relationship("BillingAccount", back_populates="entitlements")
    app_profile = relationship("AppProfile", back_populates="entitlements")


class AppStoreTransaction(Base):
    """Apple IAP transaction records."""
    __tablename__ = "app_store_transactions"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    app_profile_id = Column(PG_UUID(as_uuid=True), ForeignKey("app_profiles.id"), nullable=False)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=True)
    original_transaction_id = Column(Text, unique=True, nullable=False)
    transaction_id = Column(Text, unique=True, nullable=False)
    product_id = Column(Text, nullable=False)
    status = Column(Text, nullable=False)
    environment = Column(String(20), nullable=False)
    purchased_at = Column(DateTime(timezone=True), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    raw_payload = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("environment IN ('Sandbox', 'Production')", name="ck_ast_environment"),
    )


class WebOrder(Base):
    """ЮKassa single payment records (web only)."""
    __tablename__ = "web_orders"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=False)
    yookassa_payment_id = Column(Text, unique=True, nullable=True)
    status = Column(String(20), nullable=False, default="pending")
    tier = Column(String(10), nullable=False)
    period = Column(String(10), nullable=False)
    amount_original = Column(Numeric(10, 2))
    discount_amount = Column(Numeric(10, 2), default=0)
    amount_final = Column(Numeric(10, 2))
    currency = Column(String(5), default="RUB")
    promo_code_id = Column(PG_UUID(as_uuid=True), nullable=True)
    yookassa_metadata = Column(JSONB, default={})
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    paid_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint("status IN ('pending', 'succeeded', 'canceled', 'refunded')", name="ck_wo_status"),
        CheckConstraint("tier IN ('black', 'gold')", name="ck_wo_tier"),
        CheckConstraint("period IN ('month', 'year')", name="ck_wo_period"),
    )


class WebSubscription(Base):
    """ЮKassa recurring subscription tracking (web only)."""
    __tablename__ = "web_subscriptions"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=False)
    tier = Column(String(10), nullable=False)
    period = Column(String(10), nullable=False)
    status = Column(String(20), nullable=False, default="active")
    yookassa_payment_method_id = Column(Text, nullable=True)
    next_charge_at = Column(DateTime(timezone=True), nullable=True)
    started_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)
    canceled_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        CheckConstraint("status IN ('active', 'canceled', 'past_due', 'expired')", name="ck_ws_status"),
        CheckConstraint("tier IN ('black', 'gold')", name="ck_ws_tier"),
        CheckConstraint("period IN ('month', 'year')", name="ck_ws_period"),
    )


class PromoCode(Base):
    """Web-only promotional discount codes. NOT accessible from app API."""
    __tablename__ = "promo_codes"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code_hash = Column(Text, unique=True, nullable=False, index=True)
    code_prefix = Column(Text, nullable=False)
    discount_type = Column(String(10), nullable=False)
    discount_value = Column(Numeric(10, 2), nullable=False)
    applies_to_tiers = Column(JSONB, default=[])
    starts_at = Column(DateTime(timezone=True), nullable=True)
    ends_at = Column(DateTime(timezone=True), nullable=True)
    usage_limit = Column(Integer, nullable=True)
    used_count = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("discount_type IN ('percent', 'fixed')", name="ck_pc_discount_type"),
    )


class MagicLoginToken(Base):
    """One-time email verification codes for login/restore/delete."""
    __tablename__ = "magic_login_tokens"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=False)
    token_hash = Column(Text, unique=True, nullable=False)
    purpose = Column(String(20), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("purpose IN ('login', 'restore', 'delete_account')", name="ck_mlt_purpose"),
    )


class ConsentLog(Base):
    """GDPR / 152-ФЗ consent audit trail."""
    __tablename__ = "consent_logs"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    billing_account_id = Column(PG_UUID(as_uuid=True), ForeignKey("billing_accounts.id"), nullable=True)
    app_profile_id = Column(PG_UUID(as_uuid=True), ForeignKey("app_profiles.id"), nullable=True)
    consent_type = Column(String(30), nullable=False)
    document_version = Column(Text, nullable=False)
    accepted_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    source = Column(String(10), nullable=False)
    ip_hash = Column(Text, nullable=True)
    user_agent_hash = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint(
            "consent_type IN ('terms', 'privacy', 'pd_processing', 'cookies', 'marketing', 'subscription_terms')",
            name="ck_cl_consent_type"
        ),
        CheckConstraint("source IN ('web', 'ios', 'android')", name="ck_cl_source"),
    )


class BillingEvent(Base):
    """Idempotent webhook/event audit log."""
    __tablename__ = "billing_events"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    provider = Column(String(20), nullable=False)
    event_type = Column(Text, nullable=False)
    provider_event_id = Column(Text, nullable=True)
    payload = Column(JSONB, nullable=False)
    processed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("provider IN ('apple', 'yookassa', 'internal')", name="ck_be_provider"),
        UniqueConstraint("provider", "provider_event_id", name="uq_be_provider_event"),
    )
