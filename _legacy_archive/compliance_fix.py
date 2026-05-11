import os
import glob
import re
import sys

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        return False

    original_content = content

    # 1. Replace Health Code mentions
    content = re.sub(r'\bHealth Code\b', 'ejeweeka', content)
    content = re.sub(r'\bHealthCode\b', 'ejeweeka', content)
    content = content.replace('Health Code — be more · feel alive', 'ejeweeka — be more · feel alive')
    content = content.replace('healthcode', 'ejeweeka')

    # 2. Replace old colors with new tokens (safely, mainly in TSX/HTML/CSS)
    if filepath.endswith(('.tsx', '.ts', '.html', '.css', '.js')):
        content = content.replace('#F5922B', 'var(--primary)')
        content = content.replace('#E07018', 'var(--primary-dark)')
        content = content.replace('#F59520', 'var(--primary)')
        content = content.replace('icon-symbol-orange.png', 'eje-app-icon-master.png')
        
        # 3. Theme fixes (TSX only)
        if filepath.endswith('.tsx'):
            # Replace white text with semantic text variable
            content = content.replace('text-white', 'text-[var(--text-main)]')
            # Replace inline white text colors with semantic text
            content = re.sub(r'color:\s*"rgba\(255,255,255,[0-9.]+\)"', 'color: "var(--text-muted)"', content)
            content = re.sub(r'color:\s*\'rgba\(255,255,255,[0-9.]+\)\'', 'color: "var(--text-muted)"', content)
            # Replace dark inline backgrounds with semantic backgrounds
            content = content.replace('background: "#2D3239"', 'background: "var(--bg)"')
            content = content.replace('background: "#1a1d22"', 'background: "var(--surface)"')
            content = content.replace('background: "#111318"', 'background: "var(--bg)"')
            content = re.sub(r'background:\s*"linear-gradient\(145deg[^"]+\)"', 'background: "var(--bg)"', content)
            content = re.sub(r'background:\s*"linear-gradient\(180deg[^"]+\)"', 'background: "var(--bg)"', content)
            content = re.sub(r'borderTop:\s*"1px solid rgba\(255,255,255,[0-9.]+\)"', 'borderTop: "1px solid var(--border)"', content)
            content = re.sub(r'border:\s*"1px solid rgba\(255,255,255,[0-9.]+\)"', 'border: "1px solid var(--border)"', content)

    # Write back if changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

# Files to process
patterns = [
    'landing-page/src/**/*.tsx',
    'landing-page/src/**/*.ts',
    'health_code/lib/**/*.dart',
    'health_code/ios/Runner/Info.plist',
    'aidiet-backend/**/*.py'
]

files_changed = 0
for pattern in patterns:
    for filepath in glob.glob(pattern, recursive=True):
        if process_file(filepath):
            files_changed += 1

print(f"Applied automated fixes to {files_changed} files.")
