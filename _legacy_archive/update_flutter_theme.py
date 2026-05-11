import re

theme_path = 'health_code/lib/core/theme/app_theme.dart'
with open(theme_path, 'r') as f:
    content = f.read()

# Replace AppColors
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

  // Background & Surface (Dark Theme Default)
  static const background = Color(0xFF0D0618);
  static const surface = Color(0xFF1A0A35);
  static const surfaceVariant = Color(0xFF221344);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textDisabled = Color(0xFF71717A);

  // Feedback
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Tier colors
  static const tierWhite = Color(0xFFF9FAFB);
  static const tierBlack = Color(0xFF000000);
  static const tierGold = Color(0xFFF59E0B);
}"""
content = re.sub(r'class AppColors \{.*?\n\}', new_app_colors, content, flags=re.DOTALL)

# Ensure Brightness.dark is used in materialPremium
content = content.replace('brightness: Brightness.light,', 'brightness: Brightness.dark,')
# Change default card colors and borders
content = content.replace('side: const BorderSide(color: Color(0xFFF0F0F0)),', 'side: const BorderSide(color: Color(0x14FFFFFF)),')
content = content.replace('side: const BorderSide(color: Color(0xFFE0E0E0)),', 'side: const BorderSide(color: Color(0x14FFFFFF)),')
content = content.replace('color: Color(0xFFF0F0F0),', 'color: Color(0x14FFFFFF),')

with open(theme_path, 'w') as f:
    f.write(content)

print("Updated flutter theme.")
