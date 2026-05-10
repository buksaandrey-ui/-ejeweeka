# AIDiet Design System: Style B (Clean Apple-like)

**Version**: 2.0 (Mass-market re-positioning)  
**Base Aesthetic**: Simple, Clean Apple-like  
**Target Atmosphere**: Calm, Friendly, Accessible, Trustworthy

---

## 🎨 Color Tokens

| Token | Value | usage |
|-------|-------|-------|
| `--color-primary` | `#4C1D95` | Primary accent, CTA buttons |
| `--color-primary-gradient` | `linear-gradient(135deg, #F59520, #E07018)` | Large buttons, highlight areas |
| `--color-bg-main` | `#FAFAFA` | Global background color |
| `--color-surface` | `#FFFFFF` | Card backgrounds, isolated sections |
| `--color-text-primary` | `#1A1A1A` | Headings, primary body text |
| `--color-text-secondary` | `#6B7280` | Subtitles, labels, footers |
| `--color-divider` | `#E5E7EB` | Hairline borders, separators |

### Nutrients
- **Proteins**: `#52B044` (Green)
- **Fats**: `#F09030` (Orange)
- **Carbs**: `#42A5F5` (Blue)

---

## ✍️ Typography (Google Fonts: Inter)

- **Headings**: `Inter`, Weight 700 (Bold) or 600 (Semi-bold).
- **Body Text**: `Inter`, Weight 400 (Regular).
- **Secondary/Labels**: `Inter`, Weight 500 (Medium), Size 12-14px.

---

## 📐 Layout & Spacing

- **Logo Size (Welcome)**: `240px` width.
- **Top Padding (Phone)**: `24px` from the notch/status bar.
- **Card Radius**: `12px` (standard) or `16px` (larger UI blocks).
- **Page Side Padding**: `20px` to `24px`.
- **Vertical Gap (Sections)**: `32px`.

---

## 🧱 Component Rules

### Cards (Clean Apple-like)
- Background: `#FFFFFF`
- Border: `1px solid #E5E7EB`
- Shadow: `0 1px 4px rgba(0,0,0,0.06)` or `0 2px 12px rgba(0,0,0,0.06)` for emphasis.

### Buttons (Primary)
- Style: Solid Orange Gradient or Solid Orange.
- Radius: `12px` or `14px`.
- Padding: `16px 24px`.

### Onboarding Flow (Mandatory)
- **NO Skip button**: Users must complete the steps.
- **NO Personalized Greetings**: Until name is captured (Welcome screen O-1 must be generic).

### Copywriting & Tone of Voice
- **Friend Tone**: Приложение всегда обращается к пользователю на «ты» (как друг и наставник). Юридические документы могут использовать «Ты».
- **Gender Personalization**: В онбординге используется унисекс формат — глаголы с окончанием «(а)» (например, *указал(а)*). Внутри приложения (дашборд, профиль, рецепты) обращение **строго персонализируется** в зависимости от пола пользователя, который мы уже знаем из профиля.

### Educational Blocks (Motivational)
- Placement: Bottom of Profile/Metrics screens.
- Content: Explanatory text about why the data is being collected.

---

## 🎯 Iconography
- Library: **Phosphor Icons** (Regular) or **Lucide Icons**.
- Size: `24px` for standard icons, `44-48px` within USP card circles.
