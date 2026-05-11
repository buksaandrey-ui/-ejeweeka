path = 'health_code/lib/features/photo/presentation/photo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

if "import 'package:health_code/shared/widgets/hc_gradient_button.dart';" not in content:
    content = content.replace("import 'package:image_picker/image_picker.dart';", "import 'package:image_picker/image_picker.dart';\nimport 'package:health_code/shared/widgets/hc_gradient_button.dart';")
    with open(path, 'w') as f:
        f.write(content)
