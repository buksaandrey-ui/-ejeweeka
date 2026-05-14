# ejeweeka — Контекст проекта (обновлять после каждой сессии)
# Последнее обновление: 2026-05-13

> [!CAUTION]
> **BRAND SPELLING RULE:** Название продукта ВСЕГДА пишется только так: **ejeweeka** (lowercase).
> Запрещено: EjeWEEKa, EJEWEEKA, Ejeweeka, ejeWEEKa и любые смешанные варианты.

> [!CAUTION]
> **CRITICAL RULE FOR ALL AI AGENTS:**
> ПЕРЕД выполнением ЛЮБОЙ задачи, ты ОБЯЗАН сверяться с двумя главными документами:
> 1. `/Users/andreybuksa/Downloads/aidiet-docs/01_architecture/architecture.md`
> 2. `/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/screens-map.md`
>
> **ЗАКОН UI:** ВСЕ экраны без исключений должны СТРОГО соответствовать контенту из карты экранов (`screens-map.md`). Запрещено добавлять или убирать кнопки, логику или элементы, не описанные в карте. Карта экранов — единственный авторитет по контенту. Без ее анализа запрещено писать код. Единственный источник правды по коду UI — папка `05_ui_screens/main-screens/`. Черновые React-файлы не являются авторитетными.

> [!WARNING]
> **ПРАВИЛО ТРОЙКИ (TRINITY RULE):**
> Три файла образуют «треугольник истины» проекта:
> 1. `PROJECT_CONTEXT.md` — бизнес-контекст, ключи данных, pipeline
> 2. `01_architecture/architecture.md` — техническая архитектура, статусы, API
> 3. `05_ui_screens/screens-map.md` — карта экранов, UX-спецификации
>
> **При обнаружении ЛЮБОГО расхождения** между этими тремя файлами или между ними и кодом:
> 1. ❌ ЗАПРЕЩЕНО молча менять код или спеки
> 2. ✅ ОБЯЗАТЕЛЬНО: описать расхождение, предложить **минимум 3 варианта** решения
> 3. ✅ ДОЖДАТЬСЯ явного решения от Андрея
> 4. ✅ СНАЧАЛА обновить спеки (все 3 файла), ПОТОМ менять код
>
> Без прохождения этой процедуры изменения в архитектуру/данные/спеки ЗАПРЕЩЕНЫ.

## Кто я
Андрей. Solo-founder без опыта разработки. Работаю через оркестрацию AI:
Antigravity (IDE), Claude (архитектура, UI через UI UX Pro Max + Frontend Design skill), ChatGPT, Gemini, Grok.
Нет наёмных разработчиков и дизайнеров.

## Среда разработки
- **Машина**: MacBook Pro (macOS), `MacBook-Pro-Andrej`
- **Xcode**: Установлен (iOS-сборка доступна)
- **Android Studio**: Требуется проверить / установить
- **GitHub**: `buksaandrey-ui/aidiet-docs` (основной репозиторий)
- **Vercel**: `main-screens.vercel.app` (UI прототипы)
- **Render**: `aidiet-api.onrender.com` (Backend API, Free tier)
- **Supabase**: проект `AIDiet`, регион `eu-west-1`, NANO plan

## Юридика и публикация
- **Текущее юрлицо**: ИП (Россия)
- **Планируемое юрлицо**: ТОО (Казахстан) — для Apple/Google Developer аккаунтов
- **Apple Developer**: ❌ Ещё не зарегистрирован (ждёт ТОО в Казахстане)
- **Google Play Developer**: ❌ Ещё не зарегистрирован
- **Тестирование до регистрации**: Xcode Simulator, USB-деплой на своё устройство, Android Emulator

## Проект
ejeweeka — Массовый Apple-like wellness-продукт: простой, чистый, умный, доброжелательный помощник по питанию, сну и активности, понятный миллионам пользователей.
Приложение использует Zero-Knowledge архитектуру (zero-knowledge health profile + minimal server-side billing account): чувствительные health-данные хранятся исключительно на устройстве. На сервер передаётся только обезличенный JSON для генерации плана, который немедленно удаляется после ответа. Сервер хранит ТОЛЬКО billing/account/entitlement данные. Приложение не является медицинским устройством или клиникой.
- **Монетизация (Hybrid)**: Уровни доступа (статусы: white / black / gold) работают как прозрачная подписочная модель. Архитектура:
  - **iOS app**: IAP через Apple StoreKit (auto-renewable subscriptions) + status sync через email login
  - **Web РФ (ejeweeka.ru)**: ЮKassa (СБП, карты РФ) + промокоды + управление подпиской
  - **Backend**: Unified entitlement system — единый source of truth для статуса
- Во время ревью Apple активируется `Review Demo Mode`.
- **Внутренние API-имена** (`aidiet_profile`, `AIDiet.saveField`, `aidiet_subscription`) — сохранены для обратной совместимости. UI-facing имя: **ejeweeka**.
- **Billing/account данные** (email, платёжные записи, consent logs) являются персональными данными и требуют соблюдения 152-ФЗ.

