# ejeweeka Brand System v1.0

Premium wellness intelligence — design tokens, logo assets, brandbook.

## Quick Start

```bash
# Generate all assets from the master icon
python3 brandbook/generate-assets.py
```

Requires Python 3 + Pillow + NumPy:
```bash
pip3 install Pillow numpy
```

## Structure

```
brandbook/
├── generate-assets.py          # Asset generation script
├── assets/
│   ├── source/
│   │   └── original-app-icon.png   # Master — never modify
│   ├── logo/
│   │   ├── eje-app-icon-master.png         # @1x
│   │   ├── eje-app-icon-master@2x.png      # @2x
│   │   ├── eje-app-icon-master@3x.png      # @3x (1024px)
│   │   ├── eje-mark-transparent.png        # Neon mark, no bg @1x
│   │   ├── eje-mark-transparent@2x.png     # @2x
│   │   └── eje-mark-transparent@3x.png     # @3x — for dark backgrounds
│   ├── app-icon/
│   │   ├── ios-1024.png … ios-20.png       # All iOS required sizes
│   │   └── android-512.png … android-48.png
│   ├── favicon/
│   │   ├── favicon.ico                     # Multi-size (16/32/48)
│   │   ├── favicon-16.png
│   │   ├── favicon-32.png
│   │   ├── favicon-48.png
│   │   ├── apple-touch-icon.png            # 180×180
│   │   ├── pwa-192.png
│   │   └── pwa-512.png
│   └── examples/
│       └── social-avatar.png
├── tokens/
│   ├── design-tokens.json      # Source of truth
│   ├── colors.css              # CSS custom properties
│   └── tailwind.tokens.js      # Tailwind extend config
└── docs/
    ├── ejeweeka-brandbook.html # Main brandbook (open in browser)
    ├── logo-usage.md
    ├── developer-guide.md
    └── designer-guide.md
```

## Name Rule

**Always:** `ejeweeka`
**Never:** `Ejeweeka`, `EJEWEEKA`, `EjeWeeka`, any capitalization.

## Transparent Mark Note

`eje-mark-transparent*` is auto-extracted via luminosity masking.
- Works well on **dark / OLED backgrounds**
- For **light backgrounds** → open original in Figma/Photoshop and manually mask the dark panel

## Key Colors

| Token | HEX | Use |
|---|---|---|
| `--color-brand-neon-violet` | `#8B5CF6` | Primary accent |
| `--color-brand-neon-magenta` | `#D946EF` | Gradient highlight |
| `--color-bg-oled` | `#000000` | App base background |
| `--color-bg-dark` | `#0D0618` | Premium dark background |
| `--color-surface-dark` | `#1A0A35` | Cards, panels |
| `--color-status-gold` | `#F59E0B` | Status Gold accent |

## Compliance

- Never use: `subscription`, `price`, `buy`, `tariff`, `купить`, `цена`, `тариф`, `подписка`
- Use: `статус`, `открыть статус`, `активировать статус`, `возможности статуса`
- This reduces App Store review risk — does not guarantee approval
