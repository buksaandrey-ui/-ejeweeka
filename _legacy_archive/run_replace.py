import re

def replace_button(path):
    with open(path, 'r') as f:
        content = f.read()

    # We need to replace ElevatedButton blocks.
    # This regex is an approximation. Let's do it safely.
    if "activation_code_screen.dart" in path:
        new_btn = """              HcGradientButton(
                onPressed: _isLoading ? null : _activateCode,
                text: 'Активировать Статус Gold',
                isLoading: _isLoading,
              ),"""
        content = re.sub(r'ElevatedButton\([\s\S]*?style:\s*ElevatedButton\.styleFrom[\s\S]*?child:\s*_isLoading[\s\S]*?Активировать Статус Gold[\s\S]*?\),', new_btn, content)
        
    elif "photo_screen.dart" in path:
        new_btn = """  Widget _pickerBtn(IconData icon, String label, ImageSource source) =>
    HcGradientButton(
      onPressed: _loading ? null : () => _pickImage(source),
      icon: icon,
      text: label,
    );"""
        content = re.sub(r'Widget _pickerBtn[\s\S]*?ElevatedButton\.icon\([\s\S]*?\);', new_btn, content)
        
    with open(path, 'w') as f:
        f.write(content)

replace_button('health_code/lib/features/onboarding/presentation/activation_code_screen.dart')
replace_button('health_code/lib/features/photo/presentation/photo_screen.dart')
