with open('landing-page/src/app/layout.tsx', 'r') as f:
    content = f.read()

import re
content = re.sub(r'<html([^>]*)>', r'<html\1 data-theme="light" className="theme-light">', content)
# Just in case it duplicates
content = content.replace('data-theme="light" className="theme-light" data-theme="light" className="theme-light"', 'data-theme="light" className="theme-light"')

with open('landing-page/src/app/layout.tsx', 'w') as f:
    f.write(content)
