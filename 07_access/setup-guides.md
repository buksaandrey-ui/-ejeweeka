# ejeweeka — Пошаговые инструкции к запуску

> Дата: 2026-04-27 | Модель оплаты: Premium Stealth (Telegram + ЮKassa)

---

## 💬 Инструкция 1: Telegram Bot (@healthcode_bot)

> Время: ~1-2 часа | Стоимость: бесплатно

### Шаг 1: Создай бота через BotFather
1. Открой Telegram → найди `@BotFather`
2. Отправь `/newbot`
3. Имя бота: `ejeweeka Concierge`
4. Username: `healthcode_bot` (или схожий свободный)
5. BotFather вернёт **API Token** — сохрани его в `.env`

### Шаг 2: Зарегистрируй бота в BotFather
```
/setdescription — «Управление статусами ejeweeka: оплата, восстановление, поддержка»
/setabouttext   — «Оформите Status Black или Gold для доступа к полному функционалу»
/setcommands:
  start   — Главное меню
  status  — Мой текущий статус
  pay     — Оформить / продлить статус
  restore — Восстановить статус на новом устройстве
  help    — Помощь
```

### Шаг 3: Установи python-telegram-bot
```bash
pip install python-telegram-bot==20.7 aiohttp
```

### Шаг 4: Базовая структура бота
```python
# telegram_bot/main.py
from telegram import Update, InlineKeyboardMarkup, InlineKeyboardButton
from telegram.ext import Application, CommandHandler, CallbackQueryHandler

BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
BACKEND_URL = 'https://healthcode-api.onrender.com'

async def start(update: Update, ctx):
    kb = InlineKeyboardMarkup([
        [InlineKeyboardButton('💳 Оформить Status Black — 490₽/мес', callback_data='pay_black')],
        [InlineKeyboardButton('⭐ Оформить Status Gold — 990₽/мес', callback_data='pay_gold')],
        [InlineKeyboardButton('🔄 Восстановить статус', callback_data='restore')],
    ])
    await update.message.reply_text(
        '👋 Добро пожаловать в ejeweeka!\n\nВыбери действие:',
        reply_markup=kb
    )

async def pay_callback(update: Update, ctx):
    query = update.callback_query
    tier = 'black' if 'black' in query.data else 'gold'
    # Создаём платёжную ссылку через ЮKassa
    payment_url = await create_yukassa_payment(tier, query.from_user.id)
    await query.message.reply_text(f'💳 Ссылка для оплаты:\n{payment_url}')

app = Application.builder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler('start', start))
app.add_handler(CallbackQueryHandler(pay_callback))
app.run_polling()
```

### Шаг 5: Разверни бота
```bash
# На Render.com (новый сервис, Web Service)
# Build Command: pip install -r requirements.txt
# Start Command: python telegram_bot/main.py
```

> [!TIP]
> **Проверка**: Открой `@healthcode_bot` в Telegram → /start → должны появиться кнопки оплаты.

---

## 💳 Инструкция 1b: ЮKassa (платёжный шлюз)

> Время: ~1 день (ожидание верификации) | Стоимость: 1-3.5% с транзакции

### Шаг 1: Регистрация
1. Перейди на https://yookassa.ru
2. Нажми **Подключиться** → выбери «Самозанятый» или «ИП»
3. Заполни анкету → загрузи документы (паспорт + ИНН)
4. Ожидание верификации: 1-3 рабочих дня

### Шаг 2: Тестовый режим
1. В личном кабинете → **Интеграция** → **API ключи**
2. Скопируй:
   - `Shop ID` (числовой)
   - `Secret Key` (начинается с `test_` для теста)
3. Сохрани в `.env`:
```bash
YOOKASSA_SHOP_ID=12345
YOOKASSA_SECRET_KEY=test_xxxxx
```

### Шаг 3: FastAPI вебхук
```python
# backend/routers/payments.py
from yookassa import Configuration, Payment
Configuration.account_id = os.getenv('YOOKASSA_SHOP_ID')
Configuration.secret_key = os.getenv('YOOKASSA_SECRET_KEY')

@router.post('/payments/create')
async def create_payment(anonymous_uuid: str, tier: str):
    prices = {'black': 49000, 'gold': 99000}  # в копейках
    payment = Payment.create({
        'amount': {'value': str(prices[tier] / 100), 'currency': 'RUB'},
        'confirmation': {'type': 'redirect', 'return_url': 'https://t.me/healthcode_bot'},
        'description': f'ejeweeka Status {tier.title()}',
        'metadata': {'anonymous_uuid': anonymous_uuid, 'tier': tier},
        'capture': True,
    })
    return {'payment_url': payment.confirmation.confirmation_url}

@router.post('/payments/yookassa/webhook')
async def yookassa_webhook(request: Request, db: Session = Depends(get_db)):
    payload = await request.json()
    if payload['event'] == 'payment.succeeded':
        meta = payload['object']['metadata']
        uuid = meta['anonymous_uuid']
        tier = meta['tier']
        # Обновляем статус в Supabase
        expires = datetime.now() + timedelta(days=30)
        db.execute(
            'UPDATE hc_subscriptions SET tier=$1, tier_expires_at=$2 WHERE anonymous_uuid=$3',
            [tier, expires, uuid]
        )
    return {'status': 'ok'}
```

