import re

# --- Update globals.css ---
css_path = 'landing-page/src/app/globals.css'
with open(css_path, 'r') as f:
    css = f.read()

new_root = """:root {
  --bg: var(--color-bg-light);
  --surface: var(--color-surface-light);
  --text-main: var(--color-text-primary-light);
  --text-muted: var(--color-text-secondary-light);
  --border: var(--color-border-soft);
  --border-hover: var(--color-border-accent);
  --radius-md: 24px;
  --radius-lg: 32px;
}"""
css = re.sub(r':root\s*\{[^}]+\}', new_root, css, count=1)

with open(css_path, 'w') as f:
    f.write(css)

# --- Update app_theme.dart ---
theme_path = 'health_code/lib/core/theme/app_theme.dart'
with open(theme_path, 'r') as f:
    dart = f.read()

new_app_colors = """class AppColors {
  // Primary (ejeweeka)
  static const primary = Color(0xFF8B5CF6);
  static const primaryDark = Color(0xFF4C1D95);
  static const neonMagenta = Color(0xFFD946EF);
  
  // Gradients
  static const ctaGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background & Surface (Light Theme Default)
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF4F4F5);

  // Text
  static const textPrimary = Color(0xFF18181B);
  static const textSecondary = Color(0xFF71717A);
  static const textDisabled = Color(0xFFA1A1AA);

  // Feedback
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Tier colors
  static const tierWhite = Color(0xFFF9FAFB);
  static const tierBlack = Color(0xFF000000);
  static const tierGold = Color(0xFFF59E0B);
}"""
dart = re.sub(r'class AppColors \{.*?\n\}', new_app_colors, dart, flags=re.DOTALL)

dart = dart.replace('brightness: Brightness.dark,', 'brightness: Brightness.light,')
dart = dart.replace('scaffoldBackgroundColor: AppColors.background,', 'scaffoldBackgroundColor: AppColors.background,')

# Revert card borders for light theme
dart = dart.replace('side: const BorderSide(color: Color(0x14FFFFFF)),', 'side: const BorderSide(color: Color(0xFFE4E4E7)),')

with open(theme_path, 'w') as f:
    f.write(dart)

print("Updated themes to light mode.")
