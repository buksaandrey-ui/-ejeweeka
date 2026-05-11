"""
Telegram bot handlers for ejeweeka TG Concierge.

Commands:
- /start UUID — link Telegram account to app UUID, show status menu
- /status — show current subscription status
- /help — show help message

Inline keyboards:
- Status selection (Black / Gold)
- Payment confirmation
"""

import logging
from aiogram import Dispatcher, types, F
from aiogram.filters import Command, CommandStart
from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup

from bot.models import link_user, get_subscription_by_tg_id, ensure_table
from bot.yokassa import create_payment

logger = logging.getLogger("tg_concierge.handlers")


# ============================================================
# KEYBOARDS
# ============================================================

def get_status_keyboard() -> InlineKeyboardMarkup:
    """Main status selection keyboard."""
    return InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="⚡ Status Black — 490 ₽/мес", callback_data="buy:black"),
        ],
        [
            InlineKeyboardButton(text="👑 Status Gold — 990 ₽/мес", callback_data="buy:gold"),
        ],
        [
            InlineKeyboardButton(text="📊 Мой статус", callback_data="my_status"),
        ],
    ])


def get_back_keyboard() -> InlineKeyboardMarkup:
    """Back to main menu keyboard."""
    return InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text="← Назад", callback_data="main_menu")],
    ])


# ============================================================
# HANDLERS
# ============================================================

