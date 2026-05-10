/**
 * Health Code Subscription Gate — Unified Tier Access Control
 * 
 * Single source of truth for feature gating based on subscription tier.
 * Every screen uses SubscriptionGate.canAccess('feature') instead of
 * manual localStorage checks.
 * 
 * Tier hierarchy: base < trial < black < gold < group_gold
 * Trial = Gold-level access for 3 days after first launch.
 */

window.SubscriptionGate = (function() {

  // ============================================================
  // TIER DEFINITIONS
  // ============================================================

  /**
   * Feature access matrix — maps features to minimum required tier.
   * Based on access-levels.md v1.1 and screens-map.md v4.1.
   */
  const FEATURE_TIERS = {
    // Plan & Recipes
    'weekly_plan_full':      'black',    // 7 days (base = 3 days)
    'step_by_step_recipe':   'black',    // Пошаговый рецепт
    'meal_alternatives':     'black',    // Замена блюд (2 варианта — black, 3 — gold)
    'meal_correction':       'black',    // "Съел другое" ручной ввод
    'budget_cooking':        'black',    // Учёт бюджета и времени
    
    // Vitamins & Meds
    'vitamin_schedule':      'black',    // Расписание витаминов
    'vitamin_compatibility': 'black',    // Проверка совместимости
    'medication_tracking':   'black',    // Трекер лекарств
    
    // Shopping
    'shopping_weekly':       'black',    // Список на неделю (base = 3 дня)
    'shopping_price':        'black',    // Примерная стоимость
    
    // Progress & Reports
    'ai_report':             'black',    // AI-отчёт за неделю
    'report_history':        'black',    // История AI-отчётов
    'full_progress':         'black',    // Полный прогресс (активность, сон, вода)
    'health_connect':        'black',    // Apple Health / Google HC
    
    // Gold-only
    'photo_analysis':        'gold',     // Фото-анализ (5/день)
    'photo_meal_correction': 'gold',     // Коррекция плана через фото
    'workout_plan':          'gold',     // План тренировок
    'workout_videos':        'gold',     // Видео тренировок
    'ai_chat':               'gold',     // AI-чат (C-1)
    'quick_action_weight':   'gold',     // Быстрое действие "Вес"
    'quick_action_photo':    'gold',     // Быстрое действие "Фото"
    'theme_gold_status':     'gold',     // Золотая тема
    'theme_seasonal':        'gold',     // Сезонная тема
    'post_workout_replan':   'gold',     // AI-перерасчёт после >500ккал тренировки
    
    // Group Gold only
    'family_group':          'group_gold', // F-1, F-2
    'shared_meals':          'group_gold', // Общие блюда
    'shared_shopping':       'group_gold', // Общий список
    
    // Base features (always available)
    'basic_plan':            'base',     // 3-day plan
    'food_diary':            'base',     // Ручной дневник
    'calorie_ring':          'base',     // Кольцо калорий
    'water_tracker':         'base',     // Быстрое действие "Вода"
    'weight_graph_30d':      'base',     // График веса 30 дней
    'push_meals':            'base',     // Push о приёмах пищи
  };

  const TIER_RANK = {
    'base': 0,
    'trial': 3,      // Trial = Gold level
    'black': 1,
    'gold': 2,
    'group_gold': 3,
  };

  // ============================================================
  // PUBLIC API
  // ============================================================

  /**
   * Get current subscription tier.
   * @returns {string} Current tier: 'base' | 'trial' | 'black' | 'gold' | 'group_gold'
   */
  function getCurrentTier() {
    if (window.AppConfig && window.AppConfig.isReviewMode) {
      return 'gold'; // Fully unlocked for App Store Review
    }
    return localStorage.getItem('aidiet_subscription') || 'base';
  }

  /**
   * Check if user can access a feature.
   * @param {string} feature - Feature key from FEATURE_TIERS
   * @returns {boolean} True if access is allowed
   */
  function canAccess(feature) {
    const requiredTier = FEATURE_TIERS[feature];
    if (!requiredTier) {
      console.warn(`[SubscriptionGate] Unknown feature: ${feature}. Defaulting to allowed.`);
      return true;
    }

    const currentTier = getCurrentTier();
    const currentRank = TIER_RANK[currentTier] ?? 0;
    const requiredRank = TIER_RANK[requiredTier] ?? 0;

    return currentRank >= requiredRank;
  }

  /**
   * Get the number of meal alternatives allowed for current tier.
   * @returns {number} 1 (base), 2 (black), 3 (gold+)
   */
  function getMealAlternativesCount() {
    const tier = getCurrentTier();
    if (['gold', 'group_gold', 'trial'].includes(tier)) return 3;
    if (tier === 'black') return 2;
    return 1;
  }

  /**
   * Get the plan duration in days for current tier.
   * @returns {number} 3 (base) or 7 (paid)
   */
  function getPlanDays() {
    const tier = getCurrentTier();
    if (['black', 'gold', 'group_gold', 'trial'].includes(tier)) return 7;
    return 3;
  }

  /**
   * Get daily photo analysis limit for current tier.
   * @returns {number} 0 (base/black) or 5 (gold+)
   */
  function getPhotoLimit() {
    return canAccess('photo_analysis') ? 5 : 0;
  }

  /**
   * Check if the user is on a trial and it's still active.
   * @returns {boolean}
   */
  function isTrialActive() {
    if (getCurrentTier() !== 'trial') return false;
    const firstLaunch = localStorage.getItem('aidiet_first_launch');
    if (!firstLaunch) return false;
    const daysSince = (Date.now() - new Date(firstLaunch).getTime()) / (1000 * 60 * 60 * 24);
    return daysSince <= 3;
  }

  /**
   * Get remaining trial days (0 if not on trial or expired).
   * @returns {number}
   */
  function getTrialDaysRemaining() {
    if (!isTrialActive()) return 0;
    const firstLaunch = localStorage.getItem('aidiet_first_launch');
    const daysSince = (Date.now() - new Date(firstLaunch).getTime()) / (1000 * 60 * 60 * 24);
    return Math.max(0, Math.ceil(3 - daysSince));
  }

  /**
   * Apply lock UI to a locked element.
   * Adds lock icon overlay and click handler to navigate to status screen.
   * @param {HTMLElement} element - The element to lock
   * @param {string} requiredTier - Tier needed to unlock
   */
  function applyStatusWall(element, requiredTier) {
    if (!element) return;
    
    if (window.AppConfig && window.AppConfig.isReviewMode) {
      return; // Do not apply locks in Review Mode
    }

    element.style.position = 'relative';
    element.style.opacity = '0.5';
    element.style.pointerEvents = 'none';
    
    const lock = document.createElement('div');
    lock.className = 'status-lock';
    lock.innerHTML = `
      <div style="position:absolute;top:0;left:0;right:0;bottom:0;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,0.1);border-radius:inherit;pointer-events:auto;cursor:pointer;">
        <span style="font-size:20px;">🔒</span>
      </div>
    `;
    lock.querySelector('div').addEventListener('click', () => {
      // Open TG Bridge Modal instead of status screen
      if (window.TGBridge) {
        window.TGBridge.show();
      } else if (window.AIDietRouter) {
        window.AIDietRouter.navigate('o17-statuswall.html');
      } else {
        window.location.href = 'o17-statuswall.html';
      }
    });
    
    element.style.position = 'relative';
    element.appendChild(lock);
  }

  /**
   * Scan page for elements with data-gate attribute and apply locks.
   * Usage: <div data-gate="photo_analysis">...</div>
   */
  function scanAndGate() {
    document.querySelectorAll('[data-gate]').forEach(el => {
      const feature = el.getAttribute('data-gate');
      if (!canAccess(feature)) {
        applyStatusWall(el, FEATURE_TIERS[feature] || 'black');
      }
    });
  }

  // ============================================================
  // EXPORTS
  // ============================================================

  return {
    canAccess,
    getCurrentTier,
    getMealAlternativesCount,
    getPlanDays,
    getPhotoLimit,
    isTrialActive,
    getTrialDaysRemaining,
    applyStatusWall,
    scanAndGate,
    FEATURE_TIERS,
  };

})();
