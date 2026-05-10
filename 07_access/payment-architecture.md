# ejeweeka — Архитектура платежей (Premium Stealth)

> Обновлено: апрель 2026
> Модель: **Premium Stealth** — оплата вне App Store через Telegram-консьержа и ЮKassa.
> Никаких In-App Purchase (IAP). Никаких комиссий App Store (15-30%).

---

## Почему Premium Stealth, а не IAP

| Параметр | Apple IAP | Premium Stealth (наш путь) |
|----------|-----------|---------------------------|
| Комиссия | 15-30% | 1-3.5% (ЮKassa) |
| Ограничения | Обязательно через Apple Billing | Нет |
| Карты РФ (МИР) | ❌ не работают | ✅ СБП, MirPay, Yandex Pay |
| Гибкость цен | Только через App Store Connect | Полная свобода |
| Возврат | Через Apple (сложно) | Через ЮKassa напрямую |

> Apple не банит приложения за отсутствие IAP, если приложение
> не предлагает купить подписку **внутри** приложения через нативный UI.
> Мы направляем пользователя в Telegram — это легальная модель.

---

## Стек платежей ejeweeka

| Слой | Решение | Назначение |
|------|---------|-----------|
| **Консьерж** | Telegram Bot `@healthcode_bot` | Оформление статусов, восстановление, поддержка |
| **Платёжный шлюз** | ЮKassa (Web SDK) | СБП + автоплатежи + Mir Pay / Yandex Pay |
| **Бэкенд** | FastAPI `/payments/yookassa/webhook` | Приём вебхуков → обновление subscription_status |
| **Хранение статуса** | Supabase (anonymous_uuid → tier) | Связь UUID приложения со статусом |

---

## Схема оплаты (основная)

```
Пользователь открывает O-17 (Statuswall) в приложении
          ↓
Нажимает «Повысить статус до Black / Gold»
          ↓
Приложение открывает deep link → @healthcode_bot в Telegram
          ↓
Бот присылает ссылку ЮKassa на оплату
          ↓
Пользователь платит: СБП / MirPay / Yandex Pay / карта
          ↓
ЮKassa шлёт webhook → FastAPI бэкенд
          ↓
FastAPI обновляет subscription_status по anonymous_uuid
          ↓
Приложение проверяет статус при следующем запуске → Status активен ✅
```

---

## Схема восстановления статуса (смена устройства)

```
Пользователь открывает O-17 или Настройки
          ↓
Нажимает «Восстановить статус»
          ↓
Открывается @healthcode_bot
          ↓
Бот запрашивает Telegram ID или email квитанции
          ↓
Бот находит запись в Supabase → переносит subscription_status на новый UUID
          ↓
Статус восстановлен ✅ (без повторной оплаты)
```

---

## FastAPI эндпоинты

```python
# Вебхук ЮKassa
POST /api/v1/payments/yookassa/webhook
→ Проверить подпись ЮKassa (HMAC)
→ Определить anonymous_uuid по metadata
→ Обновить tier в Supabase: white → black / gold
→ Установить tier_expires_at (дата следующего списания)
→ Ответить 200 OK

# Проверка статуса (приложение при запуске)
GET /api/v1/subscription/status?uuid={anonymous_uuid}
→ Вернуть { tier, tier_expires_at, is_trial }

# Создание платёжной ссылки (через бот)
POST /api/v1/payments/create
→ Принять { anonymous_uuid, tier, period }
→ Создать платёж в ЮKassa
→ Вернуть { payment_url }
```

---

## Supabase схема

```sql
CREATE TABLE hc_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anonymous_uuid TEXT UNIQUE NOT NULL,  -- UUID из приложения
  telegram_id BIGINT,                   -- для восстановления через бот
  tier TEXT DEFAULT 'white',             -- white / black / gold
  tier_expires_at TIMESTAMP,
  is_trial BOOLEAN DEFAULT false,
  trial_started_at TIMESTAMP,
  yookassa_payment_id TEXT,             -- последний платёж
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## Цены (ejeweeka)

| Статус | Месяц | Год |
|--------|-------|-----|
| White | 0 ₽ | — |
| Status Black | 490 ₽ | 4 490 ₽ (-24%) |
| Status Gold | 990 ₽ | 9 490 ₽ (-20%) |
| Family Gold | 990 ₽ + 690 ₽/чел | — |

**Триал**: первые 3 дня — полный Gold бесплатно (без карты).

---

## Стоимость стека

| Сервис | Цена |
|--------|------|
| ЮKassa | 1-3.5% от транзакции |
| Telegram Bot API | Бесплатно |
| Supabase | Уже есть (Free tier) |
| FastAPI (Render) | Уже задеплоен |
| **Итого** | **~2% vs 15-30% у Apple IAP** |

---

## Таймлайн

```
Сейчас          → Код Flutter готов (O-17 statuswall с TG deep link)
Неделя 1        → Настроить @healthcode_bot (BotFather + Python)
Неделя 2        → ЮKassa: регистрация + тестовый режим
Неделя 3        → FastAPI webhook + Supabase схема
Неделя 4        → Тестовые платежи end-to-end
Неделя 5        → Боевой режим ЮKassa
```
