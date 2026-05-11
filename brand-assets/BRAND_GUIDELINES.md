# ejeweeka — Brand Guidelines

## Brand Tagline

**be more · feel alive**

- Logo format: `be more · feel alive` (centered dot separator)
- Text format: `be more. feel alive.` (periods)
- Voice: aspirational + emotional payoff

## Logo System

### Assets Structure
```
brand-assets/production/
├── logo-horizontal-dark-on-transparent.png    # Dark text on transparent (light bg)
├── logo-horizontal-white-on-transparent.png   # White text on transparent (dark bg)
├── logo-horizontal-dark-tagline.png           # Dark + tagline on transparent
├── logo-horizontal-white-tagline.png          # White + tagline on transparent
├── logo-stacked-dark-on-transparent.png       # Stacked, dark text
├── logo-stacked-white-on-transparent.png      # Stacked, white text
├── logo-monochrome-dark-on-transparent.png    # Single-color charcoal
├── logo-monochrome-dark-tagline.png           # Monochrome + tagline
├── logo-monochrome-white-on-transparent.png   # Single-color white
├── icon-symbol-orange-on-transparent.png      # Symbol only (orange)
├── icon-symbol-white-on-transparent.png       # Symbol only (white)
├── appicon-1024.png                           # iOS/Android app icon
├── favicon.ico                                # Multi-size favicon
├── favicon-{16..512}.png                      # Favicon at all sizes
└── AppIcon.appiconset/                        # Xcode-ready icon set (15 sizes)
```

---

## Color System

| Token | Hex | Usage |
|---|---|---|
| `brand-primary` | `#4C1D95` | Accent, CTA, "Code" wordmark, symbol gradient base |
| `brand-gradient-start` | `#E85D04` | Deep amber (gradient start) |
| `brand-gradient-end` | `#FFB347` | Soft gold (gradient end) |
| `neutral-dark` | `#1F2937` | Dark backgrounds, "Health" text (dark mode) |
| `neutral-charcoal` | `#111827` | App icon background |
| `neutral-light` | `#F9FAFB` | Light backgrounds |
| `text-primary-dark` | `#FFFFFF` | Text on dark surfaces |
| `text-primary-light` | `#1F2937` | Text on light surfaces |

### Orange Gradient (CSS)
```css
background: linear-gradient(135deg, #E85D04 0%, #4C1D95 50%, #FFB347 100%);
```

### Orange Gradient (Flutter)
```dart
LinearGradient(
  colors: [Color(0xFFE85D04), Color(0xFF4C1D95), Color(0xFFFFB347)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

## Typography

| Element | Font | Weight | Size |
|---|---|---|---|
| Wordmark "Health" | Inter / SF Pro Display | Bold (700) | — |
| Wordmark "Code" | Inter / SF Pro Display | Bold (700) | — |
| Tagline "be more · feel alive" | Inter | Light (300) | 40% of wordmark height |

---

## Symbol: Connected-Node Mark

The biomorphic connected-node symbol represents:

- **3 nodes** = nutrition, sleep, activity (the three wellness pillars)
- **Organic connections** = adaptive, personalized algorithm
- **Upward trajectory** = growth, vitality, positive momentum
- **Digital geometry** = precision, code, intelligence
- **Warm gradient** = care, warmth, wellness (not clinical)

### Clear Space
Minimum clear space around the symbol = 1× the height of the smallest node.

### Minimum Size
- **Digital:** 24×24 px minimum
- **Print:** 10mm minimum

---

## Logo Usage Rules

### ✅ Do
- Use the dark version on dark backgrounds (#1F2937 or darker)
- Use the light version on white/off-white backgrounds
- Use monochrome white when overlaying photos or colored surfaces
- Maintain minimum clear space around the logo
- Use the app icon (symbol-only) for square/circular contexts

### ❌ Don't
- Stretch, rotate, or distort the logo
- Change the gradient colors
- Add effects (drop shadows, outlines, glows)
- Place on busy or low-contrast backgrounds
- Use the full wordmark inside the app icon
- Recreate the symbol in a different style

---

## Context-Specific Usage

| Context | Asset | Notes |
|---|---|---|
| iOS App Icon | `healthcode-appicon-1024.png` | Symbol-only, dark bg |
| Android App Icon | `healthcode-appicon-1024.png` | Same source, adaptive crop |
| Favicon (32×32) | Crop from `appicon-1024.png` | Symbol remains legible |
| Website Header | `healthcode-logo-light.png` | Horizontal, light bg |
| Landing Page Hero | `healthcode-logo-dark.png` | Horizontal, dark bg |
| Splash Screen | `healthcode-logo-stacked.png` | Vertical, centered, dark bg |
| App Store Listing | App icon + horizontal wordmark | Paired for store presence |
| Telegram Bot | `healthcode-appicon-1024.png` | Circular crop from square |
| Email Signature | `healthcode-logo-light.png` | Small horizontal |
| Presentations | `healthcode-logo-dark.png` | On dark slide backgrounds |
| Watermarks | `healthcode-logo-monochrome.png` | At 15-20% opacity |


## Строгие Правила Логотипов и Темы (System Enforced)
Смотрите файл `05_ui_screens/logo-usage.md`.