"""
Supabase models for TG Concierge.

Tables used:
- tg_subscriptions: links telegram_user_id ↔ anonymous_uuid, stores subscription status

Schema (create in Supabase SQL Editor):

CREATE TABLE IF NOT EXISTS tg_subscriptions (
    id SERIAL PRIMARY KEY,
    anonymous_uuid VARCHAR(64) UNIQUE NOT NULL,
    telegram_user_id BIGINT,
    tier VARCHAR(20) DEFAULT 'free',     -- free | trial | black | gold
    payment_id VARCHAR(128),             -- last ЮKassa payment ID
    paid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tg_sub_uuid ON tg_subscriptions(anonymous_uuid);
CREATE INDEX idx_tg_sub_tg_id ON tg_subscriptions(telegram_user_id);
"""

import os
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

import asyncpg

logger = logging.getLogger("tg_concierge.models")

DATABASE_URL = os.getenv("DATABASE_URL", "")


async def get_pool():
    """Get or create asyncpg connection pool."""
    if not hasattr(get_pool, "_pool") or get_pool._pool is None:
        get_pool._pool = await asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5)
    return get_pool._pool


async def ensure_table():
    """Create tg_subscriptions table if it doesn't exist."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS tg_subscriptions (
                id SERIAL PRIMARY KEY,
                anonymous_uuid VARCHAR(64) UNIQUE NOT NULL,
                telegram_user_id BIGINT,
                tier VARCHAR(20) DEFAULT 'free',
                payment_id VARCHAR(128),
                paid_until TIMESTAMP,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            )
        """)
        logger.info("✅ tg_subscriptions table ensured")


async def link_user(anonymous_uuid: str, telegram_user_id: int) -> dict:
    """
    Link Telegram user to anonymous UUID.
    Creates record if not exists, updates telegram_user_id if exists.
    """
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM tg_subscriptions WHERE anonymous_uuid = $1",
            anonymous_uuid
        )
        
        if row:
            # Update telegram_user_id
            await conn.execute(
                """UPDATE tg_subscriptions 
                   SET telegram_user_id = $1, updated_at = NOW() 
                   WHERE anonymous_uuid = $2""",
                telegram_user_id, anonymous_uuid
            )
            return dict(row) | {"telegram_user_id": telegram_user_id}
        else:
            # Create new record
            await conn.execute(
                """INSERT INTO tg_subscriptions (anonymous_uuid, telegram_user_id, tier) 
                   VALUES ($1, $2, 'free')""",
                anonymous_uuid, telegram_user_id
            )
            return {
                "anonymous_uuid": anonymous_uuid,
                "telegram_user_id": telegram_user_id,
                "tier": "free",
            }


async def get_subscription_by_uuid(anonymous_uuid: str) -> Optional[dict]:
    """Get subscription record by anonymous UUID."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM tg_subscriptions WHERE anonymous_uuid = $1",
            anonymous_uuid
        )
        return dict(row) if row else None


async def get_subscription_by_tg_id(telegram_user_id: int) -> Optional[dict]:
    """Get subscription record by Telegram user ID."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM tg_subscriptions WHERE telegram_user_id = $1",
            telegram_user_id
        )
        return dict(row) if row else None


async def activate_subscription(anonymous_uuid: str, tier: str, payment_id: str, days: int = 30) -> dict:
    """
    Activate subscription after successful payment.
    Called by ЮKassa webhook handler.
    """
    pool = await get_pool()
    paid_until = datetime.now(timezone.utc) + timedelta(days=days)
    
    async with pool.acquire() as conn:
        await conn.execute(
            """UPDATE tg_subscriptions 
               SET tier = $1, payment_id = $2, paid_until = $3, updated_at = NOW() 
               WHERE anonymous_uuid = $4""",
            tier, payment_id, paid_until, anonymous_uuid
        )
    
    logger.info(f"✅ Subscription activated: {anonymous_uuid} → {tier} until {paid_until}")
    return {"tier": tier, "paid_until": paid_until.isoformat()}


async def deactivate_subscription(anonymous_uuid: str) -> None:
    """Deactivate subscription (expired or cancelled)."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """UPDATE tg_subscriptions 
               SET tier = 'free', paid_until = NULL, updated_at = NOW() 
               WHERE anonymous_uuid = $1""",
            anonymous_uuid
        )
    logger.info(f"⬇️ Subscription deactivated: {anonymous_uuid} → free")
