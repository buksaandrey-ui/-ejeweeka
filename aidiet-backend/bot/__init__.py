"""
ejeweeka TG Concierge — Telegram Bot for subscription management.

Architecture:
- User opens Telegram via deep link from iOS app: tg://resolve?domain=healthcode_bot&start=UUID
- Bot links telegram_user_id ↔ anonymous_uuid in Supabase
- User selects Status Black / Status Gold → bot generates ЮKassa payment link
- ЮKassa webhook → bot updates subscription_status in Supabase
- User returns to iOS app → appStateChange → /api/v1/subscription/status → UI unlocks

Environment variables:
- TELEGRAM_BOT_TOKEN — from @BotFather
- YOKASSA_SHOP_ID — ЮKassa shop ID
- YOKASSA_SECRET_KEY — ЮKassa secret key
- DATABASE_URL — Supabase PostgreSQL
- WEBHOOK_BASE_URL — public URL for ЮKassa callbacks (e.g. https://aidiet-api.onrender.com)
"""

import os
import asyncio
import logging

from aiogram import Bot, Dispatcher
from aiogram.enums import ParseMode

from bot.handlers import register_handlers

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(name)s] %(message)s")
logger = logging.getLogger("tg_concierge")

# ============================================================
# CONFIG
# ============================================================

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")

if not TELEGRAM_BOT_TOKEN:
    logger.error("TELEGRAM_BOT_TOKEN not set!")


# ============================================================
# BOT INIT
# ============================================================

bot = Bot(token=TELEGRAM_BOT_TOKEN, default={"parse_mode": ParseMode.HTML})
dp = Dispatcher()

register_handlers(dp)


async def main():
    logger.info("🤖 ejeweeka TG Concierge starting...")
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
