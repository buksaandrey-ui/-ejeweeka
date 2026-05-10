# AIDiet — Design Battle Brief

## Viewport
390x844px (iPhone 14). Each HTML is self-contained,
centered on page with #E5E7EB background outside the phone frame.

## Font
Inter (Google Fonts CDN), weights: 400, 500, 600, 700

## Color Palette (shared by all styles)
- Background: #FAFAFA
- Text primary: #1A1A1A
- Text secondary: #6B7280
- Accent / Orange: #4C1D95
- CTA gradient: linear-gradient(135deg, #F59520, #E07018)
- Proteins: #52B044
- Fats: #F09030
- Carbs: #42A5F5
- Sleep: #9575CD
- Hydration: #42A5F5
- Gold badge: linear-gradient(135deg, #FFD700, #C8A96E)
- Card background: #FFFFFF
- Border subtle: #E5E7EB
- Disabled: #D1D5DB
- Error: #EF4444
- Success: #10B981

## Logo
Horizontal logo for headers: ../logos/print/AIDiet_primary_light.svg
App icon (square): ../logos/print/AIDiet_app_icon_1024.svg

## Global rules for ALL 9 HTML files
- Fully self-contained HTML (inline CSS, no JS frameworks)
- Realistic sample data in Russian language (NOT Lorem ipsum)
- Icons via CDN (specific library depends on style)
- Mock status bar at top: time 9:41, Wi-Fi, battery icons
- Must look like a REAL production app screenshot, NOT a wireframe
- Phone frame: white rectangle 390x844 with border-radius 40px and subtle shadow, centered on #E5E7EB page

---

## SCREEN 1: O-3 — Basic Profile (Onboarding, step 2/14)

Layout top to bottom:
1. Progress bar: step 2 of 14 (thin orange line, ~14% filled)
2. Title: "Базовый профиль"
3. Subtitle: "Расскажи о себе — это поможет рассчитать план"

4. Section "О тебе":
   - Field "Имя": text input. Placeholder: "Например: Иван, Мария". Value: "Андрей"
   - Field "Пол": two toggle tabs "Женщина" / "Мужчина" (Мужчина is selected/active)
   - Field "Возраст": numeric input. Value: 32

5. Section "Параметры тела":
   - Field "Рост (см)": numeric input. Value: 178
   - Field "Текущий вес (кг)": numeric input. Value: 82
   - Field "Телосложение": dropdown, selected: "Среднее"
   - Field "Обхват талии (см)": numeric input. Value: 91.
     Info icon (i) with visible tooltip: "Измерь сантиметровой лентой на уровне пупка, стоя, на выдохе."
     Checkbox below: "Не знаю / измерю позже" (unchecked)
   - Conditional field (visible because BMI ~25.9):
     "Где лишний вес заметнее всего?"
     Dropdown, selected: "В основном живот и талия"

6. CTA button: "Далее →" (orange gradient, full width)

Notes:
- Screen scrolls (content is longer than viewport)
- Show in scrolled state so both sections are partially visible
- NO logo on this screen (it is onboarding with progress stepper)

---

## SCREEN 2: H-1 — Dashboard (Home)

Layout top to bottom:
1. Header: AIDiet logo (horizontal_sage.svg) on the left, then "Привет, Андрей!" on the right side of logo, notification bell icon + user avatar circle on the far right

2. Week switcher: horizontal row of day circles
   Пн Вт Ср Чт Пт Сб Вс
   Current day (Вт) highlighted with orange circle.
   Date above: "15 апреля"

3. Calorie ring:
   - Circular progress chart: 1420 / 2200 kcal (~65% filled)
   - Filled arc color: orange gradient
   - Inside ring: "1420" large, "из 2200 kcal" small below
   - Below ring: 3 horizontal progress bars:
     Белки: 62 / 110 г (#52B044)
     Жиры: 48 / 73 г (#F09030)
     Углеводы: 180 / 275 г (#42A5F5)

4. Next meal section:
   - Section title: "Обед — 13:00"
   - Horizontal scrollable cards (2-3 meal cards):
     Card 1: food emoji + "Греческий салат" + "320 kcal"
     Card 2: food emoji + "Куриная грудка с овощами" + "450 kcal"
   - Two buttons per card: "Съел" (green) and "Другое" (gray outline)

5. Quick actions:
   - 4 circle icons in a row:
     Вода (water drop icon), Вес (scale icon),
     Витамины (pill icon, with lock badge), Фото (camera icon, with lock badge)
   - Labels below each icon

6. Banner (Free plan):
   - Card with Gold-gradient left border
   - Text: "Попробуй Black — рецепты, витамины, AI-отчёты"
   - Small button: "Подробнее"

7. Bottom Tab Bar (fixed at bottom):
   - 5 tabs: Главная (active, orange) | Планы | Фото | Отчёты | Профиль
   - Each tab: icon + label below

---

## SCREEN 3: P-4 — Full Recipe

Layout top to bottom:
1. Header: back arrow on the left, title "Греческий салат" centered, share icon on the right

2. Hero image: large photo area at top (use a beautiful gradient placeholder #E8F5E9 to #C8E6C9 with centered salad emoji, size 80px)

3. Meta info row:
   - "320 kcal" + "15 мин" + "Легко"
   - Badge: "Black" with Gold-gradient background

4. Section "Ингредиенты" (6 items):
   - Each line: checkbox + ingredient text
     Checked: Помидоры — 2 шт (checked, line-through style)
     Checked: Огурцы — 1 шт (checked, line-through style)
     Unchecked: Перец болгарский — 1 шт
     Unchecked: Маслины — 50 г
     Unchecked: Сыр фета — 80 г
     Unchecked: Оливковое масло — 1 ст.л.

5. Section "Приготовление" (3 steps):
   - Step 1: circle with "1" + "Нарежь овощи крупными кубиками"
   - Step 2: circle with "2" + "Добавь маслины и сыр, перемешай"
   - Step 3: circle with "3" + "Заправь оливковым маслом. Дай настояться 5 минут."
     Timer button below step 3: "5:00 — Старт" (outline style)

6. CTA button: "Готово" (orange gradient, full width, sticky at bottom)

Notes:
- Screen scrolls, CTA button stays fixed at bottom

---

## STYLE A — "Apple Health Clean"
- Border-radius: 16-20px on cards, 9999px on buttons (pill shape)
- Icons: Lucide (CDN: https://unpkg.com/lucide@latest/dist/umd/lucide.min.js)
  Stroke-width: 1.5px, line-only, no fill
- Cards: NO border, shadow only (box-shadow: 0 2px 12px rgba(0,0,0,0.06))
- Card padding: 20-24px
- Section gaps: 20-24px
- Input fields: large, rounded (12px), light gray background #F3F4F6, no border
- Toggle tabs (gender): pill-shaped, selected = orange fill + white text
- Dropdown: looks like rounded input with chevron-down icon
- Tab bar: thin line icons, active tab = filled orange icon + orange label
- Progress bar: rounded caps, 8px height
- Calorie ring: stroke-width 12px, rounded linecap
- Overall: airy, generous whitespace, calm, premium feel

## STYLE B — "Material Premium"
- Border-radius: 12px on cards, 12px on buttons
- Icons: Phosphor Regular (CDN: https://unpkg.com/@phosphor-icons/web@2/src/regular/style.css)
  Use class names like: ph ph-house
- Cards: border 1px solid #E5E7EB + shadow (box-shadow: 0 1px 4px rgba(0,0,0,0.06))
- Card padding: 16px
- Section gaps: 16px
- Thin horizontal dividers (1px #E5E7EB) between sections
- Input fields: border 1px solid #D1D5DB, border-radius 8px, white background
- Toggle tabs: rectangular with rounded corners, selected = filled orange
- Dropdown: bordered input with down-arrow icon
- Tab bar: medium-weight icons, active = orange icon + label, inactive = gray icon only
- Progress bar: slightly squared caps, 6px height
- Calorie ring: stroke-width 10px
- Overall: structured, organized, information-dense but clean

## STYLE C — "Glass Calm"
- Border-radius: 16px on cards, 14px on buttons
- Icons: Phosphor Duotone (CDN: https://unpkg.com/@phosphor-icons/web@2/src/duotone/style.css)
  Use class names like: ph-duotone ph-house
- Cards: background rgba(255,255,255,0.7), backdrop-filter: blur(12px), border: 1px solid rgba(255,255,255,0.5)
- Colored shadows on accent elements (box-shadow: 0 4px 16px rgba(245,146,43,0.2) on CTA)
- Page background: linear-gradient(180deg, #FAFAFA 0%, #F0F4FF 100%)
- Card padding: 20px
- Section gaps: 20px
- Input fields: semi-transparent background rgba(255,255,255,0.6), backdrop-filter blur, border 1px solid rgba(255,255,255,0.8), border-radius 12px
- Toggle tabs: glass-style, selected = orange gradient fill
- CTA button: gradient + glow shadow
- Tab bar: duotone icons, active = gradient underline + orange icon
- Progress bar: gradient fill, rounded caps, 8px height
- Calorie ring: gradient stroke, stroke-width 12px, subtle glow
- Overall: modern, premium, slightly playful, trendy
