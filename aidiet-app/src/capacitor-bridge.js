/**
 * capacitor-bridge.js
 * Мост между HTML-прототипами и нативными API (Capacitor)
 * 
 * Что делает:
 * - В браузере: всё работает через обычный localStorage (как сейчас)
 * - В нативном приложении: подключает камеру, вибрацию, безопасное хранилище
 * 
 * Подключается ПОСЛЕ app-utils.js и onboarding-state.js
 */

(function() {
  'use strict';

  // Определяем: мы в браузере или в нативном приложении?
  const isNative = typeof window.Capacitor !== 'undefined' && window.Capacitor.isNativePlatform();
  const platform = isNative ? window.Capacitor.getPlatform() : 'web';
  
  console.log(`[Bridge] Platform: ${platform}, Native: ${isNative}`);

  // ═══ 1. SAFE AREA (убираем "чёлку" iPhone) ═══
  if (isNative && platform === 'ios') {
    document.documentElement.style.setProperty(
      '--safe-area-top', 'env(safe-area-inset-top)'
    );
    document.documentElement.style.setProperty(
      '--safe-area-bottom', 'env(safe-area-inset-bottom)'
    );
    // Добавляем класс для CSS-таргетинга
    document.body.classList.add('native-ios');
  }
  if (isNative && platform === 'android') {
    document.body.classList.add('native-android');
  }

  // ═══ 2. HAPTICS (вибрация при нажатиях) ═══
  if (isNative) {
    // Переопределяем hapticImpact из app-utils.js
    window.hapticImpact = async function() {
      try {
        const { Haptics } = await import('@capacitor/haptics');
        await Haptics.impact({ style: 'light' });
      } catch (e) {
        // Haptics не установлен — тихо игнорируем
      }
    };
  }

  // ═══ 3. CAMERA (для фото-анализа PH-1) ═══
  window.AIDiet = window.AIDiet || {};
  
  window.AIDiet.takePhoto = async function() {
    if (!isNative) {
      // В браузере: обычный input[type=file]
      return new Promise((resolve) => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.capture = 'environment';
        input.onchange = (e) => {
          const file = e.target.files[0];
          if (file) {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.readAsDataURL(file);
          }
        };
        input.click();
      });
    }
    
    // В нативном: Capacitor Camera
    try {
      const { Camera, CameraResultType, CameraSource } = await import('@capacitor/camera');
      const photo = await Camera.getPhoto({
        quality: 80,
        allowEditing: false,
        resultType: CameraResultType.DataUrl,
        source: CameraSource.Camera,
        width: 1024,
        height: 1024
      });
      return photo.dataUrl;
    } catch (e) {
      console.warn('[Bridge] Camera error:', e);
      return null;
    }
  };

  // ═══ 4. STATUS BAR (для нативного приложения) ═══
  if (isNative) {
    document.addEventListener('DOMContentLoaded', async () => {
      try {
        const { StatusBar, Style } = await import('@capacitor/status-bar');
        await StatusBar.setStyle({ style: Style.Dark });
        await StatusBar.setBackgroundColor({ color: '#FAFAFA' });
      } catch (e) {
        // StatusBar не установлен
      }
    });
  }

  // ═══ 5. BACK BUTTON (Android hardware back) ═══
  if (isNative && platform === 'android') {
    document.addEventListener('backbutton', () => {
      const backBtn = document.querySelector('.btn-back');
      if (backBtn) {
        backBtn.click();
      } else {
        // На главном экране — ничего не делаем (не закрываем приложение)
      }
    });
  }

  // ═══ 6. API BASE URL ═══
  // В браузере: относительные пути (Vercel)
  // В нативном: полный URL бэкенда
  window.AIDiet.API_BASE = isNative 
    ? 'https://aidiet-api.onrender.com' 
    : '';

  // ═══ 7. STATUS SYNC (appStateChange → проверка статуса) ═══
  // При возврате в приложение (из Telegram) — дёргаем backend для проверки
  // обновлённого subscription_status.
  if (isNative) {
    (async () => {
      try {
        const { App } = await import('@capacitor/app');
        App.addListener('appStateChange', async ({ isActive }) => {
          if (!isActive) return;
          console.log('[Bridge] App resumed — syncing subscription status...');
          _syncSubscriptionStatus();
        });
      } catch (e) {
        console.warn('[Bridge] App plugin not available:', e);
      }
    })();
  }

  /**
   * Проверить статус подписки на сервере и обновить локально.
   * Вызывается при возврате в приложение (из Telegram после оплаты).
   */
  async function _syncSubscriptionStatus() {
    try {
      // Берём UUID
      let uuid = 'unknown';
      try {
        const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
        uuid = profile.anonymous_uuid || localStorage.getItem('aidiet_anonymous_uuid') || 'unknown';
      } catch (e) { /* ignore */ }

      if (uuid === 'unknown') return;

      const base = window.AIDiet.API_BASE || '';
      const resp = await fetch(`${base}/api/v1/subscription/status?uuid=${uuid}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!resp.ok) return;

      const data = await resp.json();
      if (data.tier && data.tier !== localStorage.getItem('aidiet_subscription')) {
        console.log(`[Bridge] Tier updated: ${localStorage.getItem('aidiet_subscription')} → ${data.tier}`);
        localStorage.setItem('aidiet_subscription', data.tier);
        
        // Dispatch event for live UI updates
        window.dispatchEvent(new CustomEvent('aidiet:tierChanged', { 
          detail: { tier: data.tier } 
        }));
      }
    } catch (e) {
      console.warn('[Bridge] Status sync failed:', e);
    }
  }

  // Expose for manual sync (e.g., pull-to-refresh)
  window.AIDiet.syncStatus = _syncSubscriptionStatus;

  // ═══ 8. МЕТКА ═══
  window.AIDiet._bridge = {
    version: '2.0.0',
    platform: platform,
    isNative: isNative
  };

  console.log(`[Bridge] Ready. API: ${window.AIDiet.API_BASE || 'relative'}`);
})();
