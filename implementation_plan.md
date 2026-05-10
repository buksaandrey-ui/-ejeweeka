# Сквозной архитектурный патч и исправление багов

Этот план охватывает системное устранение всех семи заявленных проблем и их аналогов по всей кодовой базе (UI, навигация, валидация, сохранение состояния).

## User Review Required
> [!IMPORTANT]
> **Маршрутизация O-2.5 (Характер НС)**
> Экран перемещается в конец онбординга. Теперь после "O-15 (Предпочтения)" пользователь попадёт на "O-15.5 (Характер наставника)", а затем на "O-16 (Сводка)". Устраивает ли такой порядок?

> [!IMPORTANT]
> **Дефолт "Нет анализов" (O-12)**
> Если мы делаем "Нет анализов" выбранным по умолчанию, кнопка "Далее" будет активна сразу. Если пользователь случайно проскроллит и нажмёт "Далее", он пропустит ввод анализов. Подтверждаешь этот UX-паттерн для ускорения воронки?

## Классификация паттернов (Шаг 1)

1. **Overflow-паттерн (Layout):** Экран не адаптирован под появление клавиатуры без `SingleChildScrollView`.
2. **Паттерн потери стейта (State Persistence):** Неполная/асинхронная инициализация при выборе сложных радио-кнопок без дефолтных значений вложенных полей.
3. **Паттерн хардкода навигации (Routing):** `onBack` и `onNext` игнорируют условные экраны (например, `wants_to_lose_weight` из O-3, который должен открывать O-4).
4. **Паттерн неполной валидации (Validation):** Чекбокс "включает" текстовое поле, но валидатор не проверяет его заполненность (лекарства).
5. **Паттерн терминологии (Compliance):** Использование "ИИ" / "AI" вместо "НС", "Ассистент" вместо "Наставник".
6. **Паттерн избыточных данных (UX/UI):** Показ технических метрик (коэффициент активности) или дублирование базового обмена в разных блоках сводки.

## Proposed Changes (Шаг 2 & 3)

### Навигация и Экран "Характер НС"

#### [MODIFY] [o2_goal_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o2_goal_screen.dart)
- Удаление перехода на `O-2.5`. Переход будет сразу на `O-3 Profile`.

#### [MODIFY] [o15_food_prefs_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o15_food_prefs_screen.dart)
- Изменение перехода с `O-16` на экран `O-2.5 AI Personality` (будет выступать как шаг 15.5).

#### [MODIFY] [o2_5_ai_personality_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o2_5_ai_personality_screen.dart)
- **Терминология:** "Выбери характер ИИ" -> "Выбери характер наставника".
- **Терминология:** "Как ассистенту с тобой общаться?" -> "Как нейросети с тобой общаться?".
- **Навигация:** Кнопка "Назад" ведёт на `O-15 Food Prefs`. "Далее" ведёт на `O-16 Summary`.

---

### UI, Layout и Валидация

#### [MODIFY] [o0_welcome_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o0_welcome_screen.dart)
- Обернуть основной контент в `SingleChildScrollView` или добавить `resizeToAvoidBottomInset: false` в Scaffold, чтобы убрать желто-черные полосы overflow при вводе промокода.

#### [MODIFY] [o5_restrictions_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o5_restrictions_screen.dart)
- Исправление кнопки "Назад": вместо хардкода `profile.goal == 'weight_loss'` использовать `profile.goal == 'weight_loss' || profile.wantsToLoseWeight == true`.

#### [MODIFY] [o6_health_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o6_health_screen.dart)
- Добавление listener'a на текстовое поле "лекарства". Если чекбокс активен, кнопка "Далее" заблокирована, пока текстовое поле пустое.

#### [MODIFY] [o7_womens_health_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o7_womens_health_screen.dart)
- Аналогично O-6, строгая валидация обязательного ввода названия препарата, если стоит чекбокс.

---

### Данные: Сохранение и Сводка

#### [MODIFY] [o8_meal_pattern_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o8_meal_pattern_screen.dart)
- При выборе "Да, практикую" переменной `_fastingKind` будет присваиваться дефолтное значение `'daily'`, чтобы избежать сохранения `fastingType: 'none'` и сброса данных при возврате.

#### [MODIFY] [o12_blood_tests_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o12_blood_tests_screen.dart)
- В `initState` по умолчанию `_hasTests` будет установлено в `false` (вместо `null`), чтобы кнопка "Далее" была активна сразу (если пользователь не хочет вводить анализы).

#### [MODIFY] [o16_summary_screen.dart](file:///Users/andreybuksa/Downloads/aidiet-docs/health_code/lib/features/onboarding/presentation/o16_summary_screen.dart)
- **Дубликаты:** Удаление строки `Базовый обмен` из блока "Профиль", так как он дублируется в графическом блоке "Твои расчёты".
- **Коэффициенты:** Удаление технического значения `Коэффициент` (e.g., ×1.600) из блока "Активность".
- **Голодание:** Проверка маппинга стейта голодания с учетом исправлений O-8.

## Verification Plan
1. `flutter analyze` для проверки null-safety и синтаксиса.
2. `flutter run` с Hot Reload в текущем симуляторе (PID уже запущен).
3. Прогон сценариев: 
   - Заполнение экрана Сна и Голодания -> Нажатие "Назад" -> Данные не обнуляются.
   - Чекбокс лекарств на O-7 без текста -> "Далее" неактивна.
   - Экран Welcome -> Вызов клавиатуры не вызывает overflow.
   - Доход до O-15 -> Переход к "Характеру наставника" -> Переход к сводке.
