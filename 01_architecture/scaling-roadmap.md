# AIDiet — План масштабирования UI-стека

> Этот документ описывает 3 фазы эволюции фронтенда AIDiet.
> Каждая фаза строится на предыдущей и запускается по триггеру (метрике).
> **НЕ переходить к следующей фазе, пока не достигнут триггер.**

---

## Фаза 1: HTML + Capacitor (MVP) ← МЫ ЗДЕСЬ
**Стек:** Vanilla HTML/CSS/JS → Capacitor WebView → iOS & Android  
**Триггер для перехода:** 500+ активных пользователей ИЛИ инвестиции

### Что имеем
- 51 HTML-экран (Style B Material Premium)
- `aidiet_profile` SSOT архитектура (localStorage)
- API на Render (`aidiet-api.onrender.com`)
- Capacitor обёртка с iOS/Android проектами

### Плюсы этой фазы
- ⚡ Скорость запуска: дни, не месяцы
- 💰 Стоимость: $0 (Free Render + твой MacBook)
- 🔄 Быстрые итерации: поменял HTML → npx cap sync → TestFlight

### Ограничения (когда начнут мешать)
- Навигация между экранами = перезагрузка страницы (мигание)
- localStorage = нет синхронизации между устройствами
- Сложно писать unit-тесты для HTML
- Нет переиспользуемых компонентов (копипаста между экранами)

### Когда двигаться дальше
- [ ] 500+ MAU подтверждают product-market fit
- [ ] Пользователи жалуются на «подтормаживания» или «мигания»
- [ ] Нужны фичи, которые сложно делать в HTML (offline-first, сложные анимации)

---

## Фаза 2: React + Capacitor
**Стек:** React (Vite) → Capacitor WebView → iOS & Android  
**Триггер для перехода:** 5000+ MAU ИЛИ нужен второй разработчик

### План миграции (2-3 недели)
```
Неделя 1: Инфраструктура
├── Настроить React Router (react-router-dom)
├── Создать Layout компоненты (Phone, BottomNav, StatusBar)
├── Перенести global.css → CSS Modules или Tailwind
├── Настроить Context API для aidiet_profile (замена localStorage)
└── Мигрировать api-connector.js → React hook (useAPI)

Неделя 2: Экраны (онбординг)
├── O-1..O-15 → React компоненты
├── O-16 Summary → читает из Context
├── O-17 Statuswall → TG deep link (@healthcode_bot) вместо IAP
└── Общий OnboardingWizard с прогресс-баром

Неделя 3: Экраны (основные)
├── H-1 Dashboard → React + анимации (Framer Motion)
├── P-1 Weekly Plan → карусель дней
├── S-1 Shopping List → drag & drop
├── U-series → формы с react-hook-form
└── Photo Analysis → Camera plugin + Gemini Vision
```

### Архитектурные решения для Фазы 2
| Решение | Выбор | Почему |
|---------|-------|--------|
| Стейт | Zustand | Легче Redux, уже есть useStore.js |
| Роутинг | React Router v7 | Стандарт |
| Стили | Tailwind CSS v4 | Быстрее CSS Modules для соло |
| Формы | react-hook-form | Валидация + performance |
| Анимации | Framer Motion | Премиум UX |
| API | TanStack Query | Кеширование + retry |
| Хранение | Capacitor Preferences | Замена localStorage |

### Что даст переход
- ✅ Компоненты переиспользуются (один MealCard → везде)
- ✅ Нормальная навигация без перезагрузки (SPA)
- ✅ Unit тесты (Vitest)
- ✅ Hot Module Reload при разработке
- ✅ Второй разработчик сможет быстро разобраться

---

## Фаза 3: React Native (или Flutter)
**Стек:** React Native → нативные компоненты → iOS & Android  
**Триггер:** 20 000+ MAU ИЛИ критичны нативные анимации/жесты

### Когда переходить на React Native
- Capacitor WebView стал узким местом (60fps не тянет)
- Нужны сложные жесты (свайпы, pinch-to-zoom на графиках)
- Нужна глубокая интеграция с HealthKit/Health Connect
- В команде появился React Native разработчик

### Когда переходить на Flutter вместо RN
- В команде есть Dart-разработчик
- Нужен pixel-perfect одинаковый UI на iOS и Android
- Планируется Desktop/Web версия из одного кода

### План миграции React → React Native (4-6 недель)
```
Неделя 1-2: Инфраструктура
├── React Navigation (замена React Router)
├── AsyncStorage (замена localStorage)
├── Нативные компоненты (View, Text, ScrollView)
├── Стилизация: StyleSheet.create (НЕ CSS)
└── API слой остаётся (fetch → тот же бэкенд)

Неделя 3-4: Экраны
├── Все экраны переписываются на нативные компоненты
├── Анимации: React Native Reanimated v3
├── Навигация: Stack + Tab + Modal стеки
└── Push: react-native-push-notification

Неделя 5-6: Интеграции
├── Telegram Deep Link: url_launcher → @healthcode_bot (Premium Stealth)
├── HealthKit: react-native-health
├── Camera: react-native-camera (Gemini Vision)
└── Тестирование: Jest + Detox E2E
```

### Что НЕ меняется при переходе
- 🟢 Бэкенд (FastAPI + Gemini) — тот же API
- 🟢 Дизайн-система (Style B) — те же цвета/шрифты
- 🟢 Бизнес-логика (BMR, TDEE, fasting) — тот же код
- 🟢 RAG-база знаний — тот же PostgreSQL + pgvector

---

## Таймлайн

```
2026 Q2 (сейчас)     → Фаза 1: HTML + Capacitor → MVP в App Store
                        Цель: 100 пользователей, валидация идеи

2026 Q3-Q4            → Фаза 2: React + Capacitor
(если 500+ MAU)         Цель: быстрые итерации, A/B тесты

2027 Q1-Q2             → Фаза 3: React Native
(если 5000+ MAU)         Цель: премиум UX, HealthKit, 60fps
```

---

> **Главное правило:** Код — это расходный материал. Пользователи, отзывы и
> product-market fit — это актив. Не оптимизируй код, пока не подтвердишь,
> что продукт нужен людям.
