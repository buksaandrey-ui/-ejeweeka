import re
import os

# 1. Update payment-architecture.md
arch_file = '07_access/payment-architecture.md'
if os.path.exists(arch_file):
    with open(arch_file, 'w') as f:
        f.write("""# ejeweeka — Архитектура платежей (Web-to-App Funnel)

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
""")

# 2. Deprecate tg-bot-setup.md
tg_file = '07_access/tg-bot-setup.md'
if os.path.exists(tg_file):
    with open(tg_file, 'w') as f:
        f.write("""# УСТАРЕЛО (DEPRECATED)

> **Внимание:** В мае 2026 года принято решение уйти от "Telegram консьержа".
> Воронка заменена на Web-to-App (лендинг -> 1 рубль триал -> автооплата).
> Настройка бота больше не требуется. Использовать чистый Web Checkout.
""")

# 3. Update u12_status_screen.dart
status_file = 'health_code/lib/features/profile/presentation/u12_status_screen.dart'
if os.path.exists(status_file):
    with open(status_file, 'r') as f:
        content = f.read()
    
    # Replace Telegram link with Web Landing URL
    content = content.replace("static const _tgBotUrl = 'https://t.me/ejeweeka_bot?start=subscribe';", 
                              "static const _webBillingUrl = 'https://app.ejeweeka.com/subscribe';")
    content = content.replace("Uri.parse(_tgBotUrl)", "Uri.parse(_webBillingUrl)")
    
    with open(status_file, 'w') as f:
        f.write(content)

# 4. Update page.tsx CTA
page_file = 'landing-page/src/app/page.tsx'
if os.path.exists(page_file):
    with open(page_file, 'r') as f:
        content = f.read()
    
    # Replace the CTA href
    content = re.sub(r'href="/variant-a"', 'href="/subscribe"', content)
    
    with open(page_file, 'w') as f:
        f.write(content)

print("Architectural audit and refactoring completed successfully.")
