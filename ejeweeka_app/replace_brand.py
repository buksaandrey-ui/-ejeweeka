import os
import re

directories = [
    '/Users/andreybuksa/Downloads/ejeweeka-docs/ejeweeka_app/lib',
    '/Users/andreybuksa/Downloads/ejeweeka-docs/ejeweeka-backend'
]

replacements = {
    "Health Code": "ejeweeka",
    "HEALTH CODE": "EJEWEEKA",
    "Health code": "ejeweeka",
    "health code": "ejeweeka",
    "#F5922B": "#4C1D95",
    "F5922B": "4C1D95",
    "f5922b": "4c1d95"
}

def replace_in_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original = content
        for k, v in replacements.items():
            content = content.replace(k, v)
            
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filepath}")
    except Exception as e:
        pass

for directory in directories:
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(('.dart', '.py', '.md', '.json', '.yaml', '.html', '.js', '.ts', '.tsx')):
                filepath = os.path.join(root, file)
                replace_in_file(filepath)

print("Done replacing.")
