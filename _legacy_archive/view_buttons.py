files_to_fix = [
    'health_code/lib/features/profile/presentation/u_sub_screens.dart',
    'health_code/lib/features/profile/presentation/u12_status_screen.dart',
    'health_code/lib/features/chat/presentation/chat_screen.dart',
    'health_code/lib/features/progress/presentation/progress_screen.dart',
    'health_code/lib/shared/widgets/hc_dropdown_field.dart'
]
import re

for file_path in files_to_fix:
    with open(file_path, 'r') as f:
        content = f.read()
    
    matches = re.finditer(r'(ElevatedButton(?:\.icon)?\([\s\S]*?\)(?=;|,))', content)
    for m in matches:
        print(f"--- {file_path} ---")
        # print up to 500 chars to not clutter
        print(m.group(1)[:500])
