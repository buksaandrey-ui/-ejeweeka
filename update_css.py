import re

css_path = 'landing-page/src/app/globals.css'
with open(css_path, 'r') as f:
    css = f.read()

new_root = """:root {
  --bg: var(--color-bg-dark);
  --surface: var(--color-surface-glass);
  --text-main: var(--color-text-primary-dark);
  --text-muted: var(--color-text-secondary-dark);
  --border: var(--color-border-glass);
  --border-hover: var(--color-border-accent);
  --radius-md: 24px;
  --radius-lg: 32px;
}"""
css = re.sub(r':root\s*\{[^}]+\}', new_root, css, count=1)

css = css.replace('-hc', '-eje')
css = css.replace('#F5922B', 'var(--color-brand-neon-violet)')
css = css.replace('#F59520', 'var(--color-brand-glow-violet)')
css = css.replace('#D96A11', 'var(--color-brand-bright-purple)')
css = css.replace('#E07018', 'var(--color-brand-neon-magenta)')
css = css.replace('rgba(245, 146, 43', 'rgba(139, 92, 246')
css = css.replace('rgba(245,146,43', 'rgba(139,92,246')
css = css.replace('rgba(245, 149, 32', 'rgba(124, 58, 237')
css = css.replace('rgba(245,149,32', 'rgba(124,58,237')
css = css.replace('rgba(217, 106, 17', 'rgba(168, 85, 247')
css = css.replace('rgba(217,106,17', 'rgba(168,85,247')

with open('brandbook/tokens/colors.css', 'r') as f:
    colors_css = f.read()

import_statement = '@import "tailwindcss";\n'
if import_statement in css:
    css = css.replace(import_statement, import_statement + '\n' + colors_css + '\n')
else:
    css = colors_css + '\n' + css

with open(css_path, 'w') as f:
    f.write(css)

print("Updated globals.css successfully.")
