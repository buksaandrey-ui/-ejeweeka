/**
 * auth-manager.js — Anonymous Authentication Manager
 * 
 * PURPOSE: Handles anonymous UUID + token lifecycle.
 * On first app launch, calls POST /api/v1/auth/init to get UUID + token.
 * On subsequent launches, verifies the token and refreshes if expired.
 * 
 * DEPENDS ON: profile-to-api.js (for saveAuth/getAuthToken helpers)
 * 
 * USAGE:
 *   await window.AIDietAuth.ensureAuth();
 *   const token = window.AIDietAPI.getAuthToken();
 */

(function() {
  'use strict';

  const API_BASE = (function() {
    // Auto-detect API URL from env or localStorage
    const stored = localStorage.getItem('aidiet_api_url');
    if (stored) return stored;
    // Production default
    return 'https://aidiet-api.onrender.com';
  })();

  /**
   * Initialize authentication — call on every app launch
   * Returns { uuid, token } or throws
   */
  async function ensureAuth() {
    const existingToken = window.AIDietAPI.getAuthToken();
    const existingUUID = window.AIDietAPI.getAnonymousUUID();

    // If we have a token, verify it
    if (existingToken && existingUUID) {
      try {
        const isValid = await verifyToken(existingToken);
        if (isValid) {
          console.log('[Auth] Token valid, UUID:', existingUUID.substring(0, 8) + '...');
          return { uuid: existingUUID, token: existingToken };
        }
      } catch (e) {
        console.warn('[Auth] Token verification failed, will re-init:', e.message);
      }
    }

    // No valid token — initialize new anonymous session
    console.log('[Auth] Initializing new anonymous session...');
    return await initAnonymous();
  }

  /**
   * POST /api/v1/auth/init — creates anonymous UUID + token
   */
  async function initAnonymous() {
    try {
      const response = await fetch(`${API_BASE}/api/v1/auth/init`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) {
        throw new Error(`Auth init failed: ${response.status}`);
      }

      const data = await response.json();
      const uuid = data.anonymous_uuid;
      const token = data.token;

      if (!uuid || !token) {
        throw new Error('Auth init returned empty UUID or token');
      }

      window.AIDietAPI.saveAuth(uuid, token);
      console.log('[Auth] New session initialized, UUID:', uuid.substring(0, 8) + '...');
      return { uuid, token };
    } catch (e) {
      console.error('[Auth] Init failed:', e);
      // Offline fallback — generate local UUID, skip token
      const localUUID = crypto.randomUUID ? crypto.randomUUID() : 'local-' + Date.now();
      window.AIDietAPI.saveAuth(localUUID, '');
      console.warn('[Auth] Using offline fallback UUID:', localUUID.substring(0, 8) + '...');
      return { uuid: localUUID, token: '' };
    }
  }

  /**
   * POST /api/v1/auth/verify — checks if token is still valid
   */
  async function verifyToken(token) {
    try {
      const response = await fetch(`${API_BASE}/api/v1/auth/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token }),
      });

      if (!response.ok) return false;
      const data = await response.json();
      return data.valid === true;
    } catch (e) {
      // Network error — assume token is valid (offline mode)
      console.warn('[Auth] Verify network error, assuming valid for offline mode');
      return true;
    }
  }

  /**
   * Build Authorization header value
   */
  function getAuthHeader() {
    const token = window.AIDietAPI.getAuthToken();
    return token ? `Bearer ${token}` : '';
  }

  /**
   * Make an authenticated API request with retry logic
   * @param {string} path - API path (e.g., '/api/v1/plan/generate')
   * @param {object} options - fetch options (method, body, etc.)
   * @param {number} retries - number of retries (default 2)
   * @returns {Promise<object>} parsed JSON response
   */
  async function apiRequest(path, options = {}, retries = 2) {
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    const authHeader = getAuthHeader();
    if (authHeader) {
      headers['Authorization'] = authHeader;
    }

    const fetchOptions = {
      ...options,
      headers,
    };

    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const response = await fetch(`${API_BASE}${path}`, fetchOptions);

        if (response.status === 401) {
          // Token expired — re-init and retry
          console.warn('[Auth] 401 received, re-initializing...');
          await initAnonymous();
          headers['Authorization'] = getAuthHeader();
          continue;
        }

        if (!response.ok) {
          const errorBody = await response.text().catch(() => '');
          throw new Error(`API ${response.status}: ${errorBody.substring(0, 200)}`);
        }

        return await response.json();
      } catch (e) {
        if (attempt < retries) {
          const delay = Math.pow(2, attempt) * 1000; // exponential backoff: 1s, 2s
          console.warn(`[Auth] Request failed (attempt ${attempt + 1}/${retries + 1}), retrying in ${delay}ms...`);
          await new Promise(r => setTimeout(r, delay));
          continue;
        }
        throw e;
      }
    }
  }

  // ═══════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════

  window.AIDietAuth = {
    ensureAuth,
    getAuthHeader,
    apiRequest,
    API_BASE,
  };

})();
