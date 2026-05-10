/**
 * Health Code SPA Router v1.0
 * 
 * Lightweight router for shell.html — eliminates full-page reload flickering
 * by keeping the tab bar persistent and loading screens into an iframe.
 * 
 * Strategy: iframe-based routing
 * - shell.html = persistent frame (status bar + tab bar + iframe)
 * - Each screen loads in the iframe as-is (no modifications needed)
 * - Tab bar clicks intercept navigation and update iframe.src
 * - Deep links (from within screens) work naturally via iframe navigation
 * 
 * This approach is chosen because:
 * 1. Zero changes needed to existing 50+ screen HTML files
 * 2. Tab bar stays visually stable (no repaint/flicker)
 * 3. Back button works naturally (iframe history)
 * 4. Compatible with Capacitor (WKWebView)
 */

window.AIDietRouter = (function() {

  // Tab definitions — must match tab-bar in shell.html
  const TABS = [
    { id: 'home',     href: 'h1-dashboard.html',   icon: 'ph-house',         iconFill: 'ph-fill ph-house',   label: 'Главная' },
    { id: 'plan',     href: 'p1-weekly-plan.html',  icon: 'ph-calendar-check', iconFill: 'ph-fill ph-calendar-check', label: 'План' },
    { id: 'shopping', href: 's1-shopping-list.html', icon: 'ph-shopping-cart', iconFill: 'ph-fill ph-shopping-cart', label: 'Покупки' },
    { id: 'progress', href: 'pr1-progress.html',    icon: 'ph-chart-line-up', iconFill: 'ph-fill ph-chart-line-up', label: 'Прогресс' },
    { id: 'profile',  href: 'u1-profile-main.html', icon: 'ph-user',          iconFill: 'ph-fill ph-user',    label: 'Профиль' },
  ];

  let currentTab = null;
  let iframe = null;

  /**
   * Initialize router — call once from shell.html DOMContentLoaded.
   */
  function init() {
    iframe = document.getElementById('app-frame');
    if (!iframe) {
      console.error('[Router] #app-frame not found');
      return;
    }

    // Bind tab clicks
    document.querySelectorAll('.shell-tab').forEach(tab => {
      tab.addEventListener('click', (e) => {
        e.preventDefault();
        const href = tab.dataset.href;
        if (href) navigate(href);
      });
    });

    // Listen for navigation inside iframe (to update active tab)
    iframe.addEventListener('load', onIframeLoad);

    // Determine initial screen
    const hash = window.location.hash.slice(1);
    const initialScreen = hash || getDefaultScreen();
    navigate(initialScreen, false);

    console.log('[Router] Initialized');
  }

  /**
   * Navigate to a screen.
   * @param {string} href - Screen filename (e.g. 'p1-weekly-plan.html')
   * @param {boolean} pushState - Whether to update URL hash
   */
  function navigate(href, pushState = true) {
    if (!iframe) return;

    // Normalize href (strip path, keep filename)
    const filename = href.split('/').pop().split('?')[0].split('#')[0];

    // Update iframe
    iframe.src = filename + (href.includes('?') ? '?' + href.split('?')[1] : '');

    // Update hash for deep linking
    if (pushState) {
      window.location.hash = filename;
    }

    // Update active tab
    updateActiveTab(filename);
  }

  /**
   * Update which tab is visually active.
   */
  function updateActiveTab(filename) {
    const matchedTab = TABS.find(t => t.href === filename);

    document.querySelectorAll('.shell-tab').forEach(tab => {
      const tabHref = tab.dataset.href;
      const isActive = matchedTab && tabHref === matchedTab.href;

      tab.classList.toggle('active', isActive);

      // Swap icon: filled when active, outline when inactive
      const icon = tab.querySelector('i');
      if (icon) {
        const tabDef = TABS.find(t => t.href === tabHref);
        if (tabDef) {
          icon.className = isActive ? tabDef.iconFill : `ph ${tabDef.icon}`;
        }
      }
    });

    currentTab = matchedTab?.id || null;
  }

  /**
   * Called when iframe finishes loading a page.
   * Hides the iframe's own tab-bar to prevent duplication.
   */
  function onIframeLoad() {
    try {
      const doc = iframe.contentDocument || iframe.contentWindow?.document;
      if (!doc) return;

      // Hide the tab-bar/bottom-nav inside the iframe (since shell has its own)
      const innerNav = doc.querySelector('.tab-bar, .bottom-nav');
      if (innerNav) {
        innerNav.style.display = 'none';
      }

      // Reduce bottom padding in content (no longer need space for tab bar)
      const content = doc.querySelector('.content');
      if (content) {
        content.style.paddingBottom = '20px';
      }

      // Hide the phone frame border inside iframe (shell provides it)
      const phone = doc.querySelector('.phone');
      if (phone) {
        phone.style.borderRadius = '0';
        phone.style.boxShadow = 'none';
        phone.style.height = '100%';
        phone.style.width = '100%';
      }

      // Hide inner status bar (shell provides it)
      const statusBar = doc.querySelector('.status-bar');
      if (statusBar) {
        statusBar.style.display = 'none';
      }

      // Intercept tab-bar link clicks inside iframe to use router
      const innerLinks = doc.querySelectorAll('a[href]');
      innerLinks.forEach(link => {
        const href = link.getAttribute('href');
        // Only intercept main tab links
        if (TABS.some(t => t.href === href)) {
          link.addEventListener('click', (e) => {
            e.preventDefault();
            navigate(href);
          });
        }
      });

      // Update active tab based on what was loaded
      const loadedUrl = iframe.contentWindow?.location?.pathname;
      if (loadedUrl) {
        const filename = loadedUrl.split('/').pop();
        updateActiveTab(filename);
      }

    } catch (e) {
      // Cross-origin restriction — ignore
    }
  }

  /**
   * Get default screen based on app state.
   */
  function getDefaultScreen() {
    // If onboarding not complete, go to onboarding
    const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
    if (!profile['Главная цель'] && !profile['onboarding_complete']) {
      return 'o1-welcome.html';
    }
    return 'h1-dashboard.html';
  }

  /**
   * Go back in iframe history.
   */
  function goBack() {
    if (iframe?.contentWindow) {
      iframe.contentWindow.history.back();
    }
  }

  // Handle browser back/forward
  window.addEventListener('hashchange', () => {
    const hash = window.location.hash.slice(1);
    if (hash && iframe) {
      const currentSrc = iframe.src.split('/').pop().split('?')[0];
      if (currentSrc !== hash) {
        navigate(hash, false);
      }
    }
  });

  return {
    init,
    navigate,
    goBack,
    TABS,
  };

})();
