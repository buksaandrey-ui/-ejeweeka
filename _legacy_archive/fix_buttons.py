import os
import re

files_to_fix = [
    'lib/features/onboarding/presentation/activation_code_screen.dart',
    'lib/features/photo/presentation/photo_screen.dart',
    'lib/features/profile/presentation/u_sub_screens.dart',
    'lib/features/profile/presentation/u12_status_screen.dart',
    'lib/features/chat/presentation/chat_screen.dart',
    'lib/features/progress/presentation/progress_screen.dart',
    'lib/shared/widgets/hc_dropdown_field.dart'
]

import_statement = "import 'package:health_code/shared/widgets/hc_gradient_button.dart';\n"

for f in files_to_fix:
    path = os.path.join('health_code', f)
    if os.path.exists(path):
        with open(path, 'r') as file:
            content = file.read()
        
        # Add import if missing
        if 'HcGradientButton' not in content and 'hc_gradient_button.dart' not in content:
            # insert after flutter imports or at top
            if 'import \'package:flutter' in content:
                content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)
            else:
                content = import_statement + content

        # We will use regex to replace ElevatedButton blocks.
        # This is a bit risky but we can replace specific patterns.
        # For simple ElevatedButton(onPressed: X, style: Y, child: Text(Z))
        # It's better to just write a simple parsing loop or custom regex per file
        
        with open(path, 'w') as file:
            file.write(content)
