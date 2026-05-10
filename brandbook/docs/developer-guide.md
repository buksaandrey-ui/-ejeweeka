# ejeweeka — Developer Guide

## 1. Design Tokens

### CSS Variables
```html
<!-- In <head> or your global CSS -->
<link rel="stylesheet" href="/brandbook/tokens/colors.css">
```

Then use anywhere:
```css
.my-card {
  background: var(--color-surface-dark);
  border: 1px solid var(--color-border-glass);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-glow-sm);
}
```

### Tailwind
```js
// tailwind.config.js
const ejeweekaTokens = require('./brandbook/tokens/tailwind.tokens.js');
module.exports = {
  theme: { extend: ejeweekaTokens },
};
```

Usage:
```html
<div class="bg-surface-dark border border-white/8 rounded-xl shadow-glow-sm">
  <h2 class="text-h2 font-display text-text-white tracking-tight">ejeweeka</h2>
</div>
```

## 2. Favicon Setup

Paste in every page `<head>`:
```html
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon-32.png" type="image/png" sizes="32x32">
<link rel="icon" href="/favicon-16.png" type="image/png" sizes="16x16">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0D0618">
```

Files from `brandbook/assets/favicon/` → copy to public root.

## 3. PWA Manifest

```json
{
  "name": "ejeweeka",
  "short_name": "ejeweeka",
  "display": "standalone",
  "orientation": "portrait",
  "theme_color": "#0D0618",
  "background_color": "#000000",
  "icons": [
    { "src": "/pwa-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/pwa-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ]
}
```

## 4. Logo in Web

### Dark background (default)
```html
<!-- App icon with rounded corners -->
<img src="/assets/logo/eje-app-icon-master@2x.png"
     srcset="/assets/logo/eje-app-icon-master.png 1x,
             /assets/logo/eje-app-icon-master@2x.png 2x,
             /assets/logo/eje-app-icon-master@3x.png 3x"
     alt="ejeweeka"
     width="44" height="44"
     style="border-radius: 11px;">
```

### Transparent neon mark (dark backgrounds only)
```html
<img src="/assets/logo/eje-mark-transparent@2x.png"
     srcset="/assets/logo/eje-mark-transparent.png 1x,
             /assets/logo/eje-mark-transparent@2x.png 2x,
             /assets/logo/eje-mark-transparent@3x.png 3x"
     alt="ejeweeka"
     style="height: 48px; width: auto;">
```

### Horizontal lockup (nav header)
```html
<a href="/" style="display:flex; align-items:center; gap:10px; text-decoration:none;">
  <img src="/assets/logo/eje-app-icon-master@2x.png"
       alt="" width="32" height="32"
       style="border-radius:8px;">
  <span style="font-size:16px; font-weight:600; color:#fff; letter-spacing:-0.01em;">
    ejeweeka
  </span>
</a>
```

## 5. Which Asset to Use Where

| Context | File |
|---|---|
| App Store / Google Play | `ios-1024.png` |
| iOS Springboard icon | `ios-180.png` (60pt @3x) |
| Website header | `eje-app-icon-master@2x.png` |
| Splash / onboarding | `eje-mark-transparent@3x.png` on `#000` bg |
| Browser favicon | `favicon.ico` + `favicon-32.png` |
| Apple touch icon | `apple-touch-icon.png` |
| PWA | `pwa-192.png` + `pwa-512.png` |
| Social avatar | `ios-1024.png` or `android-512.png` |
| Email (HTML) | `eje-app-icon-master@2x.png` inline |
| Email (plain text) | text only — no logo |
| PDF / documents | app icon at small size, no glow on white |

## 6. Dark / Light Theme

```css
/* Dark theme (default) */
[data-theme="dark"] {
  --bg:      var(--color-bg-dark);
  --surface: var(--color-surface-dark);
  --text:    var(--color-text-primary-dark);
  --border:  var(--color-border-glass);
}

/* Light theme (Status White) */
[data-theme="light"] {
  --bg:      var(--color-bg-light);
  --surface: var(--color-surface-light);
  --text:    var(--color-text-primary-light);
  --border:  var(--color-border-soft);
}
```

## 7. Neon Glow

```css
/* Standard glow — cards, buttons */
.neon-card {
  box-shadow: 0 0 24px rgba(139, 92, 246, 0.35);
}

/* Hero / splash glow */
.neon-hero {
  box-shadow: 0 0 56px rgba(139, 92, 246, 0.4),
              0 0 32px rgba(217, 70, 239, 0.3);
}

/* Neon gradient — primary CTA */
.btn-primary {
  background: linear-gradient(135deg, #7C3AED 0%, #D946EF 100%);
  box-shadow: 0 0 12px rgba(139, 92, 246, 0.25);
}
```

## 8. Regenerate Assets

```bash
python3 brandbook/generate-assets.py
```

Source: `brandbook/assets/source/original-app-icon.png`
Never modify the source file. All derived assets are generated.