def register_handlers(dp: Dispatcher):
    """Register all bot handlers."""

    @dp.message(CommandStart(deep_link=True))
    async def cmd_start_deep_link(message: types.Message):
        """Handle /start UUID — deep link from iOS app."""
        await ensure_table()

        # Extract UUID from deep link
        args = message.text.split(maxsplit=1)
        uuid_param = args[1] if len(args) > 1 else ""

        if not uuid_param or uuid_param == "unknown":
            await message.answer(
                "❌ <b>Ошибка привязки</b>\n\n"
                "Не удалось определить профиль. Пожалуйста, откройте ссылку "
                "из приложения ejeweeka заново.",
            )
            return

        # Link TG user to app UUID
        user_data = await link_user(uuid_param, message.from_user.id)
        tier = user_data.get("tier", "free")

        tier_emoji = {"free": "🆓", "trial": "⏳", "black": "⚡", "gold": "👑"}
        tier_name = {"free": "Free", "trial": "Gold (Trial)", "black": "Black", "gold": "Gold"}

        await message.answer(
            f"👋 <b>Привет!</b>\n\n"
            f"Профиль ejeweeka синхронизирован.\n"
            f"Текущий статус: {tier_emoji.get(tier, '❓')} <b>{tier_name.get(tier, tier)}</b>\n\n"
            f"Выбери статус для продолжения работы алгоритма:",
            reply_markup=get_status_keyboard(),
        )

    @dp.message(CommandStart())
    async def cmd_start_no_link(message: types.Message):
        """Handle /start without deep link."""
        await ensure_table()

        # Check if user already linked
        sub = await get_subscription_by_tg_id(message.from_user.id)

        if sub:
            tier = sub.get("tier", "free")
            tier_name = {"free": "Free", "trial": "Gold (Trial)", "black": "Black", "gold": "Gold"}
            await message.answer(
                f"👋 <b>С возвращением!</b>\n\n"
                f"Твой статус: <b>{tier_name.get(tier, tier)}</b>\n\n"
                f"Выбери действие:",
                reply_markup=get_status_keyboard(),
            )
        else:
            await message.answer(
                "👋 <b>Привет!</b>\n\n"
                "Я — ассистент ejeweeka.\n\n"
                "Чтобы связать аккаунт, открой приложение ejeweeka → "
                "нажми «Открыть Telegram» на экране статуса.\n\n"
                "Это создаст защищённую связь между приложением и ботом.",
            )

    @dp.message(Command("status"))
    async def cmd_status(message: types.Message):
        """Show current subscription status."""
        sub = await get_subscription_by_tg_id(message.from_user.id)

        if not sub:
            await message.answer(
                "❌ Профиль не привязан. Откройте ссылку из приложения ejeweeka.",
            )
            return

        tier = sub.get("tier", "free")
        paid_until = sub.get("paid_until")
        tier_name = {"free": "Free", "trial": "Gold (Trial)", "black": "Black", "gold": "Gold"}

        text = f"📊 <b>Твой статус</b>\n\n"
        text += f"Статус: <b>{tier_name.get(tier, tier)}</b>\n"

        if paid_until:
            text += f"Активен до: <b>{paid_until.strftime('%d.%m.%Y')}</b>\n"

        if tier == "free":
            text += "\n💡 Разблокируй полный доступ к алгоритму!"

        await message.answer(text, reply_markup=get_status_keyboard())

    @dp.message(Command("help"))
    async def cmd_help(message: types.Message):
        """Show help."""
        await message.answer(
            "🤖 <b>ejeweeka Ассистент</b>\n\n"
            "Команды:\n"
            "/start — привязать профиль\n"
            "/status — текущий статус\n"
            "/help — эта справка\n\n"
            "Управление статусом:\n"
            "• <b>Status Black</b> — продвинутый доступ\n"
            "• <b>Status Gold</b> — полный доступ\n\n"
            "После оплаты вернись в приложение ejeweeka — "
            "все функции разблокируются автоматически.",
        )

    # ============================================================
    # CALLBACK QUERIES
    # ============================================================

    @dp.callback_query(F.data == "main_menu")
    async def cb_main_menu(callback: types.CallbackQuery):
        """Return to main menu."""
        await callback.message.edit_text(
            "Выбери действие:",
            reply_markup=get_status_keyboard(),
        )
        await callback.answer()

    @dp.callback_query(F.data == "my_status")
    async def cb_my_status(callback: types.CallbackQuery):
        """Show status via callback."""
        sub = await get_subscription_by_tg_id(callback.from_user.id)

        if not sub:
            await callback.answer("Профиль не привязан", show_alert=True)
            return

        tier = sub.get("tier", "free")
        paid_until = sub.get("paid_until")
        tier_name = {"free": "Free", "trial": "Gold (Trial)", "black": "Black", "gold": "Gold"}

        text = f"📊 <b>Текущий статус: {tier_name.get(tier, tier)}</b>"
        if paid_until:
            text += f"\nАктивен до: {paid_until.strftime('%d.%m.%Y')}"

        await callback.answer(text, show_alert=True)

    @dp.callback_query(F.data.startswith("buy:"))
    async def cb_buy(callback: types.CallbackQuery):
        """Handle tier purchase."""
        tier = callback.data.split(":")[1]

        # Get user's UUID
        sub = await get_subscription_by_tg_id(callback.from_user.id)
        if not sub:
            await callback.answer("Сначала привяжи профиль через приложение", show_alert=True)
            return

        anonymous_uuid = sub["anonymous_uuid"]
        tier_name = {"black": "Black", "gold": "Gold"}
        tier_price = {"black": "490", "gold": "990"}

        # Create ЮKassa payment
        payment_url = await create_payment(tier, anonymous_uuid, callback.from_user.id)

        if payment_url:
            keyboard = InlineKeyboardMarkup(inline_keyboard=[
                [InlineKeyboardButton(text=f"💳 Оплатить {tier_price[tier]} ₽", url=payment_url)],
                [InlineKeyboardButton(text="← Назад", callback_data="main_menu")],
            ])

            await callback.message.edit_text(
                f"🛒 <b>Оформление Status {tier_name[tier]}</b>\n\n"
                f"Сумма: <b>{tier_price[tier]} ₽/мес</b>\n"
                f"Оплата: ЮKassa (карта, СБП, кошелёк)\n\n"
                f"После оплаты вернись в приложение ejeweeka — "
                f"все функции разблокируются автоматически.",
                reply_markup=keyboard,
            )
        else:
            await callback.answer(
                "⚠️ Ошибка создания платежа. Попробуйте позже.",
                show_alert=True,
            )

        await callback.answer()
