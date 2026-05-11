import os
import re

dirs_to_clean = ['ejeweeka_app', 'ejeweeka_backend', '01_architecture']
replacements = [
    (re.compile(r'health_code', re.IGNORECASE), 'ejeweeka_app'),
    (re.compile(r'healthcode', re.IGNORECASE), 'ejeweeka'),
    (re.compile(r'aidiet', re.IGNORECASE), 'ejeweeka')
]

for d in dirs_to_clean:
    for root, dirs, files in os.walk(d):
        if '.git' in root or '.dart_tool' in root or 'build' in root or 'Pods' in root or '__pycache__' in root:
            continue
        for file in files:
            filepath = os.path.join(root, file)
            if not file.endswith(('.dart', '.py', '.md', '.plist', '.json', '.yaml', '.xcconfig')):
                continue
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                new_content = content
                for regex, repl in replacements:
                    new_content = regex.sub(repl, new_content)
                if new_content != content:
                    with open(filepath, 'w') as f:
                        f.write(new_content)
                    print(f"Updated {filepath}")
            except Exception as e:
                pass
