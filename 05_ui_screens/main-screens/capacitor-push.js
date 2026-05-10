/**
 * capacitor-push.js v1.0
 * Push Notifications Bridge for Health Code
 * 
 * In native app: uses @capacitor/push-notifications (FCM/APNs)
 * In browser: uses Notification API (if available)
 * 
 * Prerequisites:
 * 1. npm install @capacitor/push-notifications
 * 2. npx cap sync
 * 3. Firebase project → google-services.json (Android) + GoogleService-Info.plist (iOS)
 * 
 * Usage:
 *   AIDiet.push.init()        — request permissions + register token
 *   AIDiet.push.schedule(...)  — schedule local notification  
 */

(function() {
  'use strict';

  const isNative = typeof window.Capacitor !== 'undefined' && window.Capacitor.isNativePlatform();
  window.AIDiet = window.AIDiet || {};

  let _registered = false;

  /**
   * Initialize push notifications.
   * Requests permission and registers device token with backend.
   */
  async function init() {
    if (!isNative) {
      console.log('[Push] Web mode — using Notification API fallback');
      
      // Browser: request Notification permission
      if ('Notification' in window && Notification.permission === 'default') {
        await Notification.requestPermission();
      }
      _registered = true;
      return;
    }

    try {
      const { PushNotifications } = await import('@capacitor/push-notifications');

      // Request permission
      const permResult = await PushNotifications.requestPermissions();
      if (permResult.receive !== 'granted') {
        console.warn('[Push] Permission denied');
        return;
      }

      // Register for push
      await PushNotifications.register();

      // Token received — send to backend
      PushNotifications.addListener('registration', async (token) => {
        console.log('[Push] Token:', token.value.substring(0, 20) + '...');
        await _registerToken(token.value);
        _registered = true;
      });

      // Registration error
      PushNotifications.addListener('registrationError', (err) => {
        console.error('[Push] Registration error:', err);
      });

      // Notification received while app is in foreground
      PushNotifications.addListener('pushNotificationReceived', (notification) => {
        console.log('[Push] Received:', notification.title);
        _handleForegroundNotification(notification);
      });

      // Notification tapped (app was in background)
      PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
        console.log('[Push] Tapped:', action.notification?.title);
        _handleNotificationTap(action.notification);
      });

    } catch (e) {
      console.error('[Push] Init failed:', e);
    }
  }

  /**
   * Register device token with backend.
   */
  async function _registerToken(token) {
    try {
      const apiBase = window.AIDiet?.API_BASE || '';
      const authToken = localStorage.getItem('aidiet_token') || '';
      const platform = window.Capacitor?.getPlatform() || 'web';

      await fetch(`${apiBase}/api/v1/push/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`,
        },
        body: JSON.stringify({
          device_token: token,
          platform: platform,
        }),
      });

      console.log('[Push] Token registered with backend');
    } catch (e) {
      console.warn('[Push] Token registration failed:', e);
    }
  }

  /**
   * Handle notification when app is in foreground.
   * Shows a subtle in-app banner instead of OS notification.
   */
  function _handleForegroundNotification(notification) {
    // Create in-app banner
    const banner = document.createElement('div');
    banner.style.cssText = `
      position: fixed; top: 60px; left: 20px; right: 20px;
      background: rgba(255,255,255,0.96); backdrop-filter: blur(20px);
      border-radius: 16px; padding: 16px 20px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.12);
      z-index: 99999; display: flex; gap: 12px; align-items: center;
      transform: translateY(-100px); opacity: 0;
      transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      font-family: 'Inter', -apple-system, sans-serif;
    `;
    banner.innerHTML = `
      <div style="width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,#F59520,#E07018);display:flex;align-items:center;justify-content:center;flex-shrink:0">
        <span style="color:#fff;font-size:20px">🍎</span>
      </div>
      <div style="flex:1;min-width:0">
        <div style="font-weight:600;font-size:14px;color:#1A1A1A">${notification.title || 'Health Code'}</div>
        <div style="font-size:13px;color:#6B7280;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${notification.body || ''}</div>
      </div>
    `;
    document.body.appendChild(banner);

    // Animate in
    requestAnimationFrame(() => {
      banner.style.transform = 'translateY(0)';
      banner.style.opacity = '1';
    });

    // Auto-dismiss after 4s
    setTimeout(() => {
      banner.style.transform = 'translateY(-100px)';
      banner.style.opacity = '0';
      setTimeout(() => banner.remove(), 300);
    }, 4000);

    // Tap to dismiss
    banner.addEventListener('click', () => {
      banner.remove();
      _handleNotificationTap(notification);
    });
  }

  /**
   * Handle notification tap — navigate to relevant screen.
   */
  function _handleNotificationTap(notification) {
    const data = notification?.data || {};
    const screen = data.screen;

    if (screen) {
      // Navigate to specific screen
      window.location.href = screen;
    }
  }

  /**
   * Schedule a local notification (for meal/water/vitamin reminders).
   * Uses Capacitor Local Notifications plugin.
   */
  async function scheduleLocal(title, body, delayMinutes = 0, data = {}) {
    if (!isNative) {
      // Browser: use Notification API
      if ('Notification' in window && Notification.permission === 'granted') {
        if (delayMinutes > 0) {
          setTimeout(() => new Notification(title, { body }), delayMinutes * 60000);
        } else {
          new Notification(title, { body });
        }
      }
      return;
    }

    try {
      const { LocalNotifications } = await import('@capacitor/local-notifications');
      
      const scheduleAt = new Date(Date.now() + delayMinutes * 60000);
      
      await LocalNotifications.schedule({
        notifications: [{
          title,
          body,
          id: Math.floor(Math.random() * 100000),
          schedule: { at: scheduleAt },
          extra: data,
        }]
      });

      console.log(`[Push] Local notification scheduled: "${title}" in ${delayMinutes}min`);
    } catch (e) {
      console.warn('[Push] Local notification failed:', e);
    }
  }

  // === Public API ===
  window.AIDiet.push = {
    init,
    scheduleLocal,
    isRegistered: () => _registered,
  };

  console.log('[Push] Module loaded');
})();
