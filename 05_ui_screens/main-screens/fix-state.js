const fs = require('fs');
let content = fs.readFileSync('onboarding-state.js', 'utf8');

const injection = `
// ==========================================
// i18n Adapter: Russian to English keys/values
// ==========================================
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
    'Доп. Снижение веса': 'wants_weight_loss',
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
    'Длительность сна (мин)': 'sleep_duration_mins',
    'Тип смен': 'shift_type',
    'Средний сон (ч)': 'avg_sleep_hours',
    'Частота активности': 'activity_frequency',
    'Виды активности': 'activity_types',
    'Длительность тренировки': 'activity_duration',
    'Бюджет': 'budget',
    'Время на готовку': 'cooking_time',
    'Анализы': 'blood_tests',
    'БАД': 'takes_supplements',
    'Принимаемые витамины': 'supplement_details',
    'Отношение к БАДам': 'supplement_openness',
    'Главные барьеры прошлого': 'past_barriers',
    'Исключённые категории': 'excluded_categories',
    'Любимые продукты': 'liked_foods',
    'Нелюбимые продукты': 'disliked_foods',
    // Screen titles mapping for choice cards
    'Привычки': 'fasting_pattern',
    'Активность': 'activity_frequency'
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
    'Да': 'yes',
    'Нет': 'no',
    'Вегетарианство': 'vegetarian',
    'Веганство': 'vegan',
    'Пескатарианство': 'pescatarian',
    'Кето-диета': 'keto',
    'Палео-диета': 'paleo',
    'Халяль': 'halal',
    'Эконом': 'economy',
    'Средний': 'medium',
    'Премиум': 'premium'
};

const REVERSE_KEYS = Object.fromEntries(Object.entries(DICT_KEYS).map(([k, v]) => [v, k]));
const REVERSE_VALS = Object.fromEntries(Object.entries(DICT_VALS).map(([k, v]) => [v, k]));

window.i18n = {
    toEnKey: (k) => DICT_KEYS[k] || k,
    toEnVal: (v) => {
        if (typeof v !== 'string') return v;
        return v.split(', ').map(p => DICT_VALS[p.trim()] || p.trim()).join(', ');
    },
    toRuKey: (k) => REVERSE_KEYS[k] || k,
    toRuVal: (v) => {
        if (typeof v !== 'string') return v;
        return v.split(', ').map(p => REVERSE_VALS[p.trim()] || p.trim()).join(', ');
    }
};
// ==========================================
`;

if (!content.includes('i18n Adapter')) {
    content = injection + '\n' + content;
}

// Intercept saveField to translate to English
content = content.replace(
    'profile[key] = value;',
    'profile[window.i18n.toEnKey(key)] = window.i18n.toEnVal(value);'
);

// In hydrateUI, translate screenQuestion to English so it correctly looks up the English key for choice cards
content = content.replace(
    'let screenQuestion = document.querySelector(\'.question-title, h1\')?.innerText.trim();',
    'let screenQuestionRaw = document.querySelector(\'.question-title, h1\')?.innerText.trim();\n    let screenQuestion = window.i18n.toEnKey(screenQuestionRaw);'
);

// Map the reverse translation when setting input values
content = content.replace(
    'input.value = p[labelName];',
    'input.value = window.i18n.toRuVal(p[window.i18n.toEnKey(labelName)]);'
);

// Map reverse translation for choice cards
content = content.replace(
    'if (savedCardValues.includes(label)) {',
    'if (savedCardValues.includes(window.i18n.toEnVal(label))) {'
);

fs.writeFileSync('onboarding-state.js', content);
console.log('Fixed onboarding-state.js');
