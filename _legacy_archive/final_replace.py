import os

replacements = {
    'health_code/lib/features/profile/presentation/u_sub_screens.dart': (
"""ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white, shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Сохранить настройки', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                )""",
"""HcGradientButton(
                  onPressed: _save,
                  text: 'Сохранить настройки',
                )"""
    ),
    'health_code/lib/features/profile/presentation/u12_status_screen.dart': (
"""ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(_webBillingUrl), mode: LaunchMode.externalApplication),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Изменить статус',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
            )""",
"""HcGradientButton(
              onPressed: () => launchUrl(Uri.parse(_webBillingUrl), mode: LaunchMode.externalApplication),
              text: 'Изменить статус',
            )"""
    ),
    'health_code/lib/features/chat/presentation/chat_screen.dart': (
"""ElevatedButton(
        onPressed: () => launchUrl(
          Uri.parse('https://app.ejeweeka.com/subscribe'),
          mode: LaunchMode.externalApplication,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text('Повысить статус', style: TextStyle(fontFamily: 'Inter',
          fontSize: 12, fontWeight: FontWeight.w700)),
      )""",
"""HcGradientButton(
        onPressed: () => launchUrl(
          Uri.parse('https://app.ejeweeka.com/subscribe'),
          mode: LaunchMode.externalApplication,
        ),
        text: 'Повысить статус',
      )"""
    ),
    'health_code/lib/features/progress/presentation/progress_screen.dart': (
"""ElevatedButton(
            onPressed: () {
              final val = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
              if (val != null && val > 20 && val < 400) {
                _addEntry(val);
                _weightCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Замер $val кг сохранён'),
                    backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Сохранить', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          )""",
"""HcGradientButton(
            onPressed: () {
              final val = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
              if (val != null && val > 20 && val < 400) {
                _addEntry(val);
                _weightCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Замер $val кг сохранён'),
                    backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)));
              }
            },
            text: 'Сохранить',
          )"""
    ),
    'health_code/lib/shared/widgets/hc_dropdown_field.dart': (
"""ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Сохранить', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            )""",
"""HcGradientButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              text: 'Сохранить',
            )"""
    )
}

for path, (old, new) in replacements.items():
    with open(path, 'r') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(path, 'w') as f:
            f.write(content)
        print(f"Replaced perfectly in {path}")
    else:
        print(f"Could not find exact block in {path}")
