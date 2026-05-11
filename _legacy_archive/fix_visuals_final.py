import os
import re

def process_file(filepath, replacements):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    with open(filepath, 'r') as f:
        content = f.read()
    
    for old, new in replacements:
        content = re.sub(old, new, content)
        
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Processed: {filepath}")

# 1. Fix page.tsx Typography and Buttons
page_replacements = [
    # Force text-main on headings
    (r'<h1([^>]*)>', r'<h1\1 style={{ color: "var(--text-main)", letterSpacing: "-0.02em" }}>'),
    (r'<h2([^>]*)>', r'<h2\1 style={{ color: "var(--text-main)", letterSpacing: "-0.02em" }}>'),
    (r'<h3([^>]*)text-\[var\(--text-main\)\]([^>]*)>', r'<h3\1text-[var(--text-main)]\2>'), # Already has it, but just in case
    (r'<h3([^>]*)>(?![^<]*var\(--text-main\))', r'<h3\1 style={{ color: "var(--text-main)" }}>'),
    
    # Fix the transparent button on Hero screen
    (r'className="([^"]*)border([^"]*)"([^>]*)>(\s*)Начать', 
     r'className="\1\2" style={{ background: "var(--gradient-neon-mark)", color: "#FFF", border: "none" }}>\4Начать'),
    
    # Replace Legacy Orange with Brand Purple
    (r'rgba\(245,146,43,0.3\)', r'rgba(76,29,149,0.3)'),
    (r'rgba\(245,146,43,0.5\)', r'rgba(76,29,149,0.5)'),
]

# Note: The first replacement might double up if already applied, so let's be careful.
with open('landing-page/src/app/page.tsx', 'r') as f:
    content = f.read()

# Typography
content = re.sub(r'<h1([^>]*) className="([^"]*)"([^>]*)>', r'<h1\1 className="\2 text-[var(--text-main)]"\3>', content)
content = re.sub(r'<h2([^>]*) className="([^"]*)"([^>]*)>', r'<h2\1 className="\2 text-[var(--text-main)]"\3>', content)
content = re.sub(r'<h3([^>]*) className="([^"]*)"([^>]*)>', r'<h3\1 className="\2 text-[var(--text-main)]"\3>', content)

# Remove duplicates if any
content = content.replace('text-[var(--text-main)] text-[var(--text-main)]', 'text-[var(--text-main)]')

# Buttons
content = re.sub(
    r'<button\s*onClick=\{scrollToContent\}\s*className="([^"]*)"\s*style=\{\{ border: "[^"]*", color: "[^"]*" \}\}\s*>',
    r'<button onClick={scrollToContent} className="\1" style={{ background: "var(--gradient-neon-mark)", color: "#FFF", border: "none" }}>',
    content
)

# Colors
content = content.replace('rgba(245,146,43,0.3)', 'rgba(76,29,149,0.3)')
content = content.replace('rgba(245,146,43,0.5)', 'rgba(76,29,149,0.5)')
content = content.replace('text-black', 'text-[var(--text-main)]')

with open('landing-page/src/app/page.tsx', 'w') as f:
    f.write(content)


# 2. Fix Subscribe and Payment pages
payment_files = [
    'landing-page/src/app/subscribe/page.tsx',
    'landing-page/src/app/payment/cancel/page.tsx',
    'landing-page/src/app/payment/success/page.tsx',
    'landing-page/src/app/payment/fail/page.tsx',
    'landing-page/src/app/success/page.tsx'
]

payment_replacements = [
    (r'text-gray-300', r'text-[var(--text-muted)]'),
    (r'text-gray-400', r'text-[var(--text-muted)]'),
    (r'text-gray-500', r'text-[var(--text-muted)]'),
    (r'bg-gray-500/20', r'bg-[var(--border)]'),
    (r'text-black', r'text-[var(--text-main)]'),
    (r'hover:bg-\[#E08120\]', r'hover:opacity-90'),
    (r'text-\[#B45309\]', r'text-[var(--primary)]'),
    (r'text-\[#92400E\]', r'text-[var(--primary)]'),
    (r'text-red-700', r'text-[var(--primary)]'),
    (r'text-red-800', r'text-[var(--primary)]'),
]

for file in payment_files:
    process_file(file, payment_replacements)

# 3. Fix Success Button
success_file = 'landing-page/src/app/success/page.tsx'
if os.path.exists(success_file):
    with open(success_file, 'r') as f:
        content = f.read()
    content = content.replace('bg-[var(--primary)] hover:opacity-90 text-[var(--text-main)]', 'bg-[var(--primary)] text-white hover:opacity-90')
    with open(success_file, 'w') as f:
        f.write(content)

print("Visual fixes applied.")
