/**
 * tg-bridge-modal.js v1.0
 * Telegram Bridge Modal — мост в TG Concierge для управления статусом.
 *
 * Вызывается когда пользователь пытается использовать премиум-фичу
 * без активного статуса. Показывает модальное окно с deep link
 * в @healthcode_bot.
 *
 * Используется вместо экрана статуса — в приложении НЕТ экранов покупки.
 */

(function() {
  'use strict';

  const TG_BOT_USERNAME = 'healthcode_bot';
  let _modalElement = null;

  /**
   * Получить UUID пользователя из aidiet_profile.
   */
  function _getUserUUID() {
    try {
      const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
      return profile.anonymous_uuid || localStorage.getItem('aidiet_anonymous_uuid') || 'unknown';
    } catch (e) {
      return localStorage.getItem('aidiet_anonymous_uuid') || 'unknown';
    }
  }

  /**
   * Сформировать deep link в Telegram бот.
   */
  function _getTelegramDeepLink() {
    const uuid = _getUserUUID();
    return `tg://resolve?domain=${TG_BOT_USERNAME}&start=${uuid}`;
  }

  /**
   * Fallback ссылка (если tg:// не поддерживается).
   */
  function _getTelegramWebLink() {
    const uuid = _getUserUUID();
    return `https://t.me/${TG_BOT_USERNAME}?start=${uuid}`;
  }

  /**
   * Создать и показать модальное окно.
   * @param {string} [featureName] — название функции для персонализации текста
   */
  function show(featureName) {
    // Не дублировать
    if (_modalElement) return;

    const overlay = document.createElement('div');
    overlay.id = 'tg-bridge-overlay';
    overlay.style.cssText = `
      position: fixed; inset: 0; z-index: 99999;
      background: rgba(0,0,0,0.55); backdrop-filter: blur(8px);
      display: flex; align-items: flex-end; justify-content: center;
      padding: 0 16px 32px;
      opacity: 0; transition: opacity 0.25s ease;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    `;

    const featureText = featureName
      ? `Функция «${featureName}» доступна в премиум-статусе.`
      : 'Доступ к аналитике ограничен.';

    overlay.innerHTML = `
      <div id="tg-bridge-card" style="
        background: #FFFFFF; border-radius: 24px 24px 24px 24px;
        padding: 32px 24px 28px; max-width: 400px; width: 100%;
        box-shadow: 0 -4px 40px rgba(0,0,0,0.15);
        transform: translateY(100px); opacity: 0;
        transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
      ">
        <!-- Telegram icon -->
        <div style="width:64px;height:64px;border-radius:16px;background:linear-gradient(135deg,#2AABEE,#229ED9);display:flex;align-items:center;justify-content:center;margin:0 auto 20px;">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
            <path d="M20.665 3.717l-17.73 6.837c-1.21.486-1.203 1.161-.222 1.462l4.552 1.42 10.532-6.645c.498-.303.953-.14.579.192l-8.533 7.701h-.002l.002.001-.314 4.692c.46 0 .663-.211.921-.46l2.211-2.15 4.599 3.397c.848.467 1.457.227 1.668-.787l3.019-14.228c.309-1.239-.473-1.8-1.282-1.432z" fill="white"/>
          </svg>
        </div>

        <!-- Title -->
        <div style="font-size:20px;font-weight:800;color:#1A1A1A;text-align:center;line-height:1.3;margin-bottom:8px;">
          Telegram-ассистент<br>Health Code
        </div>

        <!-- Description -->
        <div style="font-size:14px;color:#6B7280;text-align:center;line-height:1.6;margin-bottom:24px;">
          ${featureText}<br>
          Для управления доступом и настройками подключи своего Telegram-ассистента.
        </div>

        <!-- Primary CTA -->
        <button id="tg-bridge-open-btn" style="
          width:100%;height:52px;border:none;border-radius:14px;
          background:linear-gradient(135deg,#2AABEE,#229ED9);
          color:#fff;font-size:16px;font-weight:700;
          cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;
          box-shadow:0 4px 16px rgba(42,171,238,0.35);
          transition:transform 0.15s, box-shadow 0.15s;
        ">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M20.665 3.717l-17.73 6.837c-1.21.486-1.203 1.161-.222 1.462l4.552 1.42 10.532-6.645c.498-.303.953-.14.579.192l-8.533 7.701h-.002l.002.001-.314 4.692c.46 0 .663-.211.921-.46l2.211-2.15 4.599 3.397c.848.467 1.457.227 1.668-.787l3.019-14.228c.309-1.239-.473-1.8-1.282-1.432z" fill="white"/>
          </svg>
          Открыть Telegram
        </button>

        <!-- Secondary -->
        <button id="tg-bridge-close-btn" style="
          width:100%;height:44px;border:none;background:transparent;
          color:#9CA3AF;font-size:13px;font-weight:600;cursor:pointer;
          margin-top:8px;
        ">
          Не сейчас
        </button>
      </div>
    `;

    document.body.appendChild(overlay);
    _modalElement = overlay;

    // Animate in
    requestAnimationFrame(() => {
      overlay.style.opacity = '1';
      const card = overlay.querySelector('#tg-bridge-card');
      if (card) {
        card.style.transform = 'translateY(0)';
        card.style.opacity = '1';
      }
    });

    // Open Telegram
    overlay.querySelector('#tg-bridge-open-btn').addEventListener('click', () => {
      const deepLink = _getTelegramDeepLink();
      const webLink = _getTelegramWebLink();

      // Try native deep link first, fallback to web
      const start = Date.now();
      window.location.href = deepLink;

      // If deep link didn't work (no Telegram installed), fallback after 1.5s
      setTimeout(() => {
        if (Date.now() - start < 2000) {
          window.open(webLink, '_blank');
        }
      }, 1500);
    });

    // Close
    overlay.querySelector('#tg-bridge-close-btn').addEventListener('click', hide);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) hide();
    });

    // Haptic feedback
    if (window.hapticImpact) window.hapticImpact();
  }

  /**
   * Скрыть модальное окно.
   */
  function hide() {
    if (!_modalElement) return;

    const card = _modalElement.querySelector('#tg-bridge-card');
    if (card) {
      card.style.transform = 'translateY(100px)';
      card.style.opacity = '0';
    }
    _modalElement.style.opacity = '0';

    setTimeout(() => {
      if (_modalElement && _modalElement.parentNode) {
        _modalElement.parentNode.removeChild(_modalElement);
      }
      _modalElement = null;
    }, 350);
  }

  /**
   * Проверить доступ к фиче и показать модал при блокировке.
   * @param {string} feature — ключ фичи из SubscriptionGate.FEATURE_TIERS
   * @param {string} [featureName] — человекочитаемое название
   * @returns {boolean} true если доступ разрешён
   */
  function checkAccessOrShow(feature, featureName) {
    if (window.SubscriptionGate && window.SubscriptionGate.canAccess(feature)) {
      return true;
    }
    show(featureName);
    return false;
  }

  // === Public API ===
  window.TGBridge = {
    show,
    hide,
    checkAccessOrShow,
    getTelegramLink: _getTelegramWebLink,
  };

  console.log('[TGBridge] Module loaded');
})();
