const i18n_ru = {
  // Canonical Keys (PROJECT_CONTEXT.md Standard)
  country: 'Страна',
  city: 'Город',
  goal: 'Главная цель',
  name: 'Имя',
  gender: 'Пол',
  age: 'Возраст',
  height: 'Рост',
  weight: 'Текущий вес',
  body_type: 'Телосложение',
  waist: 'Обхват талии',
  fat_distribution: 'Распределение жира',
  bmi: 'ИМТ',
  bmr: 'BMR',
  target_weight: 'Целевой вес',
  target_timeline_weeks: 'Срок (недель)',
  diets: 'Выбранные диеты/ограничения',
  allergies: 'Аллергии',
  symptoms: 'Симптомы',
  diseases: 'Хронические заболевания',
  medications: 'Принимает лекарства',
  womens_health: 'Женское здоровье',
  takes_contraceptives: 'Принимает гормональные (КОК)',
  meal_pattern: 'Сколько раз в день удобно есть?',
  fasting_type: 'Голодание',
  bedtime: 'Отбой',
  wakeup_time: 'Подъем',
  activity_level: 'Частота активности',
  activity_types: 'Виды активности',
  budget_level: 'Бюджет',
  cooking_time: 'Время на готовку',
  supplements: 'БАД',
  supplement_openness: 'Отношение к БАДам',
  motivation_barriers: 'Главные барьеры прошлого',
  excluded_meal_types: 'Исключённые категории',
  liked_foods: 'Любимые продукты',
  disliked_foods: 'Нелюбимые продукты',
  subscription_status: 'Выбранный статус',

  // Values (Common used in logic/AI)
  weight_loss: 'Снизить вес',
  muscle_gain: 'Набрать мышечную массу',
  maintenance: 'Поддерживать форму',
  male: 'Мужской',
  female: 'Женский',
  yes: 'Да',
  no: 'Нет',
  not_specified: 'Не указано'
};

// --- MAPPING DICTIONARIES for Migration & Enforcement ---
const DICT_KEYS = {
  'Страна': 'country', 'Город': 'city',
  'Главная цель': 'goal', 'primary_goal': 'goal',
  'Имя': 'name', 'first_name': 'name',
  'Пол': 'gender', 'sex': 'gender',
  'Возраст': 'age',
  'Рост': 'height', 'height_cm': 'height',
  'Текущий вес': 'weight', 'weight_kg': 'weight',
  'ИМТ': 'bmi', 'BMR': 'bmr', 'bmr_kcal': 'bmr',
  'Телосложение': 'body_type',
  'Обхват талии': 'waist', 'waist_cm': 'waist',
  'Распределение жира': 'fat_distribution',
  'Целевой вес': 'target_weight',
  'Срок (недель)': 'target_timeline_weeks',
  'Выбранные диеты/ограничения': 'diets', 'diet_restrictions': 'diets',
  'Аллергии': 'allergies', 'has_allergies': 'allergies',
  'Симптомы': 'symptoms',
  'Хронические заболевания': 'diseases', 'chronic_diseases': 'diseases', 'chronic_conditions': 'diseases',
  'Принимает лекарства': 'medications', 'takes_medication': 'medications', 'takes_medications': 'medications',
  'Женское здоровье': 'womens_health',
  'Принимает гормональные (КОК)': 'takes_contraceptives',
  'Сколько раз в день удобно есть?': 'meal_pattern', 'meals_per_day': 'meal_pattern',
  'Голодание': 'fasting_type', 'fasting_pattern': 'fasting_type',
  'Отбой': 'bedtime', 'sleep_bedtime': 'bedtime',
  'Подъем': 'wakeup_time', 'sleep_waketime': 'wakeup_time',
  'Частота активности': 'activity_level', 'activity_frequency': 'activity_level',
  'Виды активности': 'activity_types',
  'Бюджет': 'budget_level', 'budget': 'budget_level',
  'Время на готовку': 'cooking_time',
  'БАД': 'supplements', 'takes_supplements': 'supplements', 'currently_takes_supplements': 'supplements',
  'Отношение к БАДам': 'supplement_openness',
  'Главные барьеры прошлого': 'motivation_barriers', 'past_barriers': 'motivation_barriers',
  'Исключённые категории': 'excluded_meal_types', 'excluded_categories': 'excluded_meal_types',
  'Любимые продукты': 'liked_foods',
  'Нелюбимые продукты': 'disliked_foods',
  'Выбранный статус': 'subscription_status'
};

const REVERSE_KEYS = Object.fromEntries(Object.entries(DICT_KEYS).map(([k, v]) => [v, k]));

function translate(keyOrValue) {
  return i18n_ru[keyOrValue] || keyOrValue;
}

// Global i18n object for screens
window.i18n = { 
  t: translate,
  toEnKey: (k) => DICT_KEYS[k] || k,
  toRuKey: (k) => REVERSE_KEYS[k] || k,
  toEnVal: (v) => {
    if (v === 'Мужской') return 'male';
    if (v === 'Женский') return 'female';
    if (v === 'Да') return 'yes';
    if (v === 'Нет') return 'no';
    return v;
  },
  toRuVal: (v) => {
    if (v === 'male') return 'Мужской';
    if (v === 'female') return 'Женский';
    if (v === 'yes') return 'Да';
    if (v === 'no') return 'Нет';
    return v;
  }
};