## Позиционирование (Mass-Market Wellness)
Массовый, понятный миллионам пользователей Apple-like wellness-сервис. Простой, чистый, умный, доброжелательный. Приложение позиционируется строго как лайфстайл-помощник, не предоставляющий медицинских диагнозов, лечения или жестких "медицинских" диет. Мы не запугиваем пользователя терминами.
- **Только wellness и nutrition**.
- **Строгое соответствие Guideline 1.4.1 (отказ от медицинской диагностики)**.

## Четыре ключевых УТП
1. **Всё в одном плане** — «Что есть, как готовить, что купить, как тренироваться — всё в одном плане под твой бюджет и время».
2. **Витамины, которые работают** — «Железо с кофе — деньги на ветер. Витамин D без жирной еды не усвоится. Мы составим расписание витаминов, которое реально работает».
3. **Учтём все нюансы» — «Веган, халяль, беременность, подагра — учтём все важные для тебя нюансы».
4. **Калории по фото** — «Ужин в ресторане или в гостях? Просто сфотографируй — мы пересчитаем план».

## Ключевые решения
- HC-движок: Gemini 2.5 Flash (генерация планов, Vision для фото, отчёты)
- База знаний: **16000+ чанков** от 30+ практикующих врачей → RAG → pgvector (Supabase)
- YouTube Hunter v8: автоматический сбор, безлимитный режим
- Photo Analysis: Gemini Vision (НЕ YOLO-v8)
- Theme Engine: 8 цветовых схем по статусам (CSS Custom Properties)
- Zero-Knowledge Security: Сервер (PostgreSQL) НЕ содержит таблиц пользователей и их болезней.
- БД: PostgreSQL + pgvector + Redis (Только справочники рецептов, врачи и RAG-база).
- Инфраструктура: Render (backend) + Vercel (frontend) + Supabase (DB)

## Текущая фаза
- Фаза 1: Генерация макетов + LocalStorage прототипирование ✅
- Фаза 1.5: Стабилизация онбординга + Data Pipeline ✅ (2026-04-20)
- Фаза 1.7: Full-Stack аудит (Frontend→Backend→Prompt) ✅ (2026-04-21)
- Фаза 1.8: Theme Engine + Testing Suite ✅ (2026-04-22)
- Фаза 1.9: RAG пополнение (16000 → MAX) 🔄 ПАРАЛЛЕЛЬНО
- **Фаза 2: Backend MVP** ✅ (2026-04-23)
  - 6 API endpoints (auth, plan, photo, chat, report, health)
  - Render deploy: `https://aidiet-api.onrender.com` (Активен, БД Supabase подключена, Gemini настроен)
  - Frontend (Vercel) строго подключен к боевому API (оффлайн-заглушки удалены).
- **Фаза 3: Native Flutter App + Hybrid Monetization** ✅ ТЕКУЩАЯ (2026-05-13)
  - ✅ Full Flutter native app (iOS/Android)
  - ✅ Ренейминг AIDiet → ejeweeka (UI-facing)
  - ✅ Review Demo Mode: при модерации Apple демонстрируется полный функционал через тестовый аккаунт
  - ✅ Hybrid Monetization: IAP (iOS/global) + ЮKassa web (РФ) + unified backend entitlement
  - ✅ O-17 (Statuswall) удалён из обязательного онбординга. O-16.5 → H-1
  - 🔄 iOS Simulator тестирование
  - ⬜ Android build — отложен на 3-4 месяца

## Зафиксированные значимые статусы (2026-05-13)
1. **Frontend-to-Backend Connection**: Backend (FastAPI / Render) полностью функционален. Flutter app использует Bearer JWT для авторизации.
2. **Онбординг**: O-16.5 (Персональный разбор) ведёт напрямую на H-1. O-17 (Statuswall) удалён из MVP-цепочки.
3. **Генерация плана**: `app/api/plan.py` — Gemini формирует JSON план на основе RAG-базы данных (16000+ чанков).
4. **Монетизация**: Hybrid architecture — IAP для App Store, ЮKassa для РФ web, unified entitlement backend.
5. **MVP-статусы**: white / black / gold. Group Gold / Family Gold перенесены в Post-MVP.
- Фаза 5: App Store Assets + Юридика (ТОО Казахстан)
- **Фаза 6: Archetype Prompt Factory** ✅ (2026-05-04)
  - 3-Layer Composable Prompt Architecture: 5 GoalClusters × 2 Genders × 3 LifeStages + Pregnancy/BF overrides
  - `archetypes.py`: ArchetypePromptFactory.get_system_role() → 32+ уникальных комбинаций промптов
  - `assembler.py`: _build_medical_guardrails → _build_wellness_guardrails (Guideline 1.4.1)
  - `plan.py`: medical_rationale → wellness_rationale, pregnancy calorie guardrail, archetype_used logging
  - E2E: 338 тестов (test_archetypes.py) — все ✅
