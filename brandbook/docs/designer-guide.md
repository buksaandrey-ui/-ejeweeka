# ejeweeka — Designer Guide

## The Logo

The primary mark is "eje" — three letters forming a face:
- two **e**s = eyes
- **j** = center element with dot
- curved arc = smile

This is a **playful neon smile**. The character must be preserved in every adaptation.

## Which File to Use

### App Icon Master
**File:** `assets/logo/eje-app-icon-master@3x.png`

Use when you need a square icon: App Store, Google Play, social avatar, Telegram, Figma components, any platform that clips corners itself.

Never remove the dark background for this version — it IS the icon.

### Transparent Neon Mark
**File:** `assets/logo/eje-mark-transparent@3x.png`

Use on dark backgrounds: website hero, splash screen, onboarding, keynote presentations, dark-mode mockups.

⚠️ This version is auto-extracted (luminosity mask). On white/light backgrounds it may show a faint dark halo from the glass panel. For pixel-perfect light-background usage → open `assets/source/original-app-icon.png` in Figma and manually mask.

### Favicon / Tiny
**Files:** `assets/favicon/favicon-32.png`, `favicon-48.png`

Use at 16–48px. These are the 1024px master downscaled — at small sizes they read as a purple dot/cluster. Acceptable for tab icons. For critical small UI, test at actual size before shipping.

## Backgrounds

| Version | Allowed backgrounds | Avoid |
|---|---|---|
| App icon master | Any — has its own bg | — |
| Transparent neon mark | `#000`, `#0D0618`, dark surfaces | White, light gray, photos |
| Horizontal lockup | Dark surfaces | Noisy, photographic |
| Any neon version | Dark only | White paper, light UI |
| Desaturated / mono | Any | — |

## Clear Space

Minimum clear space = **0.5× the icon height** on all four sides.

For a 44px icon → minimum 22px margin on each side.
Never crowd the logo against text, edges, or other elements.

## Minimum Sizes

| Version | Min size |
|---|---|
| App icon master | 20×20px (system enforces) |
| Horizontal lockup | 120px wide |
| Transparent mark | 40px tall |
| Favicon | 16px (system favicon) |

## Colors — What You Can Change

**Can adjust:**
- Glow intensity (reduce for subtle contexts, remove for print)
- Wordmark color (white / dark / blackberry — never random colors)
- Background color (stay within brand palette)

**Cannot change:**
- The eje letterforms
- The smile shape
- The gradient direction on the mark
- The proportions of mark vs wordmark in lockups

## Status Themes in Figma

Use these color styles per status:

**Status White** — `#F9FAFB` bg, `#18181B` text, `#4C1D95` accent
**Status Gold** — `#0D0618` bg, `#F59E0B` accent, `#FCD34D` highlight
**Status Black** — `#000000` bg, `#8B5CF6` accent, neon glow
**Family Gold** — `#0D0618` bg, `#D97706` accent, `#FBBF24` warm highlight

## Typography Rules

- Always **Inter** on web, **SF Pro** on iOS
- `ejeweeka` wordmark: Inter 600–700, `letter-spacing: -0.01em`
- H1–H2: `letter-spacing: -0.02em` minimum
- Never use decorative, script, or display fonts
- Never use medical / pharma-looking typefaces

## What This Brand Is NOT

Not a medical app → no crosses, hearts (as medical symbols), pills, stethoscopes
Not a fitness brand → no dumbbells, running figures, flames
Not a children's app → nothing kitschy, cartoon, or pastels
Not crypto → no dark metallic, grids, binary
Not pharma → no clinical, sterile white-and-blue

## Compliance Terminology

Never in UI copy:
- subscription, price, buy, tariff
- подписка, цена, купить, тариф

Always use:
- статус / status
- открыть статус
- активировать статус
- возможности статуса
- уровень доступа


## Строгие Правила Логотипов и Темы (System Enforced)

Смотрите файл `05_ui_screens/logo-usage.md` для получения исчерпывающих правил по трем основным логотипам и правилам Светлой/Темной тем для приложения и лендинга.