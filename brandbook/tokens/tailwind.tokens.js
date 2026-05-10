// ejeweeka — Tailwind CSS Tokens
// Version: 1.0.0
// Usage: extend your tailwind.config.js with these tokens

/** @type {import('tailwindcss').Config} */
const ejeweekaTokens = {
  colors: {
    brand: {
      blackberry:      '#4C1D95',
      'neon-violet':   '#8B5CF6',
      'neon-magenta':  '#D946EF',
      'bright-purple': '#A855F7',
      'glow-pink':     '#F472B6',
      'glow-violet':   '#7C3AED',
      'deep-purple':   '#0D0618',
    },
    'bg-oled':            '#000000',
    'bg-oled-soft':       '#050505',
    'bg-dark':            '#0D0618',
    'surface-dark':       '#1A0A35',
    'surface-raised':     '#221344',
    'bg-light':           '#F9FAFB',
    'surface-light':      '#FFFFFF',
    'text-white':         '#FFFFFF',
    'text-soft-gray':     '#A1A1AA',
    'text-mid-gray':      '#71717A',
    'text-dark':          '#18181B',
    'text-accent':        '#A855F7',
    'status-white':       '#F9FAFB',
    'status-gold':        '#F59E0B',
    'status-gold-soft':   '#FCD34D',
    'status-black':       '#000000',
    'status-family-gold': '#D97706',
    success: '#10B981',
    warning: '#F59E0B',
    error:   '#EF4444',
    info:    '#8B5CF6',
  },

  fontFamily: {
    display: ['SF Pro Display', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
    body:    ['SF Pro Text',    'Inter', 'system-ui', '-apple-system', 'sans-serif'],
    mono:    ['SF Mono', 'JetBrains Mono', 'Menlo', 'monospace'],
  },

  fontSize: {
    'display': ['56px', { lineHeight: '1.1',  letterSpacing: '-0.03em' }],
    'h1':      ['40px', { lineHeight: '1.15', letterSpacing: '-0.02em' }],
    'h2':      ['32px', { lineHeight: '1.2',  letterSpacing: '-0.02em' }],
    'h3':      ['24px', { lineHeight: '1.3',  letterSpacing: '-0.015em' }],
    'body-lg': ['18px', { lineHeight: '1.6' }],
    'body':    ['16px', { lineHeight: '1.55' }],
    'caption': ['13px', { lineHeight: '1.4',  letterSpacing: '0.01em' }],
    'button':  ['16px', { lineHeight: '1',    letterSpacing: '-0.01em' }],
    'micro':   ['11px', { lineHeight: '1.4',  letterSpacing: '0.02em' }],
  },

  borderRadius: {
    'sm':   '8px',
    'md':   '12px',
    'lg':   '16px',
    'xl':   '24px',
    '2xl':  '32px',
    'full': '9999px',
  },

  boxShadow: {
    'glow-sm':    '0 0 12px rgba(139, 92, 246, 0.25)',
    'glow-md':    '0 0 24px rgba(139, 92, 246, 0.35)',
    'glow-lg':    '0 0 48px rgba(139, 92, 246, 0.4)',
    'glow-pink':  '0 0 32px rgba(217, 70, 239, 0.3)',
    'card-dark':  '0 1px 0 rgba(255,255,255,0.06) inset, 0 20px 40px rgba(0,0,0,0.4)',
    'card-light': '0 4px 24px rgba(0,0,0,0.08), 0 1px 4px rgba(0,0,0,0.05)',
  },

  transitionTimingFunction: {
    'spring': 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    'out':    'cubic-bezier(0, 0, 0.2, 1)',
  },

  transitionDuration: {
    'fast': '150ms',
    'base': '250ms',
    'slow': '400ms',
  },
};

module.exports = ejeweekaTokens;

// tailwind.config.js usage:
// const ejeweekaTokens = require('./brandbook/tokens/tailwind.tokens.js');
// module.exports = {
//   theme: { extend: ejeweekaTokens },
// };