- Фаза 7: TestFlight (iOS only)
- Фаза 8: App Store Submit (iOS only)

## Визуальный стиль: Style B — Material Premium
- Основной (Акцент): #4C1D95 (Orange)
- Белки: #52B044 · Жиры: #F09030 · Углеводы: #42A5F5
- Фон: #FAFAFA · Шрифт: Inter (400–700)

## Архитектура данных (SSOT — 2026-04-20)

> [!IMPORTANT]
> **Единый источник правды: `aidiet_profile`** (localStorage).
> Все данные онбординга записываются ТОЛЬКО через `AIDiet.saveField(key, value)`.
> Все чтения — ТОЛЬКО через `AIDiet.getProfile()`.
> Ключ `aidiet_onboarding` — МЁРТВЫЙ, не использовать.

### Канонические ключи профиля (English Only):
| Группа | Ключи |
|--------|-------|
| O-1 | `country`, `city` |
| O-2 | `goal`, `weight_loss_details` |
| O-3 | `name`, `gender`, `age`, `height`, `weight`, `bmi`, `bmr`, `waist`, `body_type` |
| O-4 | `target_weight`, `target_timeline_weeks` |
| O-5 | `diets`, `allergies` |
| O-6 | `symptoms`, `diseases`, `medications`, `takes_contraceptives`, `custom_condition`, `o6_visited` |
| O-7 | `womens_health` |
| O-8 | `meal_pattern`, `fasting_type`, `_fastingState` (JSON) |
| O-9 | `bedtime`, `wakeup_time` |
| O-10 | `activity_level`, `activity_types`, `activity_multiplier` |
| O-11 | `budget_level`, `cooking_time` |
| O-12 | `blood_tests` (JSON) |
| O-13 | `supplements`, `supplement_openness` |
| O-14 | `motivation_barriers` |
| O-15 | `liked_foods`, `disliked_foods`, `excluded_meal_types` |
| Calculated | `bmr_kcal`, `target_daily_calories`, `target_daily_fiber`, `tdee_calculated` |
| UI | `selected_theme`, `trial_start`, `_firstLaunch`, `_schema_version` |
| Billing (server-side) | `entitlement_status`, `entitlement_source`, `billing_account_id`, `app_profile_id` |

### Data Pipeline:
```
Онбординг (O-1..O-15) → saveField() → local profile
    ↓
O-16 Summary ← getProfileSummary()
    ↓
O-16 «Составить план» → buildProfilePayload() → API
    ↓
Backend: plan.py → BMR/TDEE → ArchetypePromptFactory → PromptAssembler → Gemini → JSON Plan
    ↓
O-16.5 (Персональный разбор) → H-1 (Дашборд)
    ↓
Trial (3 дня Gold) стартует автоматически при первом входе на H-1
```

### Billing Pipeline (server-side):
```
iOS App: StoreKit IAP → POST /api/v1/iap/verify → entitlements table
Web РФ: ЮKassa → POST /webhooks/yookassa → entitlements table
Status Sync: POST /auth/link-email → GET /entitlements/status → local state update
```

### Запрещённые паттерны:
- ❌ `localStorage.getItem('aidiet_onboarding')` — мёртвый ключ
- ❌ `localStorage.getItem('aidiet_Пол')` — phantom key
- ❌ `localStorage.getItem('o8_dietState')` — phantom key
- ❌ `setupAutoSave()` — удалена из всех O-screens
- ❌ food_log внутри `aidiet_profile` — дневник хранится в `aidiet_food_log`

## Архитектурные Принципы
1. **SSOT Architecture**: Единый ключ `aidiet_profile`, API `AIDiet.saveField/getProfile`
2. **HC Caching**: Cron-Job цены +15%, хэш ингредиентов → S3, Recipe Vault
3. **UI Стандартизация**: Flexbox `.input-wrapper`, Capture-phase interceptor на кнопках «Далее»
4. **Archetype Prompt Factory** (`archetypes.py`): 3-Layer Composable Prompts. Layer 1 = GoalCluster (5) × Gender (2) × LifeStage (3) + Pregnancy/BF overrides. Layer 2 = `_build_wellness_guardrails`. Layer 3 = `_build_lifestyle`. Маршрутизация: `ArchetypePromptFactory.get_system_role(goal, gender, age, womens_health)`. Код архетипа логируется в `archetype_used` для аналитики.
5. **Wellness-Only Compliance**: Все ключи и лейблы используют wellness-терминологию (`wellness_rationale`, `_build_wellness_guardrails`, `custom_condition`). Запрещены: `medical_rationale`, `_build_medical_guardrails`, `custom_diagnosis`. E2E: 338 тестов (test_archetypes.py).
