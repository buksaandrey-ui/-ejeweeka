# ejeweeka — Реестр параметров персонализации (SSOT)

> **Источник**: `profile_model.dart` — UserProfile class
> **Дата фиксации**: 2026-05-06
> **Итого: 67 пользовательских параметров** (без системных)

---

## O-1 · Геолокация (2)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 1 | `country` | Страна | `String` |
| 2 | `city` | Город | `String` |

## O-2 · Цель (3)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 3 | `goal` | Основная цель | `String` (enum) |
| 4 | `wants_to_lose_weight` | Хочет похудеть | `bool` |
| 5 | `weight_loss_details` | Детали похудения | `String` |

## O-3 · Антропометрия (10)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 6 | `name` | Имя | `String` |
| 7 | `gender` | Пол | `male / female` |
| 8 | `age` | Возраст | `int` |
| 9 | `height` | Рост (см) | `double` |
| 10 | `weight` | Вес (кг) | `double` |
| 11 | `bmi` | ИМТ (расчётный) | `double` |
| 12 | `bmi_class` | Класс ИМТ | `underweight / normal / overweight / obese` |
| 13 | `bmr` | BMR (расчётный) | `double` |
| 14 | `waist` | Обхват талии (см) | `double` |
| 15 | `body_type` | Тип телосложения | `String` |
| 16 | `fat_distribution` | Распределение жира | `String` |

## O-4 · Целевой вес и темп (5)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 17 | `target_weight` | Целевой вес (кг) | `double` |
| 18 | `target_timeline_weeks` | Срок достижения (нед) | `int` |
| 19 | `pace_classification` | Классификация темпа | `String` |
| 20 | `speed_priority` | Приоритет скорости | `String` |
| 21 | `target_date` | Целевая дата | `String` (ISO) |

## O-5 · Диеты и аллергии (3)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 22 | `diets` | Диетические предпочтения | `List<String>` |
| 23 | `has_allergies` | Есть аллергии | `bool` |
| 24 | `allergies` | Список аллергенов | `List<String>` |

## O-6 · Медицинский контекст (6)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 25 | `symptoms` | Симптомы | `List<String>` |
| 26 | `diseases` | Заболевания | `List<String>` |
| 27 | `medications` | Лекарства (текст) | `String` |
| 28 | `takes_medications` | Принимает лекарства | `yes / no` |
| 29 | `takes_contraceptives` | Контрацептивы | `String` |
| 30 | `custom_condition` | Прочие состояния | `String` |

## O-7 · Женское здоровье (1)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 31 | `womens_health` | Женское здоровье | `List<String>` |

## O-8 · Режим питания и голодание (10)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 32 | `meal_pattern` | Паттерн питания | `String` |
| 33 | `fasting_type` | Тип голодания | `String` |
| 34 | `fasting_state` | Состояние голодания | `String` |
| 35 | `daily_format` | Формат ежедневного IF | `String` |
| 36 | `daily_start` | Начало окна питания | `String` |
| 37 | `daily_meals` | Приёмы пищи в день | `int` |
| 38 | `daily_window_end` | Конец окна питания | `String` |
| 39 | `periodic_format` | Формат периодич. IF | `String` |
| 40 | `periodic_freq` | Частота IF | `String` |
| 41 | `periodic_days` | Дни IF | `List<int>` |

## O-9 · Сон (4)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 42 | `bedtime` | Время отхода ко сну | `String` |
| 43 | `wakeup_time` | Время пробуждения | `String` |
| 44 | `sleep_pattern` | Паттерн сна | `String` |
| 45 | `sleep_duration_hours` | Длительность сна (ч) | `double` |

## O-10 · Активность и тренировки (9)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 46 | `activity_level` | Уровень активности | `String` |
| 47 | `activity_duration` | Длительность тренировки | `30/45/60/90min` |
| 48 | `activity_types` | Типы активности | `List<String>` |
| 49 | `activity_multiplier` | Множитель TDEE | `double` |
| 50 | `fitness_level` | Уровень подготовки | `String` |
| 51 | `workout_location` | Место тренировки | `String` |
| 52 | `equipment` | Оборудование | `List<String>` |
| 53 | `physical_limitations` | Физ. ограничения | `List<String>` |
| 54 | `training_days` | Дней тренировок/нед | `int` |

## O-11 · Бюджет и готовка (4)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 55 | `budget_level` | Уровень бюджета | `String` |
| 56 | `cooking_style` | Стиль готовки | `daily/batch/none` |
| 57 | `cooking_time` | Время на готовку | `String` |
| 58 | `shopping_frequency` | Частота покупок | `String` |

## O-12 · Анализы крови (2)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 59 | `has_blood_tests` | Есть анализы | `bool` |
| 60 | `blood_tests` | Данные анализов | `String` |

## O-13 · Добавки и витамины (3)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 61 | `currently_takes_supplements` | Принимает добавки | `bool` |
| 62 | `supplements` | Список добавок | `String` |
| 63 | `supplement_openness` | Открытость к добавкам | `String` |

## O-14 · Мотивация (1)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 64 | `motivation_barriers` | Барьеры мотивации | `List<String>` |

## O-15 · Вкусовые предпочтения (3)

| # | Ключ | Перевод | Тип |
|---|---|---|---|
| 65 | `liked_foods` | Любимые продукты | `List<String>` |
| 66 | `disliked_foods` | Нелюбимые продукты | `List<String>` |
| 67 | `excluded_meal_types` | Исключённые типы блюд | `List<String>` |

---

## Расчётные/системные (10)

| Ключ | Перевод |
|---|---|
| `periodic_start` | Старт периодического IF |
| `bmr_kcal` | BMR (ккал) |
| `target_daily_calories` | Целевые калории/день |
| `target_daily_fiber` | Целевая клетчатка |
| `tdee_calculated` | TDEE |
| `waist_to_height_ratio` | Талия/рост |
| `ai_personality` | Стиль AI |
| `selected_theme` | Тема оформления |
| `subscription_status` | Статус |
| `chosen_status` | Выбранный статус |

---

**Итого**: 67 пользовательских + 10 расчётных = **77 параметров**.
Маркетинг: **60+ параметров** (консервативно) или **75+** (с расчётными).