### Шаг 4: Настрой вебхук в ЮKassa
1. Личный кабинет → **Интеграция** → **HTTP-уведомления**
2. URL: `https://healthcode-api.onrender.com/api/v1/payments/yookassa/webhook`
3. Тип: `payment.succeeded`, `payment.canceled`
4. Сохрани

> [!TIP]
> **Проверка**: В тестовом режиме используй тестовую карту `5555 5555 5555 4444` (любой CVV и срок). Должен прийти вебхук и обновиться статус.

---

## 🔔 Инструкция 2: Firebase (Push-уведомления)

> Время: ~20 минут | Стоимость: бесплатно

### Шаг 1: Создай проект Firebase
1. Перейди на https://console.firebase.google.com
2. **Add project** → Имя: `AIDiet`
3. Google Analytics → можно отключить (или включить, если хочешь аналитику)
4. **Create project** → подожди 30 сек

### Шаг 2: Добавь iOS-приложение
1. В проекте нажми на иконку **Apple** (🍎)
2. Bundle ID: `com.aidiet.app`
3. App nickname: `AIDiet iOS`
4. **Register app**
5. Скачай **`GoogleService-Info.plist`**
6. **Скопируй файл** в проект:
```bash
cp ~/Downloads/GoogleService-Info.plist aidiet-app/ios/App/App/GoogleService-Info.plist
```

### Шаг 3: APNs Key (для iOS push)
1. Перейди на https://developer.apple.com → **Certificates, IDs & Profiles**
2. **Keys** → **+** → отметь **Apple Push Notifications service (APNs)**
3. Key Name: `AIDiet Push Key`
4. **Register** → скачай `.p8` файл
5. Запиши **Key ID** (10 символов) и **Team ID** (из верхнего правого угла)
6. В Firebase Console → **Project Settings** → **Cloud Messaging** → вкладка **Apple app configuration**
7. Загрузи `.p8` файл, введи Key ID и Team ID

### Шаг 4: Установи Capacitor плагин
```bash
cd aidiet-app
npm install @capacitor/push-notifications
npx cap sync ios
```

### Шаг 5: Xcode (iOS)
1. Открой проект в Xcode: `npx cap open ios`
2. Target → **Signing & Capabilities** → **+ Capability**:
   - ✅ **Push Notifications**
   - ✅ **Background Modes** → отметь **Remote notifications**

> [!TIP]
> **Проверка**: Firebase Console → Cloud Messaging → **Send your first message** → введи тестовый FCM-токен из логов приложения.

---

## 🚀 Инструкция 3: Render Deploy (production backend)

> Время: ~10 минут | Стоимость: $7/мес (Starter plan)

### Шаг 1: Обнови план
1. Перейди на https://dashboard.render.com
2. Выбери сервис **aidiet-api**
3. **Settings** → **Plan** → переключи на **Starter** ($7/мес)
4. Подтверди

### Шаг 2: Добавь переменные окружения
1. **Environment** → **Environment Variables** → **Add Environment Variable**:

| Key | Value | Комментарий |
|-----|-------|-------------|
| `JWT_SECRET` | *(сгенерируй)* | 64 случайных символа |
| `STRICT_AUTH` | `true` | Включает проверку токенов |
| `DATABASE_URL` | *(уже должен быть)* | Supabase connection string |
| `GEMINI_API_KEY` | *(уже должен быть)* | Google AI Studio ключ |

**Для генерации JWT_SECRET** выполни в терминале:
```bash
openssl rand -hex 32
```
Скопируй результат (64 символа) и вставь как значение `JWT_SECRET`.

### Шаг 3: Deploy
1. Нажми **Manual Deploy** → **Deploy latest commit**
2. Подожди 2-3 минуты пока билд завершится
3. Проверь: открой `https://aidiet-api.onrender.com/api/v1/health`
4. Ответ должен содержать `"status": "ok"`, `"database": true`, `"gemini_key": true`

> [!WARNING]
> После включения `STRICT_AUTH=true` все запросы без токена будут возвращать 401. Убедись, что фронтенд вызывает `/auth/init` и отправляет Bearer токен.

---

## 👥 Инструкция 4: Набор 20 тестировщиков для Google Play

> Время: 2-3 дня на набор + **14 дней** ожидания | Стоимость: бесплатно

### Почему это нужно

Google Play с 2023 года **требует** закрытое тестирование с **минимум 12 реальными тестировщиками** (рекомендуется 20 для запаса), которые **активно используют** приложение **14 дней подряд**. Без этого — кнопка "Production release" заблокирована.

