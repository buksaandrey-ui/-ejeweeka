/**
 * plan-engine.js — Plan Generation & Local Persistence Engine
 * 
 * PURPOSE: E2E flow from profile → API → local storage → dashboard rendering.
 * Manages the meal plan lifecycle: generate, persist, read, update eaten status.
 * 
 * DEPENDS ON: state-contract.js, profile-to-api.js, auth-manager.js
 * 
 * STORAGE KEYS:
 *   localStorage['aidiet_meal_plan']     — the generated plan JSON
 *   localStorage['aidiet_plan_meta']     — generation metadata (date, model, calories)
 *   localStorage['aidiet_eaten_meals']   — Set of meal IDs marked as eaten
 *   localStorage['aidiet_day_progress']  — Current day progress (consumed KBZU)
 */

(function() {
  'use strict';

  const PLAN_KEY = 'aidiet_meal_plan';
  const META_KEY = 'aidiet_plan_meta';
  const EATEN_KEY = 'aidiet_eaten_meals';
  const PROGRESS_KEY = 'aidiet_day_progress';

  // ═══════════════════════════════════════════════
  // PLAN GENERATION
  // ═══════════════════════════════════════════════

  /**
   * Generate a meal plan by calling the backend API
   * @param {function} onProgress - callback for progress updates: onProgress(step, message)
   * @returns {Promise<object>} the generated plan data
   */
  async function generatePlan(onProgress) {
    const notify = onProgress || (() => {});

    try {
      // Step 1: Ensure auth
      notify(1, 'Подготавливаем запрос...');
      await window.AIDietAuth.ensureAuth();

      // Step 2: Build payload from local profile
      notify(2, 'Анализируем ваш профиль...');
      const payload = window.AIDietAPI.buildPlanPayload();

      console.log('[PlanEngine] Sending payload:', JSON.stringify(payload).substring(0, 200) + '...');

      // Step 3: Call API
      notify(3, 'Ищем рекомендации врачей по вашему случаю...');
      
      const result = await window.AIDietAuth.apiRequest('/api/v1/plan/generate', {
        method: 'POST',
        body: JSON.stringify(payload),
      }, 2); // 2 retries

      // Step 4: Validate response
      notify(4, 'Проверяем совместимость продуктов и лекарств...');
      
      if (!result || result.status !== 'success' || !result.data) {
        throw new Error('Invalid plan response: ' + JSON.stringify(result).substring(0, 100));
      }

      // Step 5: Save locally
      notify(5, 'Сохраняем ваш персональный план...');
      savePlan(result);

      console.log('[PlanEngine] Plan generated successfully:', {
        days: result.days_generated,
        meals_per_day: result.meals_per_day,
        target_kcal: result.target_kcal,
        model: result.model_used,
      });

      return result;

    } catch (error) {
      console.error('[PlanEngine] Generation failed:', error);
      throw error;
    }
  }

  // ═══════════════════════════════════════════════
  // LOCAL PERSISTENCE
  // ═══════════════════════════════════════════════

  /**
   * Save a generated plan + metadata to localStorage
   */
  function savePlan(apiResponse) {
    // Save plan data
    localStorage.setItem(PLAN_KEY, JSON.stringify(apiResponse.data));

    // Save metadata
    const meta = {
      generated_at: new Date().toISOString(),
      target_kcal: apiResponse.target_kcal,
      bmr: apiResponse.bmr,
      tdee: apiResponse.tdee,
      days_generated: apiResponse.days_generated,
      meals_per_day: apiResponse.meals_per_day,
      rag_context_used: apiResponse.rag_context_used,
      model_used: apiResponse.model_used,
      allergen_warnings: apiResponse.allergen_warnings || [],
    };
    localStorage.setItem(META_KEY, JSON.stringify(meta));

    // Reset daily progress for the new plan
    resetDayProgress();
  }

  /**
   * Load the saved plan from localStorage
   * @returns {object|null} plan data or null if no plan exists
   */
  function loadPlan() {
    try {
      const raw = localStorage.getItem(PLAN_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      console.error('[PlanEngine] Failed to load plan:', e);
      return null;
    }
  }

  /**
   * Load plan metadata
   */
  function loadMeta() {
    try {
      const raw = localStorage.getItem(META_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      return null;
    }
  }

  /**
   * Check if a plan exists and is still fresh (less than 7 days old)
   */
  function hasFreshPlan() {
    const meta = loadMeta();
    if (!meta || !meta.generated_at) return false;

    const generatedDate = new Date(meta.generated_at);
    const daysSinceGeneration = (Date.now() - generatedDate.getTime()) / (1000 * 60 * 60 * 24);
    return daysSinceGeneration < 7;
  }

  // ═══════════════════════════════════════════════
  // MEAL ACCESS
  // ═══════════════════════════════════════════════

  /**
   * Get meals for a specific day (1-indexed)
   * @param {number} dayNumber - 1 to 7
   * @returns {Array} array of meal objects or empty array
   */
  function getMealsForDay(dayNumber) {
    const plan = loadPlan();
    if (!plan) return [];

    const dayKey = `day_${dayNumber}`;
    const dayData = plan[dayKey];

    if (Array.isArray(dayData)) return dayData;
    if (dayData && dayData.meals && Array.isArray(dayData.meals)) return dayData.meals;
    return [];
  }

  /**
   * Get today's meals based on plan generation date
   * @returns {Array} array of meal objects for today
   */
  function getTodayMeals() {
    const meta = loadMeta();
    if (!meta || !meta.generated_at) return [];

    const generatedDate = new Date(meta.generated_at);
    const today = new Date();
    const dayIndex = Math.floor((today - generatedDate) / (1000 * 60 * 60 * 24)) + 1;
    const clampedDay = Math.max(1, Math.min(dayIndex, meta.days_generated || 7));

    return getMealsForDay(clampedDay);
  }

  /**
   * Get vitamins for a specific day
   */
  function getVitaminsForDay(dayNumber) {
    const plan = loadPlan();
    if (!plan) return [];

    // Check both formats
    const vitaminsKey = `vitamins_day_${dayNumber}`;
    if (plan[vitaminsKey]) return plan[vitaminsKey];

    const dayData = plan[`day_${dayNumber}`];
    if (dayData && dayData.vitamins) return dayData.vitamins;

    return [];
  }

  /**
   * Get daily tip for a specific day
   */
  function getDailyTip(dayNumber) {
    const plan = loadPlan();
    if (!plan) return '';

    const tipKey = `tip_day_${dayNumber}`;
    if (plan[tipKey]) return plan[tipKey];

    const dayData = plan[`day_${dayNumber}`];
    if (dayData && dayData.daily_tip) return dayData.daily_tip;

    return '';
  }

  // ═══════════════════════════════════════════════
  // EATEN TRACKING
  // ═══════════════════════════════════════════════

  function _getEaten() {
    try {
      return new Set(JSON.parse(localStorage.getItem(EATEN_KEY) || '[]'));
    } catch {
      return new Set();
    }
  }

  function _saveEaten(eatenSet) {
    localStorage.setItem(EATEN_KEY, JSON.stringify([...eatenSet]));
  }

  /**
   * Mark a meal as eaten
   * @param {number} dayNumber - day index (1-based)
   * @param {number} mealIndex - meal index within the day (0-based)
   */
  function markEaten(dayNumber, mealIndex) {
    const mealId = `day_${dayNumber}_meal_${mealIndex}`;
    const eaten = _getEaten();
    eaten.add(mealId);
    _saveEaten(eaten);

    // Update day progress
    const meals = getMealsForDay(dayNumber);
    if (meals[mealIndex]) {
      addToProgress(meals[mealIndex]);
    }
  }

  /**
   * Check if a meal is eaten
   */
  function isEaten(dayNumber, mealIndex) {
    const mealId = `day_${dayNumber}_meal_${mealIndex}`;
    return _getEaten().has(mealId);
  }

  // ═══════════════════════════════════════════════
  // DAY PROGRESS TRACKING
  // ═══════════════════════════════════════════════

  function getDayProgress() {
    try {
      const raw = localStorage.getItem(PROGRESS_KEY);
      if (!raw) return getEmptyProgress();
      const progress = JSON.parse(raw);
      
      // Check if progress is from today
      const today = new Date().toISOString().split('T')[0];
      if (progress.date !== today) {
        // New day — reset progress
        resetDayProgress();
        return getEmptyProgress();
      }
      return progress;
    } catch {
      return getEmptyProgress();
    }
  }

  function getEmptyProgress() {
    return {
      date: new Date().toISOString().split('T')[0],
      consumed_calories: 0,
      consumed_protein: 0,
      consumed_fat: 0,
      consumed_carbs: 0,
      consumed_fiber: 0,
    };
  }

  function resetDayProgress() {
    localStorage.setItem(PROGRESS_KEY, JSON.stringify(getEmptyProgress()));
    // Also clear eaten meals
    localStorage.setItem(EATEN_KEY, '[]');
  }

  /**
   * Add a meal's macros to today's progress
   */
  function addToProgress(meal) {
    const progress = getDayProgress();
    progress.consumed_calories += (meal.calories || 0);
    progress.consumed_protein += (meal.protein || meal.proteins || 0);
    progress.consumed_fat += (meal.fat || meal.fats || 0);
    progress.consumed_carbs += (meal.carbs || 0);
    progress.consumed_fiber += (meal.fiber || 0);
    localStorage.setItem(PROGRESS_KEY, JSON.stringify(progress));
  }

  // ═══════════════════════════════════════════════
  // SHOPPING LIST GENERATION (from plan)
  // ═══════════════════════════════════════════════

  /**
   * Generate a shopping list from the current plan
   * Groups ingredients by category and aggregates quantities
   * @param {number} maxDays - how many days to include (3 for Free, 7 for Black+)
   * @returns {object} { categories: { name: [{ name, amount, unit, bought }] } }
   */
  function generateShoppingList(maxDays) {
    const plan = loadPlan();
    if (!plan) return { categories: {} };

    const ingredients = {};
    const days = maxDays || 7;

    for (let d = 1; d <= days; d++) {
      const meals = getMealsForDay(d);
      meals.forEach(meal => {
        (meal.ingredients || []).forEach(ing => {
          const name = (ing.name || '').trim();
          if (!name) return;
          const key = name.toLowerCase();
          if (!ingredients[key]) {
            ingredients[key] = { name, amount: 0, unit: ing.unit || 'г', bought: false };
          }
          ingredients[key].amount += (ing.amount || 0);
        });
      });
    }

    // Simple category detection
    const CATEGORIES = {
      'Овощи': ['помидор', 'огурец', 'перец', 'лук', 'морковь', 'капуста', 'шпинат', 'свёкла', 'кабачок', 'баклажан', 'картофель', 'чеснок', 'салат', 'брокколи', 'цветная', 'авокадо', 'зелень', 'укроп', 'петрушка', 'базилик', 'руккола', 'сельдерей', 'редис', 'тыква', 'спаржа'],
      'Фрукты': ['яблоко', 'банан', 'апельсин', 'лимон', 'ягод', 'клубник', 'малин', 'черник', 'грейпфрут', 'киви', 'манго', 'персик', 'груша', 'виноград', 'гранат', 'слив', 'вишн', 'финик'],
      'Мясо и рыба': ['куриц', 'курин', 'филе', 'говядин', 'свинин', 'индейк', 'рыб', 'лосос', 'семг', 'треск', 'тунец', 'креветк', 'морепродукт', 'скумбри', 'форел', 'минтай', 'мяс'],
      'Молочные': ['молок', 'кефир', 'творог', 'йогурт', 'сметан', 'сыр', 'масло сливочн', 'сливк'],
      'Крупы и злаки': ['рис', 'гречк', 'овс', 'пшен', 'булгур', 'киноа', 'макарон', 'паст', 'хлеб', 'мука', 'крупа'],
      'Яйца и бобовые': ['яйц', 'нут', 'чечевиц', 'фасол', 'горох', 'тофу', 'соевый'],
      'Масла и соусы': ['масло оливков', 'масло растит', 'масло кокос', 'масло льняное', 'соус', 'уксус', 'горчиц'],
      'Орехи и семена': ['орех', 'миндал', 'грецк', 'кешью', 'фундук', 'семечк', 'тыквенн', 'кунжут', 'лён'],
      'Специи': ['соль', 'перец чёрн', 'куркум', 'корица', 'имбир', 'мускатн', 'паприк', 'орегано', 'тимьян'],
    };

    const categorized = {};
    Object.values(ingredients).forEach(ing => {
      const nameLower = ing.name.toLowerCase();
      let category = 'Другое';
      for (const [cat, keywords] of Object.entries(CATEGORIES)) {
        if (keywords.some(kw => nameLower.includes(kw))) {
          category = cat;
          break;
        }
      }
      if (!categorized[category]) categorized[category] = [];
      categorized[category].push(ing);
    });

    return { categories: categorized };
  }

  // ═══════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════

  window.PlanEngine = {
    // Generation
    generatePlan,
    // Persistence
    savePlan,
    loadPlan,
    loadMeta,
    hasFreshPlan,
    // Meal Access
    getMealsForDay,
    getTodayMeals,
    getVitaminsForDay,
    getDailyTip,
    // Eating
    markEaten,
    isEaten,
    // Day Progress
    getDayProgress,
    resetDayProgress,
    addToProgress,
    // Shopping
    generateShoppingList,
  };

})();
