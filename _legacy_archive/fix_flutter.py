import re

theme_path = 'health_code/lib/core/theme/app_theme.dart'
with open(theme_path, 'r') as f:
    dart = f.read()

missing_colors = """  // Macros (Restored)
  static const primaryLight = Color(0xFFA855F7);
  static const protein = Color(0xFF52B044);
  static const fat = Color(0xFFF09030);
  static const carb = Color(0xFF42A5F5);"""

dart = dart.replace('static const neonMagenta = Color(0xFFD946EF);', 'static const neonMagenta = Color(0xFFD946EF);\n\n' + missing_colors)

with open(theme_path, 'w') as f:
    f.write(dart)
print("Fixed Flutter theme.")
