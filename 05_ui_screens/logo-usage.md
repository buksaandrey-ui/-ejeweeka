# AIDiet — Logo Pack & Usage Guide (v2.0, 2026-04-16)

## 1. Вариации логотипа

| Вариация | SVG (logos/print/) | PNG web (logos/web/) | Где используется |
|----------|--------------------|----------------------|------------------|
| Primary Light | AIDiet_primary_light.svg | AIDiet_primary_light_512px.png | Welcome (O-1), About (U-8), Splash screen |
| Primary Dark | AIDiet_primary_dark.svg | AIDiet_primary_dark_512px.png | Хедер Экран статусов O-17, маркетинговые материалы |
| Icon Light | AIDiet_icon_light.svg | AIDiet_icon_light_512px.png | Dashboard хедер (H-1), навбар |
| Icon Dark | AIDiet_icon_dark.svg | AIDiet_icon_dark_512px.png | Тёмная тема (Nocturne), тёмные фоны |
| Mono Black | AIDiet_mono_black.svg | AIDiet_mono_black_512px.png | Печать, одноцветные носители, водяной знак |
| Mono White Dark | AIDiet_mono_white_dark.svg | AIDiet_mono_white_dark_512px.png | Инвертированный на тёмном фоне |
| App Icon | AIDiet_app_icon_1024.svg | AIDiet_app_icon_1024_1024px.png | App Store, Google Play, иконка на устройстве |

**Favicon:** logos/favicon/ — favicon.ico, aidiet-icon-{16,32,48,180,192,512,1024}px.png  
**Brand docs:** logos/brand/ — AIDiet_Brand_Guidelines.pdf, AIDiet_Usage_Sheet.pdf

## 2. Правила размещения

### Safe Zone
Свободное пространство вокруг логотипа = ширина внутреннего выреза листка (x).

### Минимальные размеры
- App icon: 24 px (icon only)
- Web header: 120 px (horizontal)
- Body/UI lockup: 96 px (stacked)
- Print: 20 mm horizontal / 16 mm stacked

### Правила фона
- Sage green логотип → только на светлых нейтральных фонах (warm beige, white)
- Белый логотип → только на тёмных сплошных фонах (dark green, charcoal, black)

## 3. Do / Don't

### DO
- Сохранять пропорции
- Использовать только утверждённые цвета
- Обеспечивать достаточный контраст с фоном

### DON'T
- Растягивать логотип
- Перекрашивать в произвольные цвета
- Размещать на шумных/пёстрых фонах с низким контрастом

## 4. Использование при генерации экранов

Все экраны генерируются через **UI UX Pro Max + Frontend Design skill** в Claude.
При генерации каждого экрана Claude автоматически читает:
1. `brandbook.md` — цветовая система, типографика, компоненты
2. `screens-map.md` — структура и данные экрана
3. `references/color_palette.md` — верифицированные токены

### Вариация логотипа по экранам
- Велкам O-1, About U-8, Splash → Primary Light (logos/print/AIDiet_primary_light.svg)
- Dashboard H-1, навбар, favicon → Icon Light (logos/print/AIDiet_icon_light.svg)
- Экран статусов O-17, маркетинг → Primary Light (logos/print/AIDiet_primary_light.svg)
- Тёмная тема → Mono White Dark (logos/print/AIDiet_mono_white_dark.svg)

## 5. Цветовые коды логотипа (финальные)

- Основной градиент: linear-gradient(135deg, #F59520, #E07018)
- Black (monochrome): #2E2E2E
- White (inverted): #FFFFFF
- Фон app icon tile: #FAFAFA
