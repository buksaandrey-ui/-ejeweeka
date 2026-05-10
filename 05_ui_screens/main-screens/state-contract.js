/**
 * state-contract.js — AIDiet Single Source of Truth (SSOT)
 * 
 * PURPOSE: Defines the canonical data schema for the entire application.
 * All fields use ENGLISH keys only. This file is the ONLY authority on field names.
 * 
 * ARCHITECTURE:
 *   Onboarding HTML screens → saveField() → localStorage['aidiet_profile'] (English keys)
 *   profile-to-api.js → reads localStorage → maps to UserProfilePayload → POST /api/v1/plan/generate
 *   Dashboard/Plan screens → read from localStorage['aidiet_meal_plan']
 * 
 * FROZEN: O-1 to O-16 UI/UX is not modified. Only the save/hydrate logic adapts to this contract.
 */

(function() {
  'use strict';

  // ═══════════════════════════════════════════════
  // CANONICAL FIELD DEFINITIONS
  // ═══════════════════════════════════════════════
  // Each field: { type, required, default, validate, screen }

  const PROFILE_SCHEMA = {
    // ──── O-1: Welcome & Country ────
    user_country:        { type: 'string',  screen: 'O-1',  default: '' },
    user_city:           { type: 'string',  screen: 'O-1',  default: '' },
    user_language:       { type: 'string',  screen: 'O-1',  default: 'ru' },

    // ──── O-2: Goal ────
    primary_goal:        { type: 'string',  screen: 'O-2',  required: true },
    also_wants_weight_loss: { type: 'string', screen: 'O-2', default: 'no' },

    // ──── O-3: Profile ────
    first_name:          { type: 'string',  screen: 'O-3',  required: true },
    sex:                 { type: 'enum',    screen: 'O-3',  required: true, values: ['male', 'female'] },
    age:                 { type: 'number',  screen: 'O-3',  required: true, min: 16, max: 100 },
    height_cm:           { type: 'number',  screen: 'O-3',  required: true, min: 100, max: 250 },
    weight_kg:           { type: 'number',  screen: 'O-3',  required: true, min: 30, max: 300 },
    body_type:           { type: 'string',  screen: 'O-3',  default: '' },
    waist_cm:            { type: 'number',  screen: 'O-3',  default: null },
    fat_distribution:    { type: 'string',  screen: 'O-3',  default: '' },

    // ──── Computed from O-3 ────
    bmi:                 { type: 'number',  computed: true },
    bmi_class:           { type: 'string',  computed: true },
    bmr_kcal:            { type: 'number',  computed: true },
    waist_to_height:     { type: 'number',  computed: true },

    // ──── O-4: Weight Loss (conditional) ────
    target_weight_kg:    { type: 'number',  screen: 'O-4',  default: null },
    target_timeline_weeks: { type: 'number', screen: 'O-4', default: null },
    speed_priority:      { type: 'string',  screen: 'O-4',  default: '' },
    target_date:         { type: 'string',  screen: 'O-4',  default: '' },
    pace_classification: { type: 'string',  screen: 'O-4',  default: '' },
    target_daily_calories: { type: 'number', computed: true },

    // ──── O-5: Restrictions & Allergies ────
    diet_restrictions:   { type: 'array',   screen: 'O-5',  default: [] },
    has_allergies:       { type: 'string',  screen: 'O-5',  default: 'no' },
    allergies:           { type: 'array',   screen: 'O-5',  default: [] },

    // ──── O-6: Health Core ────
    symptoms:            { type: 'array',   screen: 'O-6',  default: [] },
    chronic_conditions:  { type: 'array',   screen: 'O-6',  default: [] },
    diabetes_details:    { type: 'object',  screen: 'O-6',  default: null },
    thyroid_details:     { type: 'object',  screen: 'O-6',  default: null },
    gi_details:          { type: 'object',  screen: 'O-6',  default: null },
    takes_medications:   { type: 'string',  screen: 'O-6',  default: 'no' },
    medications_text:    { type: 'string',  screen: 'O-6',  default: '' },

    // ──── O-7: Women's Health (conditional) ────
    womens_health:       { type: 'array',   screen: 'O-7',  default: [] },
    takes_contraceptives:{ type: 'string',  screen: 'O-7',  default: 'no' },

    // ──── O-8: Habits ────
    meal_pattern:        { type: 'string',  screen: 'O-8',  default: '3' },
    fasting_status:      { type: 'string',  screen: 'O-8',  default: 'no' },
    fasting_type:        { type: 'string',  screen: 'O-8',  default: '' },
    fasting_duration:    { type: 'string',  screen: 'O-8',  default: '' },
    fasting_interest:    { type: 'string',  screen: 'O-8',  default: '' },

    // ──── O-9: Sleep ────
    sleep_time:          { type: 'string',  screen: 'O-9',  default: '' },
    wake_time:           { type: 'string',  screen: 'O-9',  default: '' },
    sleep_duration_hours:{ type: 'number',  screen: 'O-9',  default: null },
    sleep_stability:     { type: 'string',  screen: 'O-9',  default: '' },
    sleep_type:          { type: 'string',  screen: 'O-9',  default: 'regular' },

    // ──── O-10: Activity ────
    activity_frequency:  { type: 'string',  screen: 'O-10', default: '' },
    activity_duration:   { type: 'string',  screen: 'O-10', default: '' },
    activity_types:      { type: 'array',   screen: 'O-10', default: [] },
    activity_multiplier: { type: 'number',  computed: true, default: 1.375 },
    wants_training_plan: { type: 'string',  screen: 'O-10', default: 'no' },

    // ──── O-11: Budget & Cooking ────
    budget_level:        { type: 'string',  screen: 'O-11', default: '' },
    cooking_time:        { type: 'string',  screen: 'O-11', default: '' },

    // ──── O-12: Blood Tests ────
    has_blood_tests:     { type: 'string',  screen: 'O-12', default: 'no' },
    blood_tests:         { type: 'object',  screen: 'O-12', default: null },

    // ──── O-13: Supplements ────
    currently_takes_supplements: { type: 'string', screen: 'O-13', default: 'no' },
    current_supplements_text:    { type: 'string', screen: 'O-13', default: '' },
    supplement_openness:         { type: 'string', screen: 'O-13', default: '' },

    // ──── O-14: Motivation ────
    motivation_barriers: { type: 'array',   screen: 'O-14', default: [] },

    // ──── O-15: Preferences ────
    excluded_meal_types: { type: 'array',   screen: 'O-15', default: [] },
    liked_foods:         { type: 'string',  screen: 'O-15', default: '' },
    disliked_foods:      { type: 'string',  screen: 'O-15', default: '' },

    // ──── O-17: Subscription ────
    subscription_plan:   { type: 'string',  screen: 'O-17', default: 'base' },
    is_trial:            { type: 'boolean', screen: 'O-17', default: true },
    selected_theme:      { type: 'string',  default: 'nature' },

    // ──── System ────
    onboarding_complete: { type: 'boolean', default: false },
    _schema_version:     { type: 'number',  default: 3 },
  };

  // ═══════════════════════════════════════════════
  // LEGACY KEY BRIDGE
  // Maps legacy Russian/English keys from older onboarding-state.js
  // to canonical keys defined in PROFILE_SCHEMA above.
  // Used by getCanonical() to normalize any key to its canonical form.
  // ═══════════════════════════════════════════════

  const LEGACY_KEY_MAP = {
    // Russian legacy → canonical
    'Страна': 'user_country',
    'Город': 'user_city',
    'Главная цель': 'primary_goal',
    'Имя': 'first_name',
    'Пол': 'sex',
    'Возраст': 'age',
    'Рост': 'height_cm',
    'Текущий вес': 'weight_kg',
    'Телосложение': 'body_type',
    'Обхват талии': 'waist_cm',
    'Распределение жира': 'fat_distribution',
    'Доп. Снижение веса': 'also_wants_weight_loss',
    'ИМТ': 'bmi',
    'Класс ИМТ': 'bmi_class',
    'BMR': 'bmr_kcal',
    'Талия/Рост': 'waist_to_height',
    'Целевой вес': 'target_weight_kg',
    'Срок (недель)': 'target_timeline_weeks',
    'Выбранные диеты/ограничения': 'diet_restrictions',
    'Тип питания': 'diet_restrictions',
    'Аллергии': 'allergies',
    'Аллергены': 'allergies',
    'Есть аллергия': 'has_allergies',
    'Симптомы': 'symptoms',
    'Хронические заболевания': 'chronic_conditions',
    'Принимает лекарства': 'takes_medications',
    'Женское здоровье': 'womens_health',
    'Принимает гормональные (КОК)': 'takes_contraceptives',
    'Интерес к голоданию': 'fasting_interest',
    'Голодание': 'fasting_status',
    'Сколько раз в день удобно есть?': 'meal_pattern',
    'Отбой': 'sleep_time',
    'Подъем': 'wake_time',
    'Режим сна': 'sleep_type',
    'Длительность сна (мин)': 'sleep_duration_hours',
    'Частота активности': 'activity_frequency',
    'Виды активности': 'activity_types',
    'Длительность тренировки': 'activity_duration',
    'Бюджет': 'budget_level',
    'Время на готовку': 'cooking_time',
    'Анализы': 'blood_tests',
    'БАД': 'currently_takes_supplements',
    'Принимаемые витамины': 'current_supplements_text',
    'Отношение к БАДам': 'supplement_openness',
    'Главные барьеры прошлого': 'motivation_barriers',
    'Исключённые категории': 'excluded_meal_types',
    'Любимые продукты': 'liked_foods',
    'Нелюбимые продукты': 'disliked_foods',

    // Old English aliases → canonical (from useStore.js / other legacy code)
    'gender': 'sex',
    'weight': 'weight_kg',
    'height': 'height_cm',
    'goal': 'primary_goal',
    'country': 'user_country',
    'city': 'user_city',
    'waist': 'waist_cm',
    'target_weight': 'target_weight_kg',
    'chronic_diseases': 'chronic_conditions',
    'takes_medication': 'takes_medications',
    'fasting_pattern': 'fasting_type',
    'meals_per_day': 'meal_pattern',
    'sleep_bedtime': 'sleep_time',
    'sleep_waketime': 'wake_time',
    'budget': 'budget_level',
    'takes_supplements': 'currently_takes_supplements',
    'supplement_details': 'current_supplements_text',
    'past_barriers': 'motivation_barriers',
    'excluded_categories': 'excluded_meal_types',
    'wants_weight_loss': 'also_wants_weight_loss',
  };

  // ═══════════════════════════════════════════════
  // VALUE NORMALIZATION
  // ═══════════════════════════════════════════════

  const VALUE_NORMALIZE = {
    'Мужской': 'male',
    'Мужчина': 'male',
    'Женский': 'female',
    'Женщина': 'female',
    'Да': 'yes',
    'Нет': 'no',
    'Снизить вес': 'weight_loss',
    'Набрать мышечную массу': 'muscle_gain',
    'Поддерживать форму': 'maintenance',
    'Больше энергии и фокуса': 'energy',
    'Улучшить кожу и волосы': 'skin_health',
    'Наладить пищеварение': 'digestion',
    'Здоровье и долголетие': 'longevity',
    'Питание для кожи, ногтей, волос': 'skin_health',
    'Питание при ограничениях по здоровью': 'health_restrictions',
    'Адаптировать питание к возрасту (40+ / 50+ / 60+)': 'age_adaptation',
    'Снизить тягу к сладкому и голод': 'sugar_craving',
    'Улучшить самочувствие и энергию': 'energy',
    'Восстановление после болезни/стресса': 'recovery',
    'Поддержание веса': 'maintenance',
    'Худощавое': 'thin',
    'Среднее': 'average',
    'Крепкое': 'strong',
    'Спортивное': 'athletic',
    'Есть лишний вес': 'overweight',
    'Эконом': 'economy',
    'Средний': 'medium',
    'Премиум': 'premium',
  };

  // ═══════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════

  /**
   * Get the canonical key name for any legacy/Russian key
   */
  function getCanonicalKey(key) {
    if (PROFILE_SCHEMA[key]) return key; // already canonical
    return LEGACY_KEY_MAP[key] || key;
  }

  /**
   * Normalize a value (Russian → English canonical)
   */
  function normalizeValue(value) {
    if (typeof value !== 'string') return value;
    // Try direct match
    if (VALUE_NORMALIZE[value]) return VALUE_NORMALIZE[value];
    // Try splitting comma-separated lists
    if (value.includes(', ')) {
      return value.split(', ').map(v => VALUE_NORMALIZE[v.trim()] || v.trim()).join(', ');
    }
    return value;
  }

  /**
   * Validate a field value against the schema
   * Returns { valid: boolean, error?: string }
   */
  function validateField(canonicalKey, value) {
    const schema = PROFILE_SCHEMA[canonicalKey];
    if (!schema) return { valid: true }; // unknown field, allow

    if (schema.required && (value === undefined || value === null || value === '')) {
      return { valid: false, error: `${canonicalKey} is required` };
    }

    if (value === undefined || value === null || value === '') {
      return { valid: true }; // optional, empty is ok
    }

    switch (schema.type) {
      case 'number':
        const num = parseFloat(value);
        if (isNaN(num)) return { valid: false, error: `${canonicalKey} must be a number` };
        if (schema.min !== undefined && num < schema.min) return { valid: false, error: `${canonicalKey} min ${schema.min}` };
        if (schema.max !== undefined && num > schema.max) return { valid: false, error: `${canonicalKey} max ${schema.max}` };
        break;
      case 'enum':
        if (schema.values && !schema.values.includes(value)) {
          return { valid: false, error: `${canonicalKey} must be one of: ${schema.values.join(', ')}` };
        }
        break;
    }
    return { valid: true };
  }

  /**
   * Calculate activity multiplier from frequency string
   */
  function computeActivityMultiplier(frequency) {
    const freq = (frequency || '').toLowerCase();
    if (freq.includes('не готов') || freq.includes('0') || freq === 'none') return 1.2;
    if (freq.includes('1 раз') || freq === '1') return 1.375;
    if (freq.includes('2') || freq.includes('3')) return 1.55;
    if (freq.includes('4') || freq.includes('более') || freq.includes('5')) return 1.725;
    return 1.375; // default: light activity
  }

  /**
   * Calculate BMR using Mifflin-St Jeor
   */
  function computeBMR(weight, height, age, sex) {
    const w = parseFloat(weight) || 70;
    const h = parseFloat(height) || 165;
    const a = parseInt(age) || 28;
    let bmr = 10 * w + 6.25 * h - 5 * a;
    bmr += (sex === 'female' ? -161 : 5);
    return Math.round(bmr);
  }

  /**
   * Get the full schema definition
   */
  function getSchema() {
    return { ...PROFILE_SCHEMA };
  }

  // ═══════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════

  window.AIDietContract = {
    PROFILE_SCHEMA,
    LEGACY_KEY_MAP,
    VALUE_NORMALIZE,
    getCanonicalKey,
    normalizeValue,
    validateField,
    computeActivityMultiplier,
    computeBMR,
    getSchema,
  };

})();
