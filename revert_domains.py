import os
import re

dirs_to_clean = ['ejeweeka_app', 'ejeweeka_backend', 'render.yaml']
replacements = [
    (re.compile(r'ejeweeka-api\.onrender\.com', re.IGNORECASE), 'aidiet-api.onrender.com'),
    (re.compile(r'app\.ejeweeka\.com', re.IGNORECASE), 'app.aidiet.com'),
    (re.compile(r'ejeweeka\.app', re.IGNORECASE), 'aidiet.app')
]

for d in dirs_to_clean:
    if os.path.isfile(d):
        files_to_process = [d]
    else:
        files_to_process = []
        for root, dirs, files in os.walk(d):
            if '.git' in root or '.dart_tool' in root or 'build' in root or 'Pods' in root or '__pycache__' in root:
                continue
            for file in files:
                if file.endswith(('.dart', '.py', '.md', '.plist', '.json', '.yaml', '.xcconfig')):
                    files_to_process.append(os.path.join(root, file))
                    
    for filepath in files_to_process:
        try:
            with open(filepath, 'r') as f:
                content = f.read()
            new_content = content
            for regex, repl in replacements:
                new_content = regex.sub(repl, new_content)
            if new_content != content:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Reverted domains in {filepath}")
        except Exception as e:
            pass
