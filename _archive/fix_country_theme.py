import re

with open('/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/main-screens/o1-country.html', 'r') as f:
    content = f.read()

# Replace dark theme variables with light theme variables
light_root = """:root {
      --color-primary: #F5922B;
      --color-primary-gradient: linear-gradient(135deg, #F59520, #E07018);
      --color-bg-main: #FAFAFA;
      --color-surface: #FFFFFF;
      --color-text-primary: #1A1A1A;
      --color-text-secondary: #6B7280;
      --color-divider: #E5E7EB;
      
      --card-bg: #FFFFFF;
      --card-border: #E5E7EB;
      --input-bg: #F3F4F6;
      --input-border: #D1D5DB;
      
      --text-main: #1A1A1A;
      --text-muted: #6B7280;
      --text-label: #9CA3AF;
      --text-placeholder: #9CA3AF;
    }"""

content = re.sub(r':root\s*{[^}]*}', light_root, content)

# Replace body background
content = content.replace("background-color: #0F0F1A;", "background-color: #E5E7EB;")

# Replace phone background
content = content.replace("background-color: var(--color-bg-dark);", "background-color: var(--color-bg-main);")

# Update status bar text color dynamically based on light theme
content = content.replace("color: #FFF;", "color: var(--text-main);")

# Update bottom CTA background to match light theme
content = content.replace("background: linear-gradient(0deg, #1A1A2E 65%, rgba(26,26,46,0.8) 85%, rgba(26,26,46,0) 100%);", "background: linear-gradient(180deg, rgba(250,250,250,0) 0%, rgba(250,250,250,0.95) 20%, rgba(250,250,250,1) 100%);")

# Update the selected country item background from active to a lighter orange
content = content.replace("background: rgba(255,107,53,0.08);", "background: #FFF7ED;")

# Change btn-primary active color to the gradient
content = content.replace("background: var(--color-primary);", "background: var(--color-primary-gradient); box-shadow: 0 4px 15px rgba(245, 146, 43, 0.3); border: none;")

# Make Step 2 (City) visible by default, but maybe greyed out, or just fully visible?
# The user asked "where is the city field AFTER selecting the region".
# The JS shows it, but maybe it's cut off by the motivation card overlapping it?
# Let's ensure it has enough scroll mapping.
# Or let's just make it visible initially.
content = content.replace("max-height: 0;\n      opacity: 0;\n      overflow: hidden;", "max-height: 200px;\n      opacity: 1;\n      overflow: visible;")
# remove step-2.active override
content = re.sub(r'#step-2\.active\s*{[^}]*}', '', content)
# remove JS that sets step2El active since it's already visible
content = content.replace("step2El.classList.add('active');", "")
content = content.replace("step2El.classList.remove('active');", "")

with open('/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/main-screens/o1-country.html', 'w') as f:
    f.write(content)

print("Theme and city field fixed")
