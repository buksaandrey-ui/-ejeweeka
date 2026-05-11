import os
import shutil
import glob
import re

# Copy logos
os.makedirs('landing-page/public/brand', exist_ok=True)
shutil.copy2('brandbook/assets/logo/eje-mark-transparent.png', 'landing-page/public/brand/')

# Process TSX files
tsx_files = glob.glob('landing-page/src/**/*.tsx', recursive=True)

for file in tsx_files:
    with open(file, 'r') as f:
        content = f.read()

    # Replace logo paths
    content = content.replace('/brand/logo-horizontal-clean.png', '/brand/eje-mark-transparent.png')
    content = content.replace('/brand/logo-horizontal-white.png', '/brand/eje-mark-transparent.png')

    # Replace old company names
    content = content.replace('alt="Health Code"', 'alt="ejeweeka"')
    content = content.replace('alt="ezheWEEKa"', 'alt="ejeweeka"')
    content = content.replace('alt="Ежевика"', 'alt="ejeweeka"')

    # Replace hardcoded backgrounds with CSS variables
    content = content.replace('bg-[#0A0A0A]', 'bg-[var(--surface)]')
    content = content.replace('bg-[#111827]', 'bg-[var(--surface)]')
    content = content.replace('bg-[#050505]', 'bg-[var(--bg)]')
    content = content.replace('bg-[#1A1A1A]', 'bg-[var(--surface)]')
    content = content.replace('bg-[#1E1E1E]', 'bg-[var(--surface)]')
    
    # Text colors
    content = content.replace('text-[#A1A1A6]', 'text-[var(--text-muted)]')

    with open(file, 'w') as f:
        f.write(content)

print("Landing page UI fixed.")
