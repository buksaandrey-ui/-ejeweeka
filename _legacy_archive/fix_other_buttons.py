import re

def fix_file(path, old_pattern, new_text):
    with open(path, 'r') as f:
        content = f.read()
    content = re.sub(old_pattern, new_text, content)
    with open(path, 'w') as f:
        f.write(content)

# u_sub_screens.dart
fix_file('health_code/lib/features/profile/presentation/u_sub_screens.dart',
         r'ElevatedButton\(\s*onPressed: _save,\s*style: ElevatedButton\.styleFrom\([\s\S]*?child: const Text\(\'Сохранить\'\),\s*\)',
         """HcGradientButton(
                  onPressed: _save,
                  text: 'Сохранить',
                )""")

# u12_status_screen.dart
fix_file('health_code/lib/features/profile/presentation/u12_status_screen.dart',
         r'ElevatedButton\(\s*onPressed: \(\) => launchUrl\(Uri\.parse\(_webBillingUrl\)\),\s*style: ElevatedButton\.styleFrom\([\s\S]*?child: const Text\(\s*\'Управление подпиской\',\s*style: TextStyle\(fontSize: 16, fontWeight: FontWeight\.w600\),\s*\),\s*\)',
         """HcGradientButton(
              onPressed: () => launchUrl(Uri.parse(_webBillingUrl)),
              text: 'Управление подпиской',
            )""")

# chat_screen.dart
fix_file('health_code/lib/features/chat/presentation/chat_screen.dart',
         r'ElevatedButton\(\s*onPressed: \(\) => launchUrl\(\s*Uri\.parse\(\'https://app\.ejeweeka\.com/subscribe\'\)\s*\),\s*style: ElevatedButton\.styleFrom\([\s\S]*?child: const Text\(\s*\'Получить доступ\',\s*style: TextStyle\(fontWeight: FontWeight\.bold\),\s*\),\s*\)',
         """HcGradientButton(
        onPressed: () => launchUrl(Uri.parse('https://app.ejeweeka.com/subscribe')),
        text: 'Получить доступ',
      )""")

# progress_screen.dart
fix_file('health_code/lib/features/progress/presentation/progress_screen.dart',
         r'ElevatedButton\(\s*onPressed: \(\) \{[\s\S]*?_addWeightLog\(val\);\s*Navigator\.of\(context\)\.pop\(\);\s*\}\s*\},[\s\S]*?child: const Text\(\'Сохранить\'\),\s*\)',
         """HcGradientButton(
            onPressed: () {
              final val = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
              if (val != null && val > 0) {
                _addWeightLog(val);
                Navigator.of(context).pop();
              }
            },
            text: 'Сохранить',
          )""")

# hc_dropdown_field.dart
fix_file('health_code/lib/shared/widgets/hc_dropdown_field.dart',
         r'ElevatedButton\(\s*onPressed: \(\) => Navigator\.of\(context\)\.pop\(_selected\),[\s\S]*?child: const Text\(\'Готово\'\),\s*\)',
         """HcGradientButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              text: 'Готово',
            )""")

