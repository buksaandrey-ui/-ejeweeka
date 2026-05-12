"""
Seed: workouts_library — 36 verified workout programs.
Hand-curated for safety. NEVER LLM-generated.

Run: python -m app.scripts.seed_workouts
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import engine, Base, SessionLocal
from app.models.workout_cache import WorkoutCache


WORKOUTS = [
    # ═══════════════════════════════════════════
    # ДОМА — НОВИЧОК
    # ═══════════════════════════════════════════
    {
        "name": "Утренняя зарядка (15 мин)", "workout_type": "bodyweight", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Мягкий старт дня: разогрев суставов, лёгкая растяжка и активация мышц.",
        "exercises": [
            {"exercise_name": "Круговые вращения руками", "sets": 2, "reps": 15, "rest_sec": 15},
            {"exercise_name": "Наклоны корпуса", "sets": 2, "reps": 12, "rest_sec": 15},
            {"exercise_name": "Приседания (без веса)", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Планка", "sets": 3, "reps": 1, "rest_sec": 30, "duration_sec": 20},
            {"exercise_name": "Мостик ягодичный", "sets": 3, "reps": 15, "rest_sec": 30},
        ],
        "safety_tags": ["без_прыжков", "без_оборудования", "для_грыжи"]
    },
    {
        "name": "Тренировка для похудения дома (25 мин)", "workout_type": "bodyweight", "target_goal": "похудение",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Круговая тренировка без оборудования для жиросжигания.",
        "exercises": [
            {"exercise_name": "Марш на месте", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 60},
            {"exercise_name": "Приседания", "sets": 3, "reps": 20, "rest_sec": 30},
            {"exercise_name": "Выпады назад (поочерёдно)", "sets": 3, "reps": 12, "rest_sec": 30},
            {"exercise_name": "Отжимания от колен", "sets": 3, "reps": 10, "rest_sec": 30},
            {"exercise_name": "Скручивания лёжа", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Берпи (облегчённый)", "sets": 3, "reps": 8, "rest_sec": 45},
        ],
        "safety_tags": ["без_оборудования"]
    },
    {
        "name": "Растяжка перед сном (15 мин)", "workout_type": "flexibility", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Мягкая растяжка для снятия напряжения и улучшения сна.",
        "exercises": [
            {"exercise_name": "Наклон к ногам сидя", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 45},
            {"exercise_name": "Поза ребёнка", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 45},
            {"exercise_name": "Скрутка лёжа", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 30},
            {"exercise_name": "Бабочка", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 45},
            {"exercise_name": "Растяжка квадрицепса стоя", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 30},
        ],
        "safety_tags": ["без_прыжков", "без_оборудования", "для_грыжи", "для_варикоза"]
    },

    # ═══════════════════════════════════════════
    # ДОМА — СРЕДНИЙ
    # ═══════════════════════════════════════════
    {
        "name": "Силовая дома с резинками (30 мин)", "workout_type": "resistance", "target_goal": "тонус",
        "difficulty_level": "средний", "location": "дома",
        "description": "Полноценная силовая тренировка с резинками для всего тела.",
        "exercises": [
            {"exercise_name": "Приседания с резинкой", "sets": 4, "reps": 15, "rest_sec": 45},
            {"exercise_name": "Тяга резинки к поясу", "sets": 4, "reps": 12, "rest_sec": 45},
            {"exercise_name": "Жим резинки от груди", "sets": 3, "reps": 12, "rest_sec": 45},
            {"exercise_name": "Разведение ног с резинкой", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Подъём на бицепс с резинкой", "sets": 3, "reps": 12, "rest_sec": 30},
        ],
        "safety_tags": ["без_прыжков"]
    },
    {
        "name": "HIIT дома (20 мин)", "workout_type": "hiit", "target_goal": "похудение",
        "difficulty_level": "средний", "location": "дома",
        "description": "Высокоинтенсивная интервальная тренировка для максимального жиросжигания.",
        "exercises": [
            {"exercise_name": "Jumping Jacks", "sets": 4, "reps": 1, "rest_sec": 15, "duration_sec": 30},
            {"exercise_name": "Берпи", "sets": 4, "reps": 1, "rest_sec": 15, "duration_sec": 30},
            {"exercise_name": "Mountain Climbers", "sets": 4, "reps": 1, "rest_sec": 15, "duration_sec": 30},
            {"exercise_name": "Прыжковые приседания", "sets": 4, "reps": 1, "rest_sec": 15, "duration_sec": 30},
            {"exercise_name": "Планка с касанием плеч", "sets": 4, "reps": 1, "rest_sec": 15, "duration_sec": 30},
        ],
        "safety_tags": []
    },
    {
        "name": "Йога для начинающих (30 мин)", "workout_type": "flexibility", "target_goal": "тонус",
        "difficulty_level": "средний", "location": "дома",
        "description": "Базовый поток виньяса-йоги для гибкости и ментального баланса.",
        "exercises": [
            {"exercise_name": "Приветствие солнцу (Сурья Намаскар)", "sets": 3, "reps": 1, "rest_sec": 0},
            {"exercise_name": "Поза воина I", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 30},
            {"exercise_name": "Поза воина II", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 30},
            {"exercise_name": "Поза дерева", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 30},
            {"exercise_name": "Шавасана", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 120},
        ],
        "safety_tags": ["без_прыжков", "без_оборудования", "для_грыжи"]
    },

    # ═══════════════════════════════════════════
    # ДОМА — ПРО
    # ═══════════════════════════════════════════
    {
        "name": "Табата 4 минуты × 4 раунда", "workout_type": "hiit", "target_goal": "похудение",
        "difficulty_level": "про", "location": "дома",
        "description": "Протокол Табата: 20 сек работа / 10 сек отдых × 8 подходов × 4 раунда.",
        "exercises": [
            {"exercise_name": "Берпи с прыжком", "sets": 8, "reps": 1, "rest_sec": 10, "duration_sec": 20},
            {"exercise_name": "Прыжки на скакалке", "sets": 8, "reps": 1, "rest_sec": 10, "duration_sec": 20},
            {"exercise_name": "Выпрыгивания из приседа", "sets": 8, "reps": 1, "rest_sec": 10, "duration_sec": 20},
            {"exercise_name": "Планка с поочерёдным подъёмом ног", "sets": 8, "reps": 1, "rest_sec": 10, "duration_sec": 20},
        ],
        "safety_tags": []
    },
    {
        "name": "Гиревая тренировка дома (40 мин)", "workout_type": "free_weights", "target_goal": "набор массы",
        "difficulty_level": "про", "location": "дома",
        "description": "Функциональная тренировка с гирей для силы и выносливости.",
        "exercises": [
            {"exercise_name": "Махи гирей (свинг)", "sets": 5, "reps": 15, "rest_sec": 60},
            {"exercise_name": "Жим гири одной рукой", "sets": 4, "reps": 10, "rest_sec": 60},
            {"exercise_name": "Турецкий подъём", "sets": 3, "reps": 5, "rest_sec": 90},
            {"exercise_name": "Рывок гири", "sets": 4, "reps": 10, "rest_sec": 60},
            {"exercise_name": "Кубковый присед", "sets": 4, "reps": 12, "rest_sec": 60},
        ],
        "safety_tags": []
    },

    # ═══════════════════════════════════════════
    # ЗАЛ — НОВИЧОК
    # ═══════════════════════════════════════════
    {
        "name": "Вводная тренировка в зале (Full Body)", "workout_type": "machines", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "зал",
        "description": "Знакомство с основными тренажёрами. Безопасно для новичков.",
        "exercises": [
            {"exercise_name": "Жим ногами в тренажёре", "sets": 3, "reps": 15, "rest_sec": 60},
            {"exercise_name": "Тяга верхнего блока", "sets": 3, "reps": 12, "rest_sec": 60},
            {"exercise_name": "Жим в тренажёре от груди", "sets": 3, "reps": 12, "rest_sec": 60},
            {"exercise_name": "Разгибание ног в тренажёре", "sets": 3, "reps": 15, "rest_sec": 45},
            {"exercise_name": "Гиперэкстензия", "sets": 3, "reps": 12, "rest_sec": 45},
        ],
        "safety_tags": ["для_грыжи", "без_прыжков"]
    },
    {
        "name": "Кардио в зале (30 мин)", "workout_type": "aerobic", "target_goal": "похудение",
        "difficulty_level": "новичок", "location": "зал",
        "description": "Чередование кардио-тренажёров для равномерной нагрузки.",
        "exercises": [
            {"exercise_name": "Эллиптический тренажёр", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 600},
            {"exercise_name": "Беговая дорожка (быстрая ходьба)", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 600},
            {"exercise_name": "Велотренажёр", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 600},
        ],
        "safety_tags": ["без_прыжков", "для_варикоза"]
    },

    # ═══════════════════════════════════════════
    # ЗАЛ — СРЕДНИЙ
    # ═══════════════════════════════════════════
    {
        "name": "Push (Грудь + Плечи + Трицепс)", "workout_type": "free_weights", "target_goal": "набор массы",
        "difficulty_level": "средний", "location": "зал",
        "description": "День «Жим» в сплите Push/Pull/Legs.",
        "exercises": [
            {"exercise_name": "Жим штанги лёжа", "sets": 4, "reps": 10, "rest_sec": 90},
            {"exercise_name": "Жим гантелей на наклонной", "sets": 3, "reps": 12, "rest_sec": 60},
            {"exercise_name": "Армейский жим стоя", "sets": 4, "reps": 10, "rest_sec": 90},
            {"exercise_name": "Разводка гантелей", "sets": 3, "reps": 12, "rest_sec": 45},
            {"exercise_name": "Французский жим", "sets": 3, "reps": 12, "rest_sec": 45},
        ],
        "safety_tags": []
    },
    {
        "name": "Pull (Спина + Бицепс)", "workout_type": "free_weights", "target_goal": "набор массы",
        "difficulty_level": "средний", "location": "зал",
        "description": "День «Тяга» в сплите Push/Pull/Legs.",
        "exercises": [
            {"exercise_name": "Становая тяга", "sets": 4, "reps": 8, "rest_sec": 120},
            {"exercise_name": "Тяга штанги в наклоне", "sets": 4, "reps": 10, "rest_sec": 90},
            {"exercise_name": "Тяга верхнего блока узким хватом", "sets": 3, "reps": 12, "rest_sec": 60},
            {"exercise_name": "Подъём на бицепс с гантелями", "sets": 3, "reps": 12, "rest_sec": 45},
            {"exercise_name": "Молотки", "sets": 3, "reps": 12, "rest_sec": 45},
        ],
        "safety_tags": []
    },
    {
        "name": "Legs (Ноги + Ягодицы)", "workout_type": "free_weights", "target_goal": "набор массы",
        "difficulty_level": "средний", "location": "зал",
        "description": "День ног в сплите Push/Pull/Legs.",
        "exercises": [
            {"exercise_name": "Приседания со штангой", "sets": 4, "reps": 10, "rest_sec": 120},
            {"exercise_name": "Румынская тяга", "sets": 4, "reps": 12, "rest_sec": 90},
            {"exercise_name": "Жим ногами", "sets": 3, "reps": 15, "rest_sec": 60},
            {"exercise_name": "Разгибание ног в тренажёре", "sets": 3, "reps": 15, "rest_sec": 45},
            {"exercise_name": "Подъём на носки стоя", "sets": 4, "reps": 20, "rest_sec": 30},
        ],
        "safety_tags": []
    },

    # ═══════════════════════════════════════════
    # ЗАЛ — ПРО
    # ═══════════════════════════════════════════
    {
        "name": "Силовой максимум (Powerlifting)", "workout_type": "free_weights", "target_goal": "набор массы",
        "difficulty_level": "про", "location": "зал",
        "description": "Тяжёлая силовая: жим, присед, тяга — работа на максимум.",
        "exercises": [
            {"exercise_name": "Приседания со штангой", "sets": 5, "reps": 5, "rest_sec": 180},
            {"exercise_name": "Жим штанги лёжа", "sets": 5, "reps": 5, "rest_sec": 180},
            {"exercise_name": "Становая тяга", "sets": 5, "reps": 3, "rest_sec": 180},
            {"exercise_name": "Подтягивания с весом", "sets": 4, "reps": 8, "rest_sec": 120},
        ],
        "safety_tags": []
    },

    # ═══════════════════════════════════════════
    # УЛИЦА — НОВИЧОК
    # ═══════════════════════════════════════════
    {
        "name": "Прогулка быстрым шагом (30 мин)", "workout_type": "aerobic", "target_goal": "похудение",
        "difficulty_level": "новичок", "location": "улица",
        "description": "Быстрая ходьба 5-6 км/ч — базовое кардио для жиросжигания.",
        "exercises": [
            {"exercise_name": "Быстрая ходьба", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 1800},
        ],
        "safety_tags": ["без_прыжков", "для_грыжи", "для_варикоза", "для_подагры"]
    },
    {
        "name": "Скандинавская ходьба (40 мин)", "workout_type": "aerobic", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "улица",
        "description": "Ходьба с палками — задействует 90% мышц тела, щадит суставы.",
        "exercises": [
            {"exercise_name": "Скандинавская ходьба", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 2400},
        ],
        "safety_tags": ["без_прыжков", "для_грыжи", "для_варикоза", "для_подагры", "для_пожилых"]
    },

    # ═══════════════════════════════════════════
    # УЛИЦА — СРЕДНИЙ
    # ═══════════════════════════════════════════
    {
        "name": "Интервальный бег (25 мин)", "workout_type": "aerobic", "target_goal": "похудение",
        "difficulty_level": "средний", "location": "улица",
        "description": "Чередование бега и ходьбы для улучшения выносливости.",
        "exercises": [
            {"exercise_name": "Разминочная ходьба", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 180},
            {"exercise_name": "Бег 2 мин / Ходьба 1 мин (повторить 7 раз)", "sets": 7, "reps": 1, "rest_sec": 60, "duration_sec": 120},
            {"exercise_name": "Заминка (ходьба)", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 180},
        ],
        "safety_tags": []
    },
    {
        "name": "Воркаут на турниках (30 мин)", "workout_type": "bodyweight", "target_goal": "набор массы",
        "difficulty_level": "средний", "location": "улица",
        "description": "Уличная силовая тренировка на турниках и брусьях.",
        "exercises": [
            {"exercise_name": "Подтягивания (средний хват)", "sets": 4, "reps": 8, "rest_sec": 90},
            {"exercise_name": "Отжимания на брусьях", "sets": 4, "reps": 10, "rest_sec": 90},
            {"exercise_name": "Подъём ног в висе", "sets": 3, "reps": 12, "rest_sec": 60},
            {"exercise_name": "Австралийские подтягивания", "sets": 3, "reps": 12, "rest_sec": 60},
        ],
        "safety_tags": []
    },

    # ═══════════════════════════════════════════
    # СПЕЦИАЛЬНЫЕ (для ограничений)
    # ═══════════════════════════════════════════
    {
        "name": "Тренировка при грыже поясницы", "workout_type": "rehabilitation", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Безопасная тренировка для укрепления спины без осевой нагрузки.",
        "exercises": [
            {"exercise_name": "Кошка-корова", "sets": 3, "reps": 10, "rest_sec": 30},
            {"exercise_name": "Ягодичный мостик", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Вакуум живота", "sets": 3, "reps": 10, "rest_sec": 30},
            {"exercise_name": "Подъём руки и ноги на четвереньках", "sets": 3, "reps": 10, "rest_sec": 30},
            {"exercise_name": "Планка на локтях (20 сек)", "sets": 3, "reps": 1, "rest_sec": 30, "duration_sec": 20},
        ],
        "safety_tags": ["для_грыжи", "без_прыжков", "без_осевой_нагрузки"]
    },
    {
        "name": "Тренировка при варикозе", "workout_type": "rehabilitation", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Улучшение венозного оттока без нагрузки на ноги стоя.",
        "exercises": [
            {"exercise_name": "Велосипед лёжа", "sets": 3, "reps": 20, "rest_sec": 30},
            {"exercise_name": "Ножницы лёжа", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Подъём ног лёжа", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Растяжка икроножных (сидя)", "sets": 2, "reps": 1, "rest_sec": 0, "duration_sec": 30},
        ],
        "safety_tags": ["для_варикоза", "без_прыжков", "без_оборудования"]
    },
    {
        "name": "Тренировка для пожилых (60+)", "workout_type": "rehabilitation", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Мягкая тренировка для поддержания подвижности и профилактики саркопении.",
        "exercises": [
            {"exercise_name": "Приседания на стул", "sets": 3, "reps": 10, "rest_sec": 45},
            {"exercise_name": "Отжимания от стены", "sets": 3, "reps": 10, "rest_sec": 45},
            {"exercise_name": "Подъём на носки (у опоры)", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Шаги на месте с подъёмом колен", "sets": 2, "reps": 1, "rest_sec": 30, "duration_sec": 60},
            {"exercise_name": "Растяжка стоя (у стены)", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 60},
        ],
        "safety_tags": ["для_пожилых", "без_прыжков", "без_оборудования", "для_грыжи", "для_варикоза"]
    },
    {
        "name": "Тренировка при подагре", "workout_type": "aerobic", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Низкоинтенсивное кардио для улучшения метаболизма мочевой кислоты.",
        "exercises": [
            {"exercise_name": "Ходьба на месте", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 300},
            {"exercise_name": "Плавные круговые движения суставами", "sets": 2, "reps": 10, "rest_sec": 20},
            {"exercise_name": "Растяжка стоя", "sets": 1, "reps": 1, "rest_sec": 0, "duration_sec": 120},
        ],
        "safety_tags": ["для_подагры", "без_прыжков", "без_оборудования"]
    },
    {
        "name": "Пренатальная тренировка (беременность)", "workout_type": "rehabilitation", "target_goal": "тонус",
        "difficulty_level": "новичок", "location": "дома",
        "description": "Безопасная тренировка для беременных (2-3 триместр). Укрепление таза и спины.",
        "exercises": [
            {"exercise_name": "Упражнения Кегеля", "sets": 3, "reps": 15, "rest_sec": 30},
            {"exercise_name": "Кошка-корова", "sets": 3, "reps": 10, "rest_sec": 20},
            {"exercise_name": "Ягодичный мостик", "sets": 3, "reps": 12, "rest_sec": 30},
            {"exercise_name": "Приседания (широкая стойка, у опоры)", "sets": 3, "reps": 10, "rest_sec": 45},
            {"exercise_name": "Боковые подъёмы ног лёжа", "sets": 3, "reps": 12, "rest_sec": 30},
        ],
        "safety_tags": ["для_беременных", "без_прыжков", "без_оборудования", "без_осевой_нагрузки", "без_пресса"]
    },
]


def main():
    Base.metadata.create_all(bind=engine, tables=[WorkoutCache.__table__])
    db = SessionLocal()
    try:
        added = 0
        skipped = 0
        for w in WORKOUTS:
            existing = db.query(WorkoutCache).filter(WorkoutCache.name == w['name']).first()
            if existing:
                skipped += 1
                continue
            db.add(WorkoutCache(**w))
            added += 1
        db.commit()
        total = db.query(WorkoutCache).count()
        print(f"✅ Workouts seed: +{added} added, {skipped} skipped. Total: {total}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