### Где искать тестировщиков

#### Telegram (русскоязычные)
| Канал/Группа | Описание |
|-------------|----------|
| Поиск: `Google Play Testers` | Группы взаимного тестирования |
| Поиск: `Android Closed Testing` | Чаты для обмена бета-тестами |
| `@qajuniors` | Начинающие тестировщики (попросить протестировать) |
| `@qa_ru` | Русскоязычное QA-сообщество |
| Поиск: `бета тестирование приложений` | Общие группы для тестеров |

> Совет: в поиске Telegram введи `Тестировщики Google Play` — появится 5-10 активных групп

#### Reddit (англоязычные, но самые надёжные)
| Сабреддит | Описание |
|-----------|----------|
| **r/AndroidClosedTesting** | Главный сабреддит для взаимного тестирования |
| **r/TestersCommunity** | Активное сообщество тестеров |
| **r/AndroidApps** | Можно попросить о тестировании |

#### Платформы для обмена
| Платформа | URL |
|-----------|-----|
| **TheClosedTest** | https://theclosedtest.com |
| **Testers Community** | Мобильное приложение для обмена тестерами |

### Принцип «взаимного тестирования»

Ты тестируешь чужое приложение ↔ Они тестируют твоё. Это **бесплатно** и **легально** — Google одобряет такой подход.

### Как организовать

1. **Создай Google Group** (groups.google.com) → имя: `aidiet-testers@googlegroups.com`
2. В Google Play Console → **Closed Testing** → **Manage testers** → укажи Google Group
3. Добавляй email тестировщиков в Google Group
4. Раздай ссылку на установку из Google Play Console

### Готовое ТЗ для тестировщиков

> Скопируй и размести в Telegram/Reddit

---

```
🍎 Ищу 20 тестировщиков для AIDiet — AI-план питания

📱 Что за приложение:
AIDiet — мобильное приложение, которое составляет персональный план питания
на основе AI. Учитывает твои цели, здоровье, аллергии, бюджет и время
на готовку. Основано на рекомендациях реальных врачей (доказательная медицина).

🎯 Что нужно от тебя:
1. Установить приложение из Google Play (закрытое тестирование)
2. Пройти онбординг (заполнить профиль — 5-10 минут)
3. Открывать приложение хотя бы 1 раз в день в течение 14 дней
4. Попробовать основные функции:
   - Посмотреть план питания на неделю
   - Открыть любой рецепт
   - Отметить "Съел по плану" хотя бы 1 блюдо
   - Попробовать фото-анализ еды (сфотографировать любое блюдо)
   - Добавить воду в трекер
5. (Необязательно) Написать краткий фидбек — что понравилось, что нет

⏱ Сколько времени:
- Первый день: 10-15 минут (онбординг + осмотр)
- Остальные 13 дней: 1-2 минуты в день (открыть → посмотреть → закрыть)

📋 Требования:
- Android 8.0+ (99% смартфонов)
- Google-аккаунт (для Google Play)
- Реальное устройство (не эмулятор)

🤝 Взамен:
- Бесплатный Gold-доступ на 3 месяца (после релиза)
- Готов тестировать ваше приложение в ответ (взаимное тестирование)

📩 Как присоединиться:
1. Напишите мне в ЛС свой email (Google-аккаунт)
2. Я добавлю тебя в группу тестировщиков
3. Ты получите ссылку на установку из Google Play

Спасибо! 🙏
```

---

### Таймлайн набора тестеров

```
День 1:    Разместить ТЗ в 5-10 группах/форумах
День 2-3:  Собрать 20-25 email (набери с запасом!)
День 3:    Добавить всех в Google Group → раздать ссылку
День 4-17: 14 дней тестирования (напоминай раз в 3 дня: "Откройте приложение!")
День 18:   Проверить в Google Play Console: ≥12 тестеров активны → Production unlock
```

> [!WARNING]
> **Не используй ботов и платные сервисы!** Google проверяет реальность тестеров.
> При обнаружении фейков — бан аккаунта разработчика навсегда.

---

## ✅ Чеклист: что делать сейчас (пока ждём Apple ID)

| # | Задача | Время | Зависит от |
|---|--------|-------|------------|
| 1 | Настроить @healthcode_bot (BotFather + Python) | 1-2ч | — |
| 2 | ЮKassa: регистрация + тестовый режим | 1д (верификация) | — |
| 3 | FastAPI: webhook эндпоинт + Supabase схема | 2-3ч | — |
| 4 | Firebase проект + APNs key | 20 мин | Apple Developer ID |
| 5 | Render deploy (production) | 10 мин | — |
| 6 | Privacy Policy на домене | 5 мин | — |

> **Совет**: Пункты 1, 2, 3, 5, 6 — делаем прямо сейчас пока ждём Apple ID. Пункт 4 — после одобрения аккаунта.
