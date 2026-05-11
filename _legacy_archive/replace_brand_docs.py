import os

directory = '/Users/andreybuksa/Downloads/aidiet-docs'

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

for root, dirs, files in os.walk(directory):
    if '.git' in root or '.agents' in root or '.venv' in root or 'node_modules' in root:
        continue
    for file in files:
        if file.endswith(('.md', '.yaml', '.txt', '.json')):
            filepath = os.path.join(root, file)
            replace_in_file(filepath)

print("Done replacing docs.")
