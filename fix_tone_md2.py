import os
import re

replacements = [
    (r'\bВаш\b', 'Твой'), (r'\bваш\b', 'твой'),
    (r'\bВаша\b', 'Твоя'), (r'\bваша\b', 'твоя'),
    (r'\bВашей\b', 'Твоей'), (r'\bвашей\b', 'твоей'),
    (r'\bВашу\b', 'Твою'), (r'\bвашу\b', 'твою'),
    (r'\bВаши\b', 'Твои'), (r'\bваши\b', 'твои'),
    (r'\bВашего\b', 'Твоего'), (r'\bвашего\b', 'твоего'),
    (r'\bВашему\b', 'Твоему'), (r'\bвашему\b', 'твоему'),
    (r'\bВам\b', 'Тебе'), (r'\bвам\b', 'тебе'),
    (r'\bВас\b', 'Тебя'), (r'\bвас\b', 'тебя'),
    (r'\bВы\b', 'Ты'), (r'\bвы\b', 'ты'),
]

directories = ['.']

files_modified = 0
total_replacements = 0

for root, _, files in os.walk('.'):
    # skip node_modules and other huge dirs
    if 'node_modules' in root or '.git' in root or 'ios' in root or 'android' in root or 'build' in root or '.dart_tool' in root: continue
    
    for file in files:
        if not file.endswith('.md'):
            continue
        
        filepath = os.path.join(root, file)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
        except UnicodeDecodeError:
            continue
            
        new_content = content
        file_changed = False
        for pattern, repl in replacements:
            new_content, count = re.subn(pattern, repl, new_content)
            if count > 0:
                file_changed = True
                total_replacements += count
                
        if file_changed:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated: {filepath}")
            files_modified += 1

print(f"Done! Modified {files_modified} files with {total_replacements} replacements.")
