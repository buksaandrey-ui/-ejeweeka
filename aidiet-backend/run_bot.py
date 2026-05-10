#!/usr/bin/env python3
"""
Run ejeweeka TG Concierge bot.

Usage:
    python run_bot.py

Required environment variables:
    TELEGRAM_BOT_TOKEN — from @BotFather
    DATABASE_URL — Supabase PostgreSQL connection string
    YOKASSA_SHOP_ID — ЮKassa shop ID (optional for dev)
    YOKASSA_SECRET_KEY — ЮKassa secret key (optional for dev)
"""

import asyncio
import os
import sys

# Add parent to path so bot module is importable
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv
load_dotenv()

from bot import main

if __name__ == "__main__":
    print("🤖 Starting ejeweeka TG Concierge...")
    print(f"   Bot token: {'✅ set' if os.getenv('TELEGRAM_BOT_TOKEN') else '❌ missing'}")
    print(f"   Database:  {'✅ set' if os.getenv('DATABASE_URL') else '❌ missing'}")
    print(f"   ЮKassa:    {'✅ set' if os.getenv('YOKASSA_SHOP_ID') else '⚠️ missing (dev mode)'}")
    
    asyncio.run(main())
