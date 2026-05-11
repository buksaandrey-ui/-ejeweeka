import os

files = [
    'health_code/lib/features/profile/presentation/u_sub_screens.dart',
    'health_code/lib/features/profile/presentation/u12_status_screen.dart',
    'health_code/lib/features/chat/presentation/chat_screen.dart',
    'health_code/lib/features/progress/presentation/progress_screen.dart',
    'health_code/lib/shared/widgets/hc_dropdown_field.dart'
]

def find_matching_paren(s, start):
    count = 0
    for i in range(start, len(s)):
        if s[i] == '(':
            count += 1
        elif s[i] == ')':
            count -= 1
            if count == 0:
                return i
    return -1

def extract_on_pressed(block):
    # poor man's extraction
    lines = block.split('\n')
    on_pressed = None
    text = "'Кнопка'"
    
    # Very hacky, let's just do custom replacements since it's 5 files.
    # It's better to just manually construct the correct replacement string.
    pass

# I will just write custom Python string replacements using split() and replace()
# Since they are exactly 5 files left, I can read them and replace them by hand using python script but I'll print them first.

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    idx = content.find("ElevatedButton")
    if idx != -1:
        end_idx = find_matching_paren(content, content.find("(", idx))
        if end_idx != -1:
            print(f"--- {f} ---")
            print(content[idx:end_idx+1])
