"""
Генератор 100 уникальных тестовых профилей для E2E тестирования ejeweeka.
Матрица: цели × пол × регион × аллергии × болезни × ограничения × бюджет × fasting × batch_cooking × возраст
"""

from app.api.plan import UserProfilePayload
from typing import List

# ═══════════════════════════════════════════════════════════════
# МАТРИЦА ПАРАМЕТРОВ
# ═══════════════════════════════════════════════════════════════

GOALS = [
    "Снизить вес", "Набрать мышечную массу", "Поддержание веса",
    "Улучшить самочувствие и энергию", "Питание при ограничениях по здоровью",
    "Восстановление после болезни/стресса", "Питание для кожи, ногтей, волос",
    "Адаптировать питание к возрасту", "Снизить тягу к сладкому и голод",
]

REGIONS = [
    {"country": "Россия", "city": "Москва"},
    {"country": "ОАЭ", "city": "Дубай"},
    {"country": "Таиланд", "city": "Бангкок"},
    {"country": "Турция", "city": "Стамбул"},
    {"country": "Израиль", "city": "Тель-Авив"},
]

ALLERGY_SETS = [
    [],
    ["Орехи"],
    ["Лактоза"],
    ["Глютен"],
    ["Рыба", "Морепродукты"],
    ["Орехи", "Соя"],
]

DISEASE_SETS = [
    [],
    ["Гипертония"],
    ["Диабет 2 типа"],
    ["Подагра"],
    ["Гастрит"],
    ["СПКЯ"],  # женское
]

RESTRICTION_SETS = [
    [],
    ["Веганство"],
    ["Халяль"],
    ["Кошерное"],
    ["Пескетарианство"],
    ["Без молочки"],
    ["Без глютена", "Без лактозы"],
]

FASTING_CONFIGS = [
    {"fasting_type": "none"},
    {"fasting_type": "daily", "daily_format": "16:8", "daily_start": "12:00",
     "daily_window_end": "20:00", "daily_meals": 3},
    {"fasting_type": "periodic", "periodic_format": "5:2", "periodic_freq": "2 дня в неделю",
     "periodic_days": [1, 4], "periodic_start": "20:00"},
]

BATCH_CONFIGS = [
    {"cooking_style": "daily", "shopping_frequency": "few_days"},
    {"cooking_style": "batch_2_3_days", "shopping_frequency": "few_days"},
    {"cooking_style": "batch_weekly", "shopping_frequency": "weekly"},
]

BUDGET_LEVELS = ["Экономный", "Средний", "Без разницы"]


