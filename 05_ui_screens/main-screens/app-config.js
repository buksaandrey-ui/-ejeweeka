/**
 * Health Code App Config
 * Handles global configuration and App Store Review Mode
 */

window.AppConfig = (function() {
    // In a real production build, this might be fetched from an API
    // e.g., GET /api/v1/config -> { "review_mode": true }
    // For now, we simulate the fetch or use a hardcoded value.
    const CONFIG = {
        review_mode: false // SET TO TRUE DURING APP STORE REVIEW
    };

    /**
     * Fetch configuration from the backend
     * For now, we mock it.
     */
    async function fetchConfig() {
        try {
            // Uncomment to use real API
            // const response = await fetch('https://aidiet-api.onrender.com/api/v1/config');
            // const data = await response.json();
            // CONFIG.review_mode = data.review_mode;
        } catch (e) {
            console.warn('[AppConfig] Failed to fetch config, using defaults', e);
        }
    }

    return {
        init: fetchConfig,
        get isReviewMode() {
            return CONFIG.review_mode;
        }
    };
})();
