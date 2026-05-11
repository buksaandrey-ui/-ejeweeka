import os

root_dir = '/Users/andreybuksa/Downloads/aidiet-docs'
extensions = ('.md', '.dart', '.html', '.yaml', '.py', '.tsx', '.ts', '.js', '.json')

count = 0
for dirpath, _, filenames in os.walk(root_dir):
    if '.git' in dirpath or '.dart_tool' in dirpath or 'build' in dirpath or '.pub-cache' in dirpath or 'node_modules' in dirpath or '.next' in dirpath:
        continue
    for filename in filenames:
        if filename.endswith(extensions):
            filepath = os.path.join(dirpath, filename)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if 'ejeweeka' in content:
                    new_content = content.replace('ejeweeka', 'ejeweeka')
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    count += 1
                    print(f"Updated: {filepath}")
            except Exception as e:
                pass

print(f"\nTotal files updated: {count}")
