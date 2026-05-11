import re

files_to_fix = [
    'health_code/lib/features/onboarding/presentation/activation_code_screen.dart',
    'health_code/lib/features/photo/presentation/photo_screen.dart',
    'health_code/lib/features/profile/presentation/u_sub_screens.dart',
    'health_code/lib/features/profile/presentation/u12_status_screen.dart',
    'health_code/lib/features/chat/presentation/chat_screen.dart',
    'health_code/lib/features/progress/presentation/progress_screen.dart',
    'health_code/lib/shared/widgets/hc_dropdown_field.dart'
]

# Specifically replace ElevatedButton(...) with HcGradientButton
for file_path in files_to_fix:
    with open(file_path, 'r') as f:
        content = f.read()

    # Generic replace for ElevatedButton( ... child: Text('...'))
    # This regex is a bit complex for nested parentheses, but let's do a basic one for our specific formatting
    
    # Let's use a simpler approach: 
    # Just print the file content where ElevatedButton is found, to craft exact replacements.