def generate_100_profiles() -> List[UserProfilePayload]:
    """Генерирует 100 уникальных тестовых профилей."""
    profiles = []
    idx = 0

    # ═══ БЛОК 1: Систематическая матрица (63 профиля) ═══
    # 9 целей × 7 комбинаций ограничений = 63 ключевых профиля
    for goal_idx, goal in enumerate(GOALS):
        for rest_idx, restrictions in enumerate(RESTRICTION_SETS):
            gender = "female" if (goal_idx + rest_idx) % 2 == 0 else "male"
            region = REGIONS[(goal_idx + rest_idx) % len(REGIONS)]
            allergies = ALLERGY_SETS[(goal_idx + rest_idx) % len(ALLERGY_SETS)]
            diseases = DISEASE_SETS[(goal_idx + rest_idx) % len(DISEASE_SETS)]
            fasting = FASTING_CONFIGS[(goal_idx + rest_idx) % len(FASTING_CONFIGS)]
            batch = BATCH_CONFIGS[(goal_idx + rest_idx) % len(BATCH_CONFIGS)]
            budget = BUDGET_LEVELS[(goal_idx + rest_idx) % len(BUDGET_LEVELS)]
            age = 25 + (goal_idx * 5) + rest_idx  # 25-73

            # Женское здоровье только для female
            womens_health = None
            if gender == "female" and diseases and "СПКЯ" in diseases:
                womens_health = ["СПКЯ"]

            p = UserProfilePayload(
                age=min(age, 75),
                gender=gender,
                weight=55 + idx * 1.5,
                height=155 + (idx % 30),
                target_weight=(55 + idx * 1.5 - 10) if "Снизить" in goal else None,
                target_timeline_weeks=12 if "Снизить" in goal else None,
                goal=goal,
                activity_level="2-3 раза в неделю",
                country=region["country"],
                city=region["city"],
                allergies=allergies,
                diseases=diseases,
                restrictions=restrictions,
                budget_level=budget,
                cooking_time="До 30 мин",
                meal_pattern="3 приема (завтрак, обед, ужин)" if fasting.get("fasting_type") == "none" else "4 приема",
                fasting_type=fasting.get("fasting_type"),
                daily_format=fasting.get("daily_format"),
                daily_start=fasting.get("daily_start"),
                daily_window_end=fasting.get("daily_window_end"),
                daily_meals=fasting.get("daily_meals"),
                periodic_format=fasting.get("periodic_format"),
                periodic_freq=fasting.get("periodic_freq"),
                periodic_days=fasting.get("periodic_days", []),
                periodic_start=fasting.get("periodic_start"),
                cooking_style=batch.get("cooking_style"),
                shopping_frequency=batch.get("shopping_frequency"),
                training_schedule="2-3 раза в неделю" if "Набрать" in goal else "Без регулярных тренировок",
                training_days=3 if "Набрать" in goal else 0,
                workout_location="Дома",
                disliked_foods=["Грибы", "Баклажаны"] if idx % 5 == 0 else [],
                liked_foods=["Курица", "Рис"] if idx % 3 == 0 else [],
                womens_health=womens_health,
                tier="T1",
            )
            profiles.append(p)
            idx += 1
            if idx >= 63:
                break
        if idx >= 63:
            break

    # ═══ БЛОК 2: Критические краевые случаи (37 профилей) ═══

    # EC-01: Беременная веганка с аллергией на орехи
    profiles.append(UserProfilePayload(
        age=30, gender="female", weight=65, height=165, goal="Поддержание веса",
        activity_level="1 раз", country="Россия", city="Москва",
        allergies=["Орехи"], restrictions=["Веганство"],
        womens_health=["Беременность (2-й триместр)"],
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-02: 65-летний мужчина с подагрой + диабетом, экономный бюджет
    profiles.append(UserProfilePayload(
        age=65, gender="male", weight=95, height=175, goal="Снизить вес",
        target_weight=85, target_timeline_weeks=24,
        activity_level="Сидячий", country="Россия", city="Самара",
        diseases=["Подагра", "Диабет 2 типа"], allergies=[],
        budget_level="Экономный", cooking_time="До 15 мин", tier="T1",
    ))

    # EC-03: Женщина на ГВ в Таиланде с непереносимостью лактозы
    profiles.append(UserProfilePayload(
        age=28, gender="female", weight=70, height=162, goal="Снизить вес",
        target_weight=60, target_timeline_weeks=16,
        activity_level="1 раз", country="Таиланд", city="Пхукет",
        allergies=["Лактоза"], womens_health=["Грудное вскармливание"],
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-04: Мужчина muscle_gain БЕЗ тренировок (должен получить предупреждение)
    profiles.append(UserProfilePayload(
        age=25, gender="male", weight=70, height=180, goal="Набрать мышечную массу",
        activity_level="Сидячий", country="Россия", city="Москва",
        training_schedule="Без регулярных тренировок", training_days=0,
        cooking_time="До 15 мин", budget_level="Средний", tier="T1",
    ))

    # EC-05: Пользователь с 5+ disliked + 3 аллергии + халяль
    profiles.append(UserProfilePayload(
        age=35, gender="male", weight=80, height=178, goal="Поддержание веса",
        activity_level="2-3 раза", country="ОАЭ", city="Дубай",
        allergies=["Орехи", "Рыба", "Соя"],
        restrictions=["Халяль"],
        disliked_foods=["Грибы", "Баклажаны", "Свекла", "Тыква", "Кабачки"],
        cooking_time="До 30 мин", budget_level="Без разницы", tier="T1",
    ))

    # EC-06: Беременная с гипертонией на метформине
    profiles.append(UserProfilePayload(
        age=38, gender="female", weight=85, height=168, goal="Питание при ограничениях по здоровью",
        activity_level="Сидячий", country="Россия", city="СПб",
        diseases=["Гипертония"], medications="Метформин",
        womens_health=["Беременность (3-й триместр)"],
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-07: 70-летний мужчина с почечной недостаточностью
    profiles.append(UserProfilePayload(
        age=70, gender="male", weight=75, height=172, goal="Питание при ограничениях по здоровью",
        activity_level="Сидячий", country="Россия", city="Казань",
        diseases=["Хроническая почечная недостаточность"],
        medications="Эналаприл", cooking_time="До 30 мин",
        budget_level="Экономный", tier="T1",
    ))

    # EC-08: Женщина в менопаузе, skin_hair_nails, Израиль
    profiles.append(UserProfilePayload(
        age=52, gender="female", weight=68, height=164, goal="Питание для кожи, ногтей, волос",
        activity_level="1 раз", country="Израиль", city="Тель-Авив",
        womens_health=["Менопауза"], restrictions=["Кошерное"],
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-09: Интервальное голодание 20:4 + силовые + muscle_gain
    profiles.append(UserProfilePayload(
        age=28, gender="male", weight=85, height=185, goal="Набрать мышечную массу",
        activity_level="4-5 раз", country="Россия", city="Москва",
        fasting_type="daily", daily_format="20:4", daily_start="14:00",
        daily_window_end="18:00", daily_meals=2,
        training_schedule="5 раз в неделю", training_days=5,
        activity_types=["Силовые тренировки", "Тренажёрный зал"],
        workout_location="Зал",
        cooking_time="До 30 мин", budget_level="Без разницы", tier="T2",
    ))

    # EC-10: Периодическое голодание 5:2 + экономный + batch_weekly
    profiles.append(UserProfilePayload(
        age=40, gender="female", weight=78, height=168, goal="Снизить вес",
        target_weight=68, target_timeline_weeks=20,
        activity_level="1 раз", country="Турция", city="Анталья",
        fasting_type="periodic", periodic_format="5:2",
        periodic_freq="2 дня в неделю", periodic_days=[1, 4],
        periodic_start="20:00",
        cooking_style="batch_weekly", shopping_frequency="weekly",
        cooking_time="До 30 мин", budget_level="Экономный", tier="T1",
    ))

    # EC-11: Веган с дефицитом B12 и железа (анализы)
    profiles.append(UserProfilePayload(
        age=32, gender="female", weight=58, height=165, goal="Улучшить самочувствие и энергию",
        activity_level="2-3 раза", country="Россия", city="Москва",
        restrictions=["Веганство"],
        blood_tests='{"vitamin_d": 15, "ferritin": 8, "b12": 180}',
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-12: Болезнь Крона + пескетарианство
    profiles.append(UserProfilePayload(
        age=45, gender="male", weight=72, height=178, goal="Питание при ограничениях по здоровью",
        activity_level="1 раз", country="Россия", city="Нижний Новгород",
        diseases=["Болезнь Крона"], restrictions=["Пескетарианство"],
        cooking_time="До 15 мин", budget_level="Средний", tier="T1",
    ))

    # EC-13: СПКЯ + кето-подобное (без глютена + без сахара)
    profiles.append(UserProfilePayload(
        age=29, gender="female", weight=72, height=163, goal="Снизить вес",
        target_weight=62, target_timeline_weeks=16,
        activity_level="2-3 раза", country="Россия", city="Екатеринбург",
        diseases=["СПКЯ"], womens_health=["СПКЯ"],
        restrictions=["Без глютена"],
        disliked_foods=["Сахар", "Белый хлеб", "Конфеты"],
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-14: На варфарине (контроль витамина K)
    profiles.append(UserProfilePayload(
        age=60, gender="male", weight=80, height=175, goal="Поддержание веса",
        activity_level="Сидячий", country="Россия", city="Москва",
        medications="Варфарин",
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # EC-15: На л-тироксине (щитовидка)
    profiles.append(UserProfilePayload(
        age=35, gender="female", weight=65, height=165, goal="Снизить вес",
        target_weight=58, target_timeline_weeks=16,
        activity_level="1 раз", country="Россия", city="Москва",
        medications="Л-тироксин 75мкг",
        cooking_time="До 30 мин", budget_level="Средний", tier="T1",
    ))

    # Дополнительные до 100
    while len(profiles) < 100:
        extra_idx = len(profiles) - 63
        gender = "female" if extra_idx % 2 == 0 else "male"
        region = REGIONS[extra_idx % len(REGIONS)]
        profiles.append(UserProfilePayload(
            age=30 + extra_idx,
            gender=gender,
            weight=65 + extra_idx,
            height=165 + (extra_idx % 20),
            goal=GOALS[extra_idx % len(GOALS)],
            activity_level="2-3 раза",
            country=region["country"],
            city=region["city"],
            budget_level=BUDGET_LEVELS[extra_idx % len(BUDGET_LEVELS)],
            cooking_time="До 30 мин",
            tier="T1",
        ))

    return profiles[:100]


def get_profile_description(p: UserProfilePayload) -> str:
    """Человекочитаемое описание профиля для отчёта."""
    parts = [
        f"{p.gender}/{p.age}лет/{p.weight}кг",
        f"Цель: {p.goal}",
        f"Регион: {p.country}",
    ]
    if p.allergies:
        parts.append(f"Аллергии: {', '.join(p.allergies)}")
    if p.diseases:
        parts.append(f"Болезни: {', '.join(p.diseases)}")
    if p.effective_restrictions:
        parts.append(f"Ограничения: {', '.join(p.effective_restrictions)}")
    if p.disliked_foods:
        parts.append(f"Не любит: {', '.join(p.disliked_foods)}")
    if p.fasting_type and p.fasting_type != 'none':
        parts.append(f"Голодание: {p.fasting_type}")
    if p.womens_health:
        parts.append(f"Жен.здоровье: {', '.join(p.womens_health)}")
    if p.medications and p.medications != 'Нет':
        parts.append(f"Лекарства: {p.medications}")
    return " | ".join(parts)
