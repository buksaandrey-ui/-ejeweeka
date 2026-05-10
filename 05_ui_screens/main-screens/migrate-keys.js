const fs = require('fs');
const path = require('path');

const UI_DIR = path.join(__dirname);

// The mapping dictionaries
const KEY_MAP = {
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
    'Нелюбимые продукты': 'disliked_foods'
};

function processHtmlFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    let changed = false;

    // 1. Replace data-question attributes
    Object.entries(KEY_MAP).forEach(([ru, en]) => {
        const regex1 = new RegExp(`data-question=["']${ru}["']`, 'g');
        if (regex1.test(content)) {
            content = content.replace(regex1, `data-question="${en}"`);
            changed = true;
        }
        
        // 2. Replace saveField calls: saveField('Русский', ...) -> saveField('english', ...)
        // Handle exact string match
        const regex2 = new RegExp(`saveField\\(\\s*['"]${ru}['"]\\s*,`, 'g');
        if (regex2.test(content)) {
            content = content.replace(regex2, `saveField('${en}',`);
            changed = true;
        }
    });

    if (changed) {
        fs.writeFileSync(filePath, content);
        console.log(`Updated HTML: ${path.basename(filePath)}`);
    }
}

function processJsFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    let changed = false;

    Object.entries(KEY_MAP).forEach(([ru, en]) => {
        // app-utils.js: p['Русский'] -> p['english']
        const regex = new RegExp(`p\\[['"]${ru}['"]\\]`, 'g');
        if (regex.test(content)) {
            content = content.replace(regex, `p['${en}']`);
            changed = true;
        }
    });

    // Special fix for getProfileSummary if it has split(p['Русский'])
    if (changed) {
        fs.writeFileSync(filePath, content);
        console.log(`Updated JS: ${path.basename(filePath)}`);
    }
}

const files = fs.readdirSync(UI_DIR);

files.forEach(file => {
    const fullPath = path.join(UI_DIR, file);
    if (file.endsWith('.html')) {
        processHtmlFile(fullPath);
    } else if (file === 'app-utils.js' || file === 'api-connector.js') {
        processJsFile(fullPath);
    }
});

console.log("Migration complete.");
