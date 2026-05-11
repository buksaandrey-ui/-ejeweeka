import os
import shutil
import glob
import re

# 1. Update Specifications
logo_usage_md = """# ejeweeka — Logo Usage & Theme Guidelines (Strict Rules)

## 1. Базовая Тема (Theming)
- **Приложение (Flutter)**: Базовая тема приложения — **строго Светлая (Light Theme)**. Темная тема может использоваться только как опция.
- **Лендинги (Web)**: Лендинги имеют **две вариации** — Светлая (для светлого времени суток) и Темная (для темного времени суток). Переключение должно происходить автоматически через `@media (prefers-color-scheme: dark)`.

## 2. Главные Варианты Логотипа

### Лого #1 (Основной Wordmark)
**Файл:** `/brandbook/assets/logo/ejeweeka-inline-wordmark@2x.png`
**Где использовать:**
- Как ОСНОВНОЙ на лендингах: в Header, Footer, и Hero секции первого экрана (если это главная страница — значит без хедера до скроллинга ко второму экрану).
- Страница Welcome.
- Страницы выбора статусов (на 3D картах).
- И другие случаи согласно общей логике презентации.

### Лого #2 (Прозрачная Метка / Transparent Mark)
**Файл:** `/brandbook/assets/logo/eje-mark-transparent@3x.png`
**Где использовать:**
- Во всех местах, где мало места.
- В большинстве экранов внутри мобильного приложения.

### Лого #3 (Иконка Приложения / App Icon Master)
**Файл:** `/brandbook/assets/logo/eje-app-icon-master@3x.png`
**Где использовать:**
- В качестве иконки мобильного приложения (App Store / Google Play).
- Фавиконы (Web).
- Аватары в социальных сетях и подобных ситуациях.

**ВАЖНО:** Данные правила являются строгими и обязательны к соблюдению во всех будущих спецификациях и генерациях экранов.
"""
with open('05_ui_screens/logo-usage.md', 'w') as f:
    f.write(logo_usage_md)

# Append to designer-guide.md
with open('brandbook/docs/designer-guide.md', 'a') as f:
    f.write("\n\n## Строгие Правила Логотипов и Темы (System Enforced)\n\n")
    f.write("Смотрите файл `05_ui_screens/logo-usage.md` для получения исчерпывающих правил по трем основным логотипам и правилам Светлой/Темной тем для приложения и лендинга.")

# Try to append to BRAND_GUIDELINES.md if it exists
if os.path.exists('brand-assets/BRAND_GUIDELINES.md'):
    with open('brand-assets/BRAND_GUIDELINES.md', 'a') as f:
        f.write("\n\n## Строгие Правила Логотипов и Темы (System Enforced)\n")
        f.write("Смотрите файл `05_ui_screens/logo-usage.md`.")

# 2. Copy Logo #1 to Landing Page
os.makedirs('landing-page/public/brand', exist_ok=True)
shutil.copy2('brandbook/assets/logo/ejeweeka-inline-wordmark@2x.png', 'landing-page/public/brand/ejeweeka-inline-wordmark.png')

# Update Landing Page TSX to use Logo #1
tsx_files = glob.glob('landing-page/src/**/*.tsx', recursive=True)
for file in tsx_files:
    with open(file, 'r') as f:
        content = f.read()
    
    # Replace the previously set transparent mark with the wordmark for header/hero
    content = content.replace('/brand/eje-mark-transparent.png', '/brand/ejeweeka-inline-wordmark.png')
    
    with open(file, 'w') as f:
        f.write(content)

# 3. Add Dual Theme (Dark Mode) to globals.css
css_path = 'landing-page/src/app/globals.css'
with open(css_path, 'r') as f:
    css = f.read()

dark_mode_css = """
@media (prefers-color-scheme: dark) {
  :root {
    --bg: var(--color-bg-deep);
    --surface: var(--color-surface-elevated);
    --text-main: var(--color-text-primary-dark);
    --text-muted: var(--color-text-secondary-dark);
    --border: var(--color-border-accent);
  }
}
"""

if "@media (prefers-color-scheme: dark)" not in css:
    css += dark_mode_css
    with open(css_path, 'w') as f:
        f.write(css)

print("Specs updated, logo #1 applied, and dual themes configured.")
