/**
 * Health Code API Connector v3.0 (Offline First)
 * Связывает фронтенд с бэкендом.
 * 
 * v3.0 Changes:
 * - Full Offline-First support (caching meal plans and subscription status).
 * - Standardized English canonical keys for all payloads.
 * - Improved error handling for unreliable internet (RF mobile internet support).
 */

const API_BASE = (window.AIDiet && window.AIDiet.API_BASE)
  ? window.AIDiet.API_BASE
  : (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? 'http://localhost:8001'   
    : 'https://aidiet-api.onrender.com';

const AUTH_TOKEN_KEY = 'aidiet_auth_token';
const AUTH_UUID_KEY = 'aidiet_anonymous_uuid';
const CACHE_PLAN_KEY = 'aidiet_meal_plan';
const CACHE_SUBS_KEY = 'aidiet_subscription_data';

// ============================================================
// AUTH
// ============================================================

async function initAuth() {
  const existing = localStorage.getItem(AUTH_TOKEN_KEY);
  if (existing) return existing;

  try {
    const response = await fetch(`${API_BASE}/api/v1/auth/init`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });

    if (response.ok) {
      const data = await response.json();
      if (data.token) {
        localStorage.setItem(AUTH_TOKEN_KEY, data.token);
        localStorage.setItem(AUTH_UUID_KEY, data.anonymous_uuid || '');
        return data.token;
      }
    }
  } catch (e) {
    console.warn('[Auth] Network error during init');
  }
  return null;
}

async function apiFetch(path, options = {}, maxRetries = 2) {
  const token = localStorage.getItem(AUTH_TOKEN_KEY);
  const headers = options.headers || {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  
  if (options.body && !(options.body instanceof FormData) && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }
  
  let lastError;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(`${API_BASE}${path}`, { ...options, headers });
      if (response.ok || (response.status >= 400 && response.status < 500 && response.status !== 429)) {
        return response;
      }
      lastError = new Error(`API error: ${response.status}`);
    } catch (e) {
      lastError = e;
      if (attempt < maxRetries) {
        const delay = Math.pow(2, attempt) * 1000;
        await new Promise(r => setTimeout(r, delay));
      }
    }
  }
  throw lastError;
}

// ============================================================
// OFFLINE FIRST: SUBSCRIPTION & PLAN
// ============================================================

/**
 * Syncs subscription with server, but falls back to CACHE for offline access.
 */
async function checkSubscription() {
  try {
    const response = await apiFetch('/api/v1/billing/status', { method: 'GET' }, 1);
    if (response.ok) {
      const data = await response.json();
      localStorage.setItem('aidiet_subscription', data.tier || 'base');
      localStorage.setItem(CACHE_SUBS_KEY, JSON.stringify(data));
      return data;
    }
  } catch (e) {
    console.warn('[Offline] Using cached subscription data');
  }
  
  const cached = localStorage.getItem(CACHE_SUBS_KEY);
  return cached ? JSON.parse(cached) : { tier: localStorage.getItem('aidiet_subscription') || 'base', is_trial: false };
}

/**
 * Returns stored meal plan for offline viewing.
 */
function getStoredPlan() {
  const plan = localStorage.getItem(CACHE_PLAN_KEY);
  return plan ? JSON.parse(plan) : null;
}

// ============================================================
// PLAN GENERATION
// ============================================================

async function generatePlanAPI(onStep) {
  if (!window.AIDietAPI || !window.AIDietAPI.buildPlanPayload) {
    throw new Error('Critical: profile-to-api.js not loaded');
  }

  const payload = window.AIDietAPI.buildPlanPayload();
  if (onStep) onStep('Синхронизируем профиль…');

  try {
    const response = await apiFetch('/api/v1/plan/generate', {
      method: 'POST',
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({}));
      throw new Error(err.detail || 'Server error');
    }

    const result = await response.json();
    if (onStep) onStep('Персональный план готов!');

    // Caching & Day Shifting logic
    let planData = result.data;
    if (typeof planData === 'string') planData = JSON.parse(planData);
    
    // Shift days: day_1 = Today
    const offset = (new Date().getDay() || 7) - 1;
    const shiftedPlan = {};
    Object.keys(planData).forEach(key => {
      const match = key.match(/^(day_|vitamins_day_|tip_day_)(\d+)$/);
      if (match) {
        let newNum = parseInt(match[2]) + offset;
        while (newNum > 7) newNum -= 7;
        shiftedPlan[`${match[1]}${newNum}`] = planData[key];
      } else {
        shiftedPlan[key] = planData[key];
      }
    });

    localStorage.setItem(CACHE_PLAN_KEY, JSON.stringify(shiftedPlan));
    
    // Save metadata
    if (result.target_kcal && window.AIDiet.saveField) {
      window.AIDiet.saveField('target_daily_calories', result.target_kcal);
    }
    
    return result;
  } catch (error) {
    console.error('[Plan] Generation failed:', error);
    const cached = getStoredPlan();
    if (cached) {
      console.log('[Offline] Falling back to cached plan');
      return { data: cached, is_offline: true };
    }
    throw error;
  }
}

// ============================================================
// PHOTO ANALYSIS
// ============================================================

async function analyzePhotoAPI(imageBlob, onStep) {
  const ctx = window.AIDietAPI.buildPhotoContext();
  const formData = new FormData();
  formData.append('photo', imageBlob, 'photo.jpg');
  formData.append('goal', ctx.goal || '');
  formData.append('allergies', ctx.allergies || '[]');
  formData.append('diseases', ctx.diseases || '[]');
  formData.append('daily_calories', String(ctx.daily_calories || 2000));
  
  if (onStep) onStep('Анализируем фото через AI…');

  const response = await apiFetch('/api/v1/photo/analyze', { method: 'POST', body: formData });
  if (!response.ok) throw new Error('Photo API error');
  return await response.json();
}

// master init
async function initAIDietAPI() {
  await initAuth();
  await checkSubscription();
  
  // Trial logic
  const firstLaunch = localStorage.getItem('aidiet_first_launch');
  if (!firstLaunch) {
    localStorage.setItem('aidiet_first_launch', new Date().toISOString());
    localStorage.setItem('aidiet_subscription', 'gold');
    localStorage.setItem('aidiet_trial_active', 'true');
  } else {
    const days = (new Date() - new Date(firstLaunch)) / (1000 * 60 * 60 * 24);
    if (localStorage.getItem('aidiet_trial_active') === 'true' && days > 3) {
      localStorage.setItem('aidiet_subscription', 'base');
      localStorage.setItem('aidiet_trial_active', 'false');
    }
  }
}

window.AIDietAPI_Core = {
  generatePlanAPI,
  analyzePhotoAPI,
  checkSubscription,
  getStoredPlan,
  init: initAIDietAPI
};
