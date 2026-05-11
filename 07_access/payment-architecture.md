# ejeweeka — Архитектура платежей (Web-to-App Funnel)

> Обновлено: май 2026
> Модель: **Web-to-App Trial Funnel** — подписка оформляется на веб-лендинге, минуя App Store.
> Никаких In-App Purchase (IAP). Отказ от Telegram-консьержа ("серая" схема устранена).

---

## Воронка продаж

```
Реклама (FB/Inst/VK) 
      ↓
Web Landing Page (app.ejeweeka.com)
      ↓
Триал за 1 рубль (Web YooKassa Checkout)
      ↓
Установка App из App Store / Google Play
      ↓
Авторизация по Email / Phone / UUID Token
      ↓
3 дня полного доступа (Gold)
      ↓
Автоматическое списание (Auto-charge Gold)
```

## Стек платежей ejeweeka

| Слой | Решение | Назначение |
|------|---------|-----------|
| **Web Checkout** | Next.js Landing | Выбор тарифа и ввод данных карты |
| **Платёжный шлюз** | ЮKassa (API/Web SDK) | Рекуррентные списания, 1 рубль за привязку |
| **Бэкенд** | FastAPI `/payments/yookassa/webhook` | Приём вебхуков → автосписание → обновление subscription_status |
| **Хранение статуса** | Supabase | Связь User ID со статусом |

## Отказ от Telegram Bot
Ранее использовался Telegram бот для отправки платежных ссылок. Это признано "палевной" схемой, повышающей риск бана и снижающей конверсию. Все ссылки из Flutter App теперь ведут напрямую на Web Billing Portal.

## FastAPI эндпоинты
- `POST /api/v1/payments/checkout` - инициализация платежа (1 руб) с лендинга.
- `POST /api/v1/payments/yookassa/webhook` - обработка рекуррентных платежей (auto-charge).
- `GET /api/v1/subscription/status` - проверка прав из мобильного приложения.
