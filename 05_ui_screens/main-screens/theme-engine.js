/**
 * Health Code Theme Engine v1.0
 * 
 * 8 цветовых схем по статусам:
 *   Base:  Светлая, Тёмная
 *   Black: + Океан, Закат, Лес
 *   Gold:  + Gold Status, Сезонная
 * 
 * Подключается ПОСЛЕ onboarding-persistence.js.
 * Автоматически применяет тему при загрузке.
 */

const AIDietThemes = {
  // ─── Палитры ──────────────────────────────────────────
  themes: {
    light: {
      name: 'Светлая',
      tier: 'base',
      vars: {
        '--color-primary': '#F5922B',
        '--color-primary-gradient': 'linear-gradient(135deg, #F59520, #E07018)',
        '--color-primary-rgb': '245, 146, 43',
        '--color-bg-main': '#FAFAFA',
        '--color-surface': '#FFFFFF',
        '--color-text-primary': '#1A1A1A',
        '--color-text-secondary': '#6B7280',
        '--color-divider': '#E5E7EB',
        '--color-chip-active-bg': '#FFF7ED',
        '--color-card-bg': '#FFFFFF',
        '--color-input-bg': '#FFFFFF',
        '--color-tab-bar-bg': 'rgba(255,255,255,0.92)',
        '--color-status-bar': '#1A1A1A',
        '--color-tip-bg': '#E8F5E9',
        '--color-tip-border': '#C8E6C9',
        '--color-tip-text': '#2E7D32'
      }
    },

    dark: {
      name: 'Тёмная',
      tier: 'base',
      vars: {
        '--color-primary': '#F5922B',
        '--color-primary-gradient': 'linear-gradient(135deg, #F59520, #E07018)',
        '--color-primary-rgb': '245, 146, 43',
        '--color-bg-main': '#121212',
        '--color-surface': '#1E1E1E',
        '--color-text-primary': '#E8E8E8',
        '--color-text-secondary': '#9CA3AF',
        '--color-divider': '#2D2D2D',
        '--color-chip-active-bg': '#2A1F10',
        '--color-card-bg': '#1E1E1E',
        '--color-input-bg': '#252525',
        '--color-tab-bar-bg': 'rgba(30,30,30,0.95)',
        '--color-status-bar': '#E8E8E8',
        '--color-tip-bg': '#1B3A1B',
        '--color-tip-border': '#2D5A2D',
        '--color-tip-text': '#81C784'
      }
    },

    ocean: {
      name: 'Океан',
      tier: 'black',
      vars: {
        '--color-primary': '#0077B6',
        '--color-primary-gradient': 'linear-gradient(135deg, #0096C7, #005F8A)',
        '--color-primary-rgb': '0, 119, 182',
        '--color-bg-main': '#F0F8FF',
        '--color-surface': '#FFFFFF',
        '--color-text-primary': '#0A2540',
        '--color-text-secondary': '#4A6D8C',
        '--color-divider': '#C8E0F0',
        '--color-chip-active-bg': '#E0F2FF',
        '--color-card-bg': '#FFFFFF',
        '--color-input-bg': '#FFFFFF',
        '--color-tab-bar-bg': 'rgba(240,248,255,0.92)',
        '--color-status-bar': '#0A2540',
        '--color-tip-bg': '#E0F7FA',
        '--color-tip-border': '#B2EBF2',
        '--color-tip-text': '#00695C'
      }
    },

    sunset: {
      name: 'Закат',
      tier: 'black',
      vars: {
        '--color-primary': '#E85D04',
        '--color-primary-gradient': 'linear-gradient(135deg, #F48C06, #DC2F02)',
        '--color-primary-rgb': '232, 93, 4',
        '--color-bg-main': '#FFFAF5',
        '--color-surface': '#FFFFFF',
        '--color-text-primary': '#2D1600',
        '--color-text-secondary': '#8B5E34',
        '--color-divider': '#F0D9C4',
        '--color-chip-active-bg': '#FFF0E0',
        '--color-card-bg': '#FFFFFF',
        '--color-input-bg': '#FFFFFF',
        '--color-tab-bar-bg': 'rgba(255,250,245,0.92)',
        '--color-status-bar': '#2D1600',
        '--color-tip-bg': '#FFF3E0',
        '--color-tip-border': '#FFE0B2',
        '--color-tip-text': '#E65100'
      }
    },

    forest: {
      name: 'Лес',
      tier: 'black',
      vars: {
        '--color-primary': '#2D6A4F',
        '--color-primary-gradient': 'linear-gradient(135deg, #40916C, #1B4332)',
        '--color-primary-rgb': '45, 106, 79',
        '--color-bg-main': '#F0FDF4',
        '--color-surface': '#FFFFFF',
        '--color-text-primary': '#1B2E20',
        '--color-text-secondary': '#4A7C5E',
        '--color-divider': '#C8E6C9',
        '--color-chip-active-bg': '#E8F5E9',
        '--color-card-bg': '#FFFFFF',
        '--color-input-bg': '#FFFFFF',
        '--color-tab-bar-bg': 'rgba(240,253,244,0.92)',
        '--color-status-bar': '#1B2E20',
        '--color-tip-bg': '#E8F5E9',
        '--color-tip-border': '#A5D6A7',
        '--color-tip-text': '#1B5E20'
      }
    },

    gold_status: {
      name: 'Gold Status',
      tier: 'gold',
      vars: {
        '--color-primary': '#D4AF37',
        '--color-primary-gradient': 'linear-gradient(135deg, #FFD700, #B8860B)',
        '--color-primary-rgb': '212, 175, 55',
        '--color-bg-main': '#0D0D0D',
        '--color-surface': '#1A1A1A',
        '--color-text-primary': '#F5F0E1',
        '--color-text-secondary': '#A09070',
        '--color-divider': '#2A2520',
        '--color-chip-active-bg': '#1F1A10',
        '--color-card-bg': '#1A1A1A',
        '--color-input-bg': '#1F1F1F',
        '--color-tab-bar-bg': 'rgba(13,13,13,0.95)',
        '--color-status-bar': '#F5F0E1',
        '--color-tip-bg': '#1F1A10',
        '--color-tip-border': '#3D3420',
        '--color-tip-text': '#D4AF37'
      }
    },

    seasonal: {
      name: 'Сезонная',
      tier: 'gold',
      // Определяется динамически
      vars: null
    }
  },

  // ─── Сезонные палитры (Gold) ────────────────────────────
  _seasonalPalettes: {
    spring: { // Март-Май
      '--color-primary': '#7CB342',
      '--color-primary-gradient': 'linear-gradient(135deg, #8BC34A, #558B2F)',
      '--color-primary-rgb': '124, 179, 66',
      '--color-bg-main': '#F9FFF0',
      '--color-surface': '#FFFFFF',
      '--color-text-primary': '#1B3A00',
      '--color-text-secondary': '#5A7A3A',
      '--color-divider': '#DCEDC8',
      '--color-chip-active-bg': '#F1F8E9',
      '--color-card-bg': '#FFFFFF',
      '--color-input-bg': '#FFFFFF',
      '--color-tab-bar-bg': 'rgba(249,255,240,0.92)',
      '--color-status-bar': '#1B3A00',
      '--color-tip-bg': '#F1F8E9',
      '--color-tip-border': '#DCEDC8',
      '--color-tip-text': '#33691E'
    },
    summer: { // Июнь-Август
      '--color-primary': '#FF8F00',
      '--color-primary-gradient': 'linear-gradient(135deg, #FFA000, #EF6C00)',
      '--color-primary-rgb': '255, 143, 0',
      '--color-bg-main': '#FFFDE7',
      '--color-surface': '#FFFFFF',
      '--color-text-primary': '#3E2723',
      '--color-text-secondary': '#8D6E63',
      '--color-divider': '#FFF9C4',
      '--color-chip-active-bg': '#FFF8E1',
      '--color-card-bg': '#FFFFFF',
      '--color-input-bg': '#FFFFFF',
      '--color-tab-bar-bg': 'rgba(255,253,231,0.92)',
      '--color-status-bar': '#3E2723',
      '--color-tip-bg': '#FFF8E1',
      '--color-tip-border': '#FFECB3',
      '--color-tip-text': '#E65100'
    },
    autumn: { // Сентябрь-Ноябрь
      '--color-primary': '#BF360C',
      '--color-primary-gradient': 'linear-gradient(135deg, #D84315, #8D3006)',
      '--color-primary-rgb': '191, 54, 12',
      '--color-bg-main': '#FFF8F5',
      '--color-surface': '#FFFFFF',
      '--color-text-primary': '#3E1A00',
      '--color-text-secondary': '#8D6E63',
      '--color-divider': '#F0D0C0',
      '--color-chip-active-bg': '#FBE9E7',
      '--color-card-bg': '#FFFFFF',
      '--color-input-bg': '#FFFFFF',
      '--color-tab-bar-bg': 'rgba(255,248,245,0.92)',
      '--color-status-bar': '#3E1A00',
      '--color-tip-bg': '#FBE9E7',
      '--color-tip-border': '#FFCCBC',
      '--color-tip-text': '#BF360C'
    },
    winter: { // Декабрь-Февраль
      '--color-primary': '#1565C0',
      '--color-primary-gradient': 'linear-gradient(135deg, #1E88E5, #0D47A1)',
      '--color-primary-rgb': '21, 101, 192',
      '--color-bg-main': '#F5F9FF',
      '--color-surface': '#FFFFFF',
      '--color-text-primary': '#0D1B3E',
      '--color-text-secondary': '#5C7A9A',
      '--color-divider': '#BBDEFB',
      '--color-chip-active-bg': '#E3F2FD',
      '--color-card-bg': '#FFFFFF',
      '--color-input-bg': '#FFFFFF',
      '--color-tab-bar-bg': 'rgba(245,249,255,0.92)',
      '--color-status-bar': '#0D1B3E',
      '--color-tip-bg': '#E3F2FD',
      '--color-tip-border': '#90CAF9',
      '--color-tip-text': '#0D47A1'
    }
  },

  // ─── Текущий сезон ──────────────────────────────────
  _getCurrentSeason() {
    const m = new Date().getMonth(); // 0-11
    if (m >= 2 && m <= 4) return 'spring';
    if (m >= 5 && m <= 7) return 'summer';
    if (m >= 8 && m <= 10) return 'autumn';
    return 'winter';
  },

  // ─── Tier проверка ────────────────────────────────────
  _getTier() {
    try {
      const sub = localStorage.getItem('aidiet_subscription');
      if (sub) return sub.toLowerCase();
      const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
      const tier = (profile['Выбранный статус'] || '').toLowerCase();
      if (tier.includes('gold')) return 'gold';
      if (tier.includes('black')) return 'black';
      // Триал Gold проверка
      const trialStart = profile['trial_start'] || profile['_firstLaunch'];
      if (trialStart) {
        const daysSince = (Date.now() - new Date(trialStart).getTime()) / 86400000;
        if (daysSince <= 3) return 'gold'; // Триал 3 дня = Gold
      }
      return 'base';
    } catch { return 'base'; }
  },

  _tierLevel(t) {
    return { base: 0, black: 1, gold: 2 }[t] || 0;
  },

  canUseTheme(themeId) {
    const theme = this.themes[themeId];
    if (!theme) return false;
    return this._tierLevel(this._getTier()) >= this._tierLevel(theme.tier);
  },

  // ─── Применение темы ───────────────────────────────────
  apply(themeId) {
    let vars;

    if (themeId === 'seasonal') {
      vars = this._seasonalPalettes[this._getCurrentSeason()];
    } else {
      const theme = this.themes[themeId];
      if (!theme) return false;
      vars = theme.vars;
    }

    if (!vars) return false;

    const root = document.documentElement;
    Object.entries(vars).forEach(([prop, val]) => {
      root.style.setProperty(prop, val);
    });

    // Дополнительные стили для тёмных тем
    const isDark = themeId === 'dark' || themeId === 'gold_status';
    document.body.classList.toggle('theme-dark', isDark);

    // Применяем фон body для мобильного режима
    document.body.style.backgroundColor = vars['--color-bg-main'] || '#FAFAFA';

    // Дополнительные правки для тёмных тем
    if (isDark) {
      this._applyDarkOverrides();
    }

    return true;
  },

  _applyDarkOverrides() {
    // Инжектируем стили для тёмных тем, которые не покрываются CSS variables
    let darkStyle = document.getElementById('aidiet-dark-overrides');
    if (!darkStyle) {
      darkStyle = document.createElement('style');
      darkStyle.id = 'aidiet-dark-overrides';
      document.head.appendChild(darkStyle);
    }
    darkStyle.innerHTML = `
      .theme-dark .phone { background-color: var(--color-bg-main); }
      .theme-dark .header, 
      .theme-dark .progress-header { background: var(--color-surface); border-color: var(--color-divider); }
      .theme-dark .input-wrapper { background: var(--color-input-bg); border-color: var(--color-divider); }
      .theme-dark .chip { background: var(--color-card-bg); border-color: var(--color-divider); }
      .theme-dark .chip.active { background: var(--color-chip-active-bg); }
      .theme-dark .btn-back { background: var(--color-surface); border-color: var(--color-divider); color: var(--color-text-primary); }
      .theme-dark .back-btn { background: var(--color-surface); border-color: var(--color-divider); color: var(--color-text-primary); }
      .theme-dark .tab-bar, .theme-dark .bottom-nav { background: var(--color-tab-bar-bg) !important; border-color: var(--color-divider) !important; }
      .theme-dark .onboarding-tip-card { background: var(--color-tip-bg); border-color: var(--color-tip-border); }
      .theme-dark .onboarding-tip-text { color: var(--color-tip-text); }
      .theme-dark .progress-bar { background: var(--color-divider); }
      .theme-dark .theme-card { background: var(--color-card-bg); border-color: var(--color-divider); }
    `;
  },

  // ─── Сохранение ─────────────────────────────────────
  save(themeId) {
    if (window.AIDiet && window.AIDiet.saveField) {
      window.AIDiet.saveField('selected_theme', themeId);
    } else {
      try {
        const p = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
        p.selected_theme = themeId;
        localStorage.setItem('aidiet_profile', JSON.stringify(p));
      } catch {}
    }
  },

  // ─── Получение текущей темы ──────────────────────────
  getCurrent() {
    try {
      const p = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
      return p.selected_theme || 'light';
    } catch { return 'light'; }
  },

  // ─── Полный цикл: проверить доступ → применить ─────────
  init() {
    const saved = this.getCurrent();
    if (this.canUseTheme(saved)) {
      this.apply(saved);
    } else {
      // Тема недоступна (статус понижен) → откат на Светлую
      this.apply('light');
      this.save('light');
    }
  },

  // ─── Переключение темы (для U-13) ──────────────────────
  switchTo(themeId) {
    if (!this.canUseTheme(themeId)) return false;
    this.apply(themeId);
    this.save(themeId);
    return true;
  },

  // ─── Список тем для UI (U-13) ──────────────────────────
  getThemeList() {
    const tier = this._getTier();
    const current = this.getCurrent();
    return Object.entries(this.themes).map(([id, theme]) => ({
      id,
      name: theme.name,
      tier: theme.tier,
      locked: this._tierLevel(tier) < this._tierLevel(theme.tier),
      active: id === current,
      requiredTier: theme.tier === 'base' ? null : theme.tier === 'black' ? 'Black' : 'Gold'
    }));
  }
};

// Авто-инициализация при загрузке
document.addEventListener('DOMContentLoaded', () => AIDietThemes.init());
// Фоллбэк если DOMContentLoaded уже прошёл
if (document.readyState !== 'loading') AIDietThemes.init();
