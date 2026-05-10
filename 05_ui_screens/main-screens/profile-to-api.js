/**
 * profile-to-api.js — Frontend → Backend Data Adapter (Standardized)
 * 
 * v3.0 Changes:
 * - Strictly uses canonical English keys (name, gender, weight, height, diseases, medications, supplements).
 * - Implements failsafe mapping via i18n.toEnKey for any legacy/cyrillic keys.
 * - Removed target_weight_kg/height_cm redundancy.
 */

(function() {
  'use strict';

  // ═══════════════════════════════════════════════
  // PROFILE READER — reads from localStorage with key normalization
  // ═══════════════════════════════════════════════

  function readProfile() {
    try {
      // AIDiet.getProfile() already returns merged/canonical view
      const profile = (window.AIDiet && window.AIDiet.getProfile) 
        ? window.AIDiet.getProfile() 
        : JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
      
      const normalized = {};
      Object.entries(profile).forEach(([key, value]) => {
        // Use i18n to ensure we have the canonical English key
        const canonical = (window.i18n && window.i18n.toEnKey) ? window.i18n.toEnKey(key) : key;
        normalized[canonical] = value;
      });
      return normalized;
    } catch (e) {
      console.error('[profile-to-api] Failed to read profile:', e);
      return {};
    }
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════

  function parseArrayField(value) {
    if (Array.isArray(value)) return value;
    if (!value || value === '' || value === 'Нет' || value === 'no' || value === 'none') return [];
    return String(value).split(', ').map(s => s.trim()).filter(Boolean);
  }

  function parseGoalForBackend(goal) {
    // Backend expects specific strings or descriptions
    const goalMap = {
      'weight_loss':         'Снизить вес',
      'muscle_gain':         'Набрать мышечную массу',
      'maintenance':         'Поддерживать форму',
      'energy':              'Больше энергии и фокуса',
      'skin_health':         'Улучшить кожу и волосы',
      'digestion':           'Наладить пищеварение',
      'longevity':           'Здоровье и долголетие',
    };
    return goalMap[goal] || goal || 'Поддерживать форму';
  }

  function parseTier(plan) {
    const tierMap = {
      'base': 'T1',
      'trial': 'T3', 
      'black': 'T2',
      'gold': 'T3',
      'group_gold': 'T3',
    };
    return tierMap[plan] || 'T1';
  }

  // ═══════════════════════════════════════════════
  // MAIN BUILDER — produces UserProfilePayload
  // ═══════════════════════════════════════════════

  function buildPlanPayload() {
    const p = readProfile();

    return {
      age:                parseInt(p.age) || 30,
      gender:             (p.gender === 'female' || p.sex === 'female') ? 'female' : 'male',
      weight:             parseFloat(p.weight) || parseFloat(p.weight_kg) || 70,
      height:             parseFloat(p.height) || parseFloat(p.height_cm) || 170,
      target_weight:      p.target_weight ? parseFloat(p.target_weight) : null,
      target_timeline_weeks: p.target_timeline_weeks ? parseInt(p.target_timeline_weeks) : null,
      goal:               parseGoalForBackend(p.goal || p.primary_goal),
      activity_level:     p.activity_level || p.activity_frequency || 'Умеренная',
      allergies:          parseArrayField(p.allergies),
      restrictions:       parseArrayField(p.diets || p.diet_restrictions),
      diseases:           parseArrayField(p.diseases || p.chronic_diseases || p.chronic_conditions),
      symptoms:           parseArrayField(p.symptoms),
      country:            p.country || p.user_country || 'Россия',
      city:               p.city || p.user_city || '',
      budget_level:       p.budget_level || p.budget || 'Средний',
      cooking_time:       p.cooking_time || 'Без разницы',
      fasting_status:     (p.fasting_status === true || p.fasting_status === 'yes' || p.fasting_status === 'Да'),
      fasting_type:       p.fasting_type || null,
      meal_pattern:       p.meal_pattern || '3 приема (завтрак, обед, ужин)',
      training_schedule:  p.training_schedule || (p.activity_level ? `${p.activity_level}, ${p.activity_types || ''}` : 'Без регулярных тренировок'),
      sleep_schedule:     p.sleep_schedule || (p.bedtime ? `Отбой ${p.bedtime}, Подъём ${p.wakeup_time || '08:00'}` : '8 часов'),
      medications:        p.medications || p.medications_text || p.takes_medications || 'Нет',
      supplements:        p.supplements || p.current_supplements_text || p.takes_supplements || 'Нет',
      supplement_openness: p.supplement_openness || null,
      liked_foods:        parseArrayField(p.liked_foods),
      disliked_foods:     parseArrayField(p.disliked_foods),
      excluded_meal_types: parseArrayField(p.excluded_meal_types),
      motivation_barriers: parseArrayField(p.motivation_barriers),
      tier:               parseTier(p.subscription_status || p.subscription_plan || localStorage.getItem('aidiet_subscription')),
      activity_multiplier: parseFloat(p.activity_multiplier) || 1.2,
      // Medical data
      womens_health:      p.womens_health || null,
      takes_contraceptives: p.takes_contraceptives || null,
      bmi:                p.bmi ? String(p.bmi) : null,
      waist:              p.waist ? String(p.waist) : (p.waist_cm ? String(p.waist_cm) : null),
      body_type:          p.body_type || null,
      blood_tests:        p.blood_tests || null
    };
  }

  function buildPhotoContext() {
    const p = readProfile();
    return {
      goal:             parseGoalForBackend(p.goal || p.primary_goal),
      allergies:        JSON.stringify(parseArrayField(p.allergies)),
      diseases:         JSON.stringify(parseArrayField(p.diseases || p.chronic_diseases || p.chronic_conditions)),
      daily_calories:   parseInt(p.target_daily_calories) || 2000,
      calories_consumed: 0, 
    };
  }

  function buildChatContext() {
    const p = readProfile();
    return {
      age:       parseInt(p.age) || 30,
      gender:    p.gender || p.sex || 'male',
      goal:      parseGoalForBackend(p.goal || p.primary_goal),
      diseases:  parseArrayField(p.diseases || p.chronic_diseases || p.chronic_conditions),
      allergies: parseArrayField(p.allergies),
    };
  }

  function buildReportPayload(daySummaries) {
    const p = readProfile();
    return {
      days:          daySummaries || [],
      user_goal:     parseGoalForBackend(p.goal || p.primary_goal),
      user_name:     p.name || p.first_name || null,
      user_diseases: parseArrayField(p.diseases || p.chronic_diseases || p.chronic_conditions),
    };
  }

  window.AIDietAPI = {
    readProfile,
    buildPlanPayload,
    buildPhotoContext,
    buildChatContext,
    buildReportPayload,
    getAuthToken: () => localStorage.getItem('aidiet_auth_token') || '',
    getAnonymousUUID: () => localStorage.getItem('aidiet_anonymous_uuid') || '',
    saveAuth: (uuid, token) => {
      localStorage.setItem('aidiet_anonymous_uuid', uuid);
      localStorage.setItem('aidiet_auth_token', token);
    }
  };

})();
