/**
 * State Adapter (i18n Bridge)
 * Translates Russian UI strings to English standard keys/enums for localStorage and API,
 * and translates them back to Russian for UI hydration.
 */

const DICT_KEYS = {
    'Страна': 'country',
    'Город': 'city',
    'Главная цель': 'goal',
    'Имя': 'first_name',
    'Пол': 'gender',
    'Возраст': 'age',
    'Рост': 'height',
    'Текущий вес': 'weight',
    'Телосложение': 'body_type',
    'Обхват талии': 'waist',
    'Распределение жира': 'fat_distribution',
    'ИМТ': 'bmi',
    'Класс ИМТ': 'bmi_class',
    'BMR': 'bmr',
    'Талия/Рост': 'waist_to_height',
    'Целевой вес': 'target_weight',
    'Срок (недель)': 'target_timeline_weeks',
    'Выбранные диеты/ограничения': 'diet_restrictions',
    'Аллергии': 'allergies',
    'Симптомы': 'symptoms',
    'Хронические заболевания': 'chronic_diseases',
    'Принимает лекарства': 'takes_medication',
    'Женское здоровье': 'womens_health',
    'Принимает гормональные (КОК)': 'takes_contraceptives',
    'Интерес к голоданию': 'fasting_interest',
    'Голодание': 'fasting_pattern',
    'Сколько раз в день удобно есть?': 'meals_per_day',
    'Отбой': 'sleep_bedtime',
    'Подъем': 'sleep_waketime',
    'Режим сна': 'sleep_type',
    'Частота активности': 'activity_frequency',
    'Виды активности': 'activity_types',
    'Бюджет': 'budget',
    'Время на готовку': 'cooking_time',
    'БАД': 'takes_supplements',
    'Принимаемые витамины': 'supplement_details',
    'Отношение к БАДам': 'supplement_openness',
    'Главные барьеры прошлого': 'past_barriers',
    'Исключённые категории': 'excluded_categories',
    'Любимые продукты': 'liked_foods',
    'Нелюбимые продукты': 'disliked_foods',
    'Доп. Снижение веса': 'wants_weight_loss'
};

const DICT_VALS = {
    'Снизить вес': 'weight_loss',
    'Набрать мышечную массу': 'muscle_gain',
    'Поддерживать форму': 'maintenance',
    'Больше энергии и фокуса': 'energy',
    'Улучшить кожу и волосы': 'skin_health',
    'Наладить пищеварение': 'digestion',
    'Здоровье и долголетие': 'longevity',
    'Мужской': 'male',
    'Женский': 'female',
    'Худощавое': 'thin',
    'Среднее': 'average',
    'Крепкое': 'strong',
    'Спортивное': 'athletic',
    'Есть лишний вес': 'overweight',
    'В основном живот и талия': 'belly',
    'Бёдра и ягодицы': 'hips',
    'Равномерно по телу': 'even',
    'Затрудняюсь ответить': 'unknown',
    'Да': 'yes',
    'Нет': 'no',
    'Вегетарианство': 'vegetarian',
    'Веганство': 'vegan',
    'Пескатарианство': 'pescatarian',
    'Кето-диета': 'keto',
    'Палео-диета': 'paleo',
    'Халяль': 'halal',
    'Недостаточный': 'underweight',
    'Нормальный': 'normal',
    'Ожирение': 'obese'
    // Add more exact string maps here if needed
};

const REVERSE_KEYS = Object.fromEntries(Object.entries(DICT_KEYS).map(([k, v]) => [v, k]));
const REVERSE_VALS = Object.fromEntries(Object.entries(DICT_VALS).map(([k, v]) => [v, k]));

window.i18nAdapter = {
    toEnglishKey: (k) => DICT_KEYS[k] || k,
    toEnglishVal: (v) => {
        if (typeof v !== 'string') return v;
        return v.split(', ').map(part => DICT_VALS[part.trim()] || part.trim()).join(', ');
    },
    toRussianKey: (k) => REVERSE_KEYS[k] || k,
    toRussianVal: (v) => {
        if (typeof v !== 'string') return v;
        return v.split(', ').map(part => REVERSE_VALS[part.trim()] || part.trim()).join(', ');
    },
    
    // Convert a full Russian UI object to English DB object
    translateProfileToEnglish: (ruProfile) => {
        const enProfile = {};
        for (const [k, v] of Object.entries(ruProfile)) {
            // Ignore system keys
            if (k.startsWith('_')) { enProfile[k] = v; continue; }
            enProfile[window.i18nAdapter.toEnglishKey(k)] = window.i18nAdapter.toEnglishVal(v);
        }
        return enProfile;
    },

    // Convert a full English DB object to Russian UI object
    translateProfileToRussian: (enProfile) => {
        const ruProfile = {};
        for (const [k, v] of Object.entries(enProfile)) {
            if (k.startsWith('_')) { ruProfile[k] = v; continue; }
            ruProfile[window.i18nAdapter.toRussianKey(k)] = window.i18nAdapter.toRussianVal(v);
        }
        return ruProfile;
    }
};
