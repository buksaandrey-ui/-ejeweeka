import os
import glob
import re

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return False

    original_content = content

    # 1. Update brandbook/tokens/colors.css
    if filepath.endswith('colors.css') or filepath.endswith('globals.css'):
        # Fix text colors for light theme to be dark purple
        content = content.replace('--color-text-primary-light:     #18181B;', '--color-text-primary-light:     var(--color-brand-deep-purple);')
        content = content.replace('--color-text-secondary-light:   #71717A;', '--color-text-secondary-light:   #4C1D95;')

    # 2. Update React TSX components
    if filepath.endswith(('.tsx', '.ts')):
        # Fix legacy gradients
        # The exact string in page.tsx might be:
        # linear-gradient(135deg, #E85D04 0%, var(--primary) 50%, #FFB347 100%)
        # Or variations. We replace it with var(--gradient-neon-mark)
        content = re.sub(r'linear-gradient\([^)]+#E85D04[^)]+\)', 'var(--gradient-neon-mark)', content)
        
        # Also fix color: "#000" in those same buttons
        content = content.replace('color: "#000"', 'color: "#FFF"')
        
        # 3. Fix SVG transparency
        content = content.replace('rgba(255,255,255,0.1)', 'var(--border-accent)')
        content = content.replace('rgba(255,255,255,0.4)', 'var(--text-muted)')
        content = content.replace('rgba(255,255,255,0.2)', 'var(--primary)')

    # Write back if changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

patterns = [
    'landing-page/src/**/*.tsx',
    'landing-page/src/**/*.ts',
    'brandbook/tokens/**/*.css',
    'landing-page/src/**/*.css',
    'health_code/lib/**/*.dart'
]

files_changed = 0
for pattern in patterns:
    for filepath in glob.glob(pattern, recursive=True):
        if process_file(filepath):
            files_changed += 1

print(f"Applied visual fixes to {files_changed} files.")
