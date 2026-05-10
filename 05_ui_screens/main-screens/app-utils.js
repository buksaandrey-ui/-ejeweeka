/**
 * Health Code App Utilities
 * - getProfileSummary() — O-16 summary builder
 * - Food diary API (addFoodLogEntry, calculateConsumedToday, etc.)
 * - Global UI enhancements (glassmorphism, spring animations, haptic)
 *
 * SSOT for profile: AIDiet.saveField / AIDiet.getProfile (onboarding-state.js)
 * This file does NOT write to aidiet_profile directly.
 */

(function() {
  // Styles moved to global.css (glassmorphism, spring, skeleton, view-transitions)

  // Auto-inject capacitor-bridge.js в нативном приложении
  if (typeof window.Capacitor !== 'undefined' || document.querySelector('script[src*="capacitor"]')) {
    const bridge = document.createElement('script');
    bridge.src = 'capacitor-bridge.js';
    document.head.appendChild(bridge);
  }

  window.hapticImpact = function() {
    if (typeof navigator !== 'undefined' && navigator.vibrate) {
      try { navigator.vibrate([15]); } catch(e) {}
    }
  };

  document.addEventListener('DOMContentLoaded', () => {
    document.body.addEventListener('click', (e) => {
      if (e.target.closest('button') || e.target.closest('.tab-item') || e.target.closest('.nav-item') || e.target.closest('.btn-spring') || e.target.closest('.action-card')) {
        window.hapticImpact();
      }
    });
    
    document.querySelectorAll('.tab-bar, .bottom-nav').forEach(el => {
      el.style.backgroundColor = 'transparent';
    });
  });

  // ═══ Smooth Page Transition ═══
  // Перехватываем ВСЕ клики по ссылкам/кнопкам с onclick="location.href=..."
  // и добавляем fade-out перед навигацией. Это маскирует WKWebView ghosting.
  window.smoothNavigate = function(url) {
    const phone = document.querySelector('.phone');
    if (phone) {
      phone.style.transition = 'opacity 0.08s ease-out';
      phone.style.opacity = '0';
      setTimeout(() => { window.location.href = url; }, 80);
    } else {
      window.location.href = url;
    }
  };

  // Перехватываем onclick="location.href='...'" через делегирование
  document.addEventListener('click', (e) => {
    const el = e.target.closest('[onclick]');
    if (!el) return;
    const onclick = el.getAttribute('onclick') || '';
    const match = onclick.match(/location\.href\s*=\s*['"](.*?)['"]/);
    if (match) {
      e.preventDefault();
      e.stopPropagation();
      window.smoothNavigate(match[1]);
    }
  }, true); // capture phase — перехватываем ДО onclick
})();

/**
 * Маппинг всех полей для O-16 (сводка).
 * Возвращает человекочитаемую сводку.
 * SSOT: Читаем из aidiet_profile (AIDiet.getProfile()).
 */
function getProfileSummary() {
  // Основной источник — единый профиль
  const p = (window.AIDiet && window.AIDiet.getProfile) 
    ? window.AIDiet.getProfile() 
    : JSON.parse(localStorage.getItem('aidiet_profile') || '{}');

  // Хелпер: split строки по запятой в массив, или вернуть пустой
  const split = (val) => {
    if (!val || typeof val !== 'string') return [];
    return val.split(/[,;]+/).map(s => s.trim()).filter(Boolean);
  };

  const parseBloodTests = () => {
    try {
      const raw = p['blood_tests'];
      if (!raw) return {};
      const obj = JSON.parse(raw);
      if (!obj.has_lab_tests) return {};
      // Russian label mapping for lab keys
      const labLabels = {
        glucose: 'Глюкоза',
        hba1c: 'HbA1c',
        insulin: 'Инсулин',
        cholesterol: 'Холестерин',
        vitD: 'Витамин D',
        ferritin: 'Ферритин',
        iron: 'Железо',
        tsh: 'ТТГ',
        b12: 'Витамин B12',
        other: 'Другое'
      };
      const result = {};
      Object.entries(obj).forEach(([k, v]) => {
        if (k.startsWith('lab_') && v) {
          const key = k.replace('lab_', '');
          result[key] = { label: labLabels[key] || key, value: v, unit: '' };
        }
      });
      return result;
    } catch { return {}; }
  };

  return {
    // O-1
    country: p['user_country'] || p['country'] || p['Страна'] || '—',
    city: p['user_city'] || p['city'] || p['Город'] || '—',

    // O-2
    goal: (window.i18n ? window.i18n.toRuVal(p['primary_goal'] || p['goal'] || p['Главная цель']) : (p['primary_goal'] || p['goal'] || p['Главная цель'])) || '—',

    // O-3
    name: p['first_name'] || p['Имя'] || '—',
    sex: (window.i18n ? window.i18n.toRuVal(p['sex'] || p['gender'] || p['Пол']) : (p['sex'] || p['gender'] || p['Пол'])) || '—',
    age: p['age'] || p['Возраст'] || '—',
    height: (p['height_cm'] || p['height'] || p['Рост']) ? `${p['height_cm'] || p['height'] || p['Рост']} см` : '—',
    weight: (p['weight_kg'] || p['weight'] || p['Текущий вес']) ? `${p['weight_kg'] || p['weight'] || p['Текущий вес']} кг` : '—',
    waist: (p['waist_cm'] || p['waist'] || p['Обхват талии']) ? `${p['waist_cm'] || p['waist'] || p['Обхват талии']} см` : '—',
    bmi: p['bmi'] || p['ИМТ'] || '—',
    bmr: (p['bmr_kcal'] || p['bmr'] || p['BMR']) ? `${p['bmr_kcal'] || p['bmr'] || p['BMR']} ккал` : '—',

    // O-4
    targetWeight: (p['target_weight_kg'] || p['target_weight'] || p['Целевой вес']) ? `${p['target_weight_kg'] || p['target_weight'] || p['Целевой вес']} кг` : null,
    targetTimeline: p['target_timeline_weeks'] ? `${p['target_timeline_weeks']} нед.` : null,

    // O-5
    restrictions: split((window.i18n ? window.i18n.toRuVal(p['diet_restrictions'] || p['Тип питания']) : (p['diet_restrictions'] || p['Тип питания']))),
    allergies: split((window.i18n ? window.i18n.toRuVal(p['allergies'] || p['Аллергены']) : (p['allergies'] || p['Аллергены']))),

    // O-6
    symptoms: split((window.i18n ? window.i18n.toRuVal(p['symptoms'] || p['Симптомы']) : (p['symptoms'] || p['Симптомы']))).filter(s => s !== 'Нет'),
    conditions: split((window.i18n ? window.i18n.toRuVal(p['chronic_conditions'] || p['chronic_diseases'] || p['Хронические заболевания']) : (p['chronic_conditions'] || p['chronic_diseases'] || p['Хронические заболевания']))).filter(s => s !== 'Нет'),

    // O-7
    medications: (window.i18n ? window.i18n.toRuVal(p['takes_medications'] || p['takes_medication']) : (p['takes_medications'] || p['takes_medication'])) || null,
    hormones: p['takes_contraceptives'] || p['Принимает гормональные (КОК)'] || null,
    womensHealth: (window.i18n ? window.i18n.toRuVal(p['womens_health']) : p['womens_health']) || null,

    // O-8
    mealPattern: p['meal_pattern'] || p['meals_per_day'] || p['Сколько раз в день удобно есть?'] || '—',
    fastingStatus: (window.i18n ? window.i18n.toRuVal(p['fasting_status'] || p['fasting_pattern']) : (p['fasting_status'] || p['fasting_pattern'])) || 'Нет',

    // O-9
    sleepTime: p['sleep_time'] || p['sleep_bedtime'] || p['Отбой'] || '—',
    wakeTime: p['sleep_waketime'] || p['Подъем'] || '—',

    // O-10
    activityFreq: (window.i18n ? window.i18n.toRuVal(p['activity_frequency']) : p['activity_frequency']) || '—',
    activityTypes: split((window.i18n ? window.i18n.toRuVal(p['activity_types']) : p['activity_types'])),

    // O-11
    budget: (window.i18n ? window.i18n.toRuVal(p['budget_level'] || p['budget'] || p['Бюджет']) : (p['budget_level'] || p['budget'] || p['Бюджет'])) || '—',
    cookingTime: (window.i18n ? window.i18n.toRuVal(p['cooking_time']) : p['cooking_time']) || '—',

    // O-12
    bloodTests: parseBloodTests(),

    // O-13
    supplements: (window.i18n ? window.i18n.toRuVal(p['currently_takes_supplements'] || p['takes_supplements'] || p['БАД']) : (p['currently_takes_supplements'] || p['takes_supplements'] || p['БАД'])) || null,
    supplementOpenness: (window.i18n ? window.i18n.toRuVal(p['supplement_openness']) : p['supplement_openness']) || '—',

    // O-14
    barriers: split((window.i18n ? window.i18n.toRuVal(p['motivation_barriers'] || p['past_barriers'] || p['Главные барьеры прошлого']) : (p['motivation_barriers'] || p['past_barriers'] || p['Главные барьеры прошлого']))),

    // O-15
    excludedMeals: split((window.i18n ? window.i18n.toRuVal(p['excluded_meal_types'] || p['excluded_categories'] || p['Исключённые категории']) : (p['excluded_meal_types'] || p['excluded_categories'] || p['Исключённые категории']))),
    likedFoods: p['liked_foods'] || p['Любимые продукты'] || '—',
    dislikedFoods: p['disliked_foods'] || p['Нелюбимые продукты'] || '—',

    // Raw data for debugging
    _raw: p
  };
}


// ============================================================
// ДНЕВНИК ПИТАНИЯ (для PH-1 Фото-анализ и H-1 Дашборд)
// Хранится ОТДЕЛЬНО от профиля в 'aidiet_food_log' (не SSOT)
// ============================================================

const FOOD_LOG_KEY = 'aidiet_food_log';

function _getFoodLogStore() {
  try { return JSON.parse(localStorage.getItem(FOOD_LOG_KEY)) || {}; }
  catch { return {}; }
}

function _saveFoodLogStore(data) {
  data._lastUpdated = new Date().toISOString();
  localStorage.setItem(FOOD_LOG_KEY, JSON.stringify(data));
}

/**
 * Добавить запись о съеденном блюде в дневник.
 * Вызывается при нажатии «Подтвердить» на PH-1 или «Съел ✅» на H-1.
 */
function addFoodLogEntry(entry) {
  const data = _getFoodLogStore();
  const today = new Date().toISOString().split('T')[0];
  if (!data.days) data.days = {};
  if (!data.days[today]) data.days[today] = [];
  data.days[today].push({
    food_name: entry.food_name || 'Неизвестное блюдо',
    calories: entry.calories || 0,
    proteins: entry.proteins || 0,
    fats: entry.fats || 0,
    carbs: entry.carbs || 0,
    fiber: entry.fiber || 0,
    portion_grams: entry.portion_grams || 0,
    source: entry.source || 'manual',
    timestamp: new Date().toISOString()
  });
  _saveFoodLogStore(data);
}

/**
 * Подсчитать общее количество калорий, съеденных сегодня.
 * Используется для отображения калорийного кольца на H-1 и расчёта остатка.
 */
function calculateConsumedToday() {
  const data = _getFoodLogStore();
  const today = new Date().toISOString().split('T')[0];
  const entries = (data.days && data.days[today]) || [];
  return entries.reduce((sum, e) => sum + (e.calories || 0), 0);
}

/**
 * Получить записи дневника за сегодня.
 */
function getTodayFoodLog() {
  const data = _getFoodLogStore();
  const today = new Date().toISOString().split('T')[0];
  return (data.days && data.days[today]) || [];
}

/**
 * Проверить лимит фото-анализов на сегодня (макс. 10 согласно ai-pipeline.md).
 * Возвращает { remaining: число, allowed: boolean }.
 */
function checkPhotoAnalysisLimit() {
  const data = _getFoodLogStore();
  const today = new Date().toISOString().split('T')[0];
  if (data.photo_analysis_date !== today) {
    data.photo_analysis_date = today;
    data.photo_analysis_count = 0;
    _saveFoodLogStore(data);
    return { remaining: 10, allowed: true };
  }
  const count = data.photo_analysis_count || 0;
  return { remaining: 10 - count, allowed: count < 10 };
}

/**
 * Увеличить счётчик использованных фото-анализов.
 */
function incrementPhotoAnalysisCount() {
  const data = _getFoodLogStore();
  data.photo_analysis_count = (data.photo_analysis_count || 0) + 1;
  _saveFoodLogStore(data);
}

/**
 * Динамическая корректировка оставшегося плана.
 * При добавлении сторонних калорий (перекус/напиток), мы вычитаем эти калории 
 * пропорционально из всех предстоящих приемов пищи на сегодня.
 */
window.adjustRemainingPlan = function(extraCalories) {
    if (!extraCalories || extraCalories <= 0) return;
    
    try {
        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw) return;
        let plan = JSON.parse(planRaw);
        if (typeof plan === 'string') plan = JSON.parse(plan);
        
        const eatenMeals = JSON.parse(localStorage.getItem('aidiet_eaten_meals') || '[]');
        const todayIdx = new Date().getDay();
        const dayIndex = todayIdx === 0 ? 7 : todayIdx;
        const dayKey = `day_${dayIndex}`;
        
        let dayMealsRaw = plan[dayKey];
        if (dayMealsRaw && dayMealsRaw.meals) dayMealsRaw = dayMealsRaw.meals;
        const dayMeals = Array.isArray(dayMealsRaw) ? dayMealsRaw : [];
        
        // Ищем несъеденные блюда сегодня
        let remainingMeals = [];
        dayMeals.forEach((m, idx) => {
            if (!eatenMeals.includes(`${dayKey}_${idx}`)) {
                remainingMeals.push({ meal: m, idx: idx });
            }
        });
        
        if (remainingMeals.length === 0) return; // Не из чего вычитать
        
        // Считаем сумму калорий оставшихся блюд
        const totalRemainingCals = remainingMeals.reduce((sum, item) => sum + (item.meal.calories || 0), 0);
        if (totalRemainingCals <= 0) return;
        
        // Пропорционально уменьшаем каждое блюдо
        remainingMeals.forEach(item => {
            const m = item.meal;
            const mealCals = m.calories || 0;
            const ratio = mealCals / totalRemainingCals;
            const calsToSubtract = Math.round(extraCalories * ratio);
            
            // Если вычет больше чем калорийность блюда, оставляем минимум 50 ккал
            if (calsToSubtract >= mealCals) {
                m.calories = 50;
            } else {
                m.calories = mealCals - calsToSubtract;
            }
            
            // Пересчитываем макросы и граммовки пропорционально
            const reduceRatio = m.calories / mealCals;
            if (m.protein) m.protein = Math.round(m.protein * reduceRatio);
            if (m.fat) m.fat = Math.round(m.fat * reduceRatio);
            if (m.carbs) m.carbs = Math.round(m.carbs * reduceRatio);
            if (m.serving_g) m.serving_g = Math.round(m.serving_g * reduceRatio);
            
            // Добавляем пометку
            if (!m.wellness_rationale) m.wellness_rationale = "";
            m.wellness_rationale += ` (Порция уменьшена на ${calsToSubtract} ккал из-за внепланового перекуса/напитка)`;
        });
        
        localStorage.setItem('aidiet_meal_plan', JSON.stringify(plan));
        console.log(`[Plan Adjusted] Вычтено ${extraCalories} ккал из ${remainingMeals.length} оставшихся блюд.`);
    } catch (e) {
        console.error("Ошибка при корректировке плана:", e);
    }
};
