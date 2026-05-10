# ejeweeka TG Concierge — Инструкция по запуску

> Код бота уже написан и лежит в `aidiet-backend/bot/`. Ниже — шаги для финального подключения.

---

## Шаг 1: Создать бота в Telegram

1. Откройте Telegram → найдите **@BotFather**
2. Отправьте `/newbot`
3. Имя бота: `ejeweeka`
4. Username: `healthcode_bot` (если занят — `healthcode_app_bot` и обновить `TG_BOT_USERNAME` в `tg-bridge-modal.js`)
5. Скопируйте **токен** (формат: `123456789:ABCdefGHIjklMNOpqrSTUvwxYZ`)
6. Настройте бота:
   - `/setdescription` → `Ассистент ejeweeka. Управление статусом и доступом к алгоритму.`
   - `/setabouttext` → `Управляй подпиской ejeweeka: Status Black и Status Gold.`
   - `/setcommands` → отправьте:
     ```
     start - Привязать профиль
     status - Мой статус
     help - Помощь
     ```

**Результат:** `TELEGRAM_BOT_TOKEN` = токен из п.5

---

## Шаг 2: Зарегистрировать магазин в ЮKassa

1. Зайдите на [yookassa.ru](https://yookassa.ru) → «Подключить ЮKassa»
2. Зарегистрируйтесь как ИП (или ТОО Казахстан)
3. После одобрения (1-3 дня):
   - В личном кабинете → **Интеграция** → **Ключи API**
   - Скопируйте `shopId` → это `YOKASSA_SHOP_ID`
   - Сгенерируйте Secret Key → это `YOKASSA_SECRET_KEY`
4. Настройте webhook:
   - **URL:** `https://aidiet-api.onrender.com/api/v1/subscription/yokassa-webhook`
   - **События:** `payment.succeeded`, `payment.canceled`

**Результат:** `YOKASSA_SHOP_ID` + `YOKASSA_SECRET_KEY`

---

## Шаг 3: Добавить env vars в Render

В [Render Dashboard](https://dashboard.render.com) → твой сервис → **Environment**:

| Variable | Value | Описание |
|----------|-------|----------|
| `TELEGRAM_BOT_TOKEN` | `123456789:ABC...` | Из шага 1 |
| `YOKASSA_SHOP_ID` | `12345` | Из шага 2 |
| `YOKASSA_SECRET_KEY` | `test_...` или `live_...` | Из шага 2 |
| `WEBHOOK_BASE_URL` | `https://aidiet-api.onrender.com` | Уже должен быть |
| `DATABASE_URL` | `postgresql://...` | Уже должен быть (Supabase) |

Нажмите **Save Changes** → сервис перезапустится.

---

## Шаг 4: Создать таблицу в Supabase

В [Supabase SQL Editor](https://supabase.com/dashboard) выполните:

```sql
CREATE TABLE IF NOT EXISTS tg_subscriptions (
    id SERIAL PRIMARY KEY,
    anonymous_uuid VARCHAR(64) UNIQUE NOT NULL,
    telegram_user_id BIGINT,
    tier VARCHAR(20) DEFAULT 'white',
    payment_id VARCHAR(128),
    paid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tg_sub_uuid ON tg_subscriptions(anonymous_uuid);
CREATE INDEX IF NOT EXISTS idx_tg_sub_tg_id ON tg_subscriptions(telegram_user_id);
```

---

## Шаг 5: Запуск бота

### Локально (для тестирования):
```bash
cd aidiet-backend
source .venv/bin/activate
python run_bot.py
```

### На Render (production):
Добавьте **второй Worker** в Render:
- **Name:** `healthcode-tg-bot`
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `python run_bot.py`
- **Environment:** те же переменные что в шаге 3

---

## Шаг 6: Проверка

1. Откройте `https://t.me/healthcode_bot?start=test-uuid-123`
2. Бот должен ответить: "Привет! Профиль синхронизирован..."
3. Нажмите "Status Gold" → должна появиться кнопка "Оплатить 990 ₽"
4. (тестовый режим ЮKassa) Оплатите → бот пришлёт "Оплата прошла!"

---

## Файлы бота

| Файл | Назначение |
|------|-----------|
| `bot/__init__.py` | Entry point: aiogram Bot + Dispatcher |
| `bot/handlers.py` | /start UUID, /status, inline keyboards |
| `bot/yokassa.py` | ЮKassa: create_payment, parse_webhook |
| `bot/models.py` | asyncpg: tg_subscriptions CRUD |
| `app/api/subscription.py` | FastAPI: GET /status, POST /yokassa-webhook |
| `run_bot.py` | Точка запуска |

---

## Связь с iOS-приложением

Deep link формируется в `tg-bridge-modal.js`:
```
tg://resolve?domain=healthcode_bot&start={USER_UUID}
```

> Если username бота отличается от `healthcode_bot` — обновите `TG_BOT_USERNAME` в файле `05_ui_screens/main-screens/tg-bridge-modal.js` (строка 16).
