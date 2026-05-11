import re

path = 'health_code/lib/features/onboarding/presentation/o0_welcome_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# Replace _usps list
old_usps = """  final List<Map<String, dynamic>> _usps = [
    {
      'icon': Icons.medical_information_outlined,
      'title': 'Смарт-наставник',
      'desc': 'Алгоритмы на базе доказательной медицины от практикующих врачей. Никаких случайных генераций.',
    },
    {
      'icon': Icons.restaurant_menu_rounded,
      'title': 'Всё в одном плане',
      'desc': 'Что есть, как готовить, что купить, как тренироваться — под твой бюджет и свободное время.',
    },
    {
      'icon': Icons.medication_liquid_rounded,
      'title': 'Витамины работают',
      'desc': 'Железо с кофе — деньги на ветер. Составим расписание добавок, которое реально усвоится.',
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'title': 'Учтём все нюансы',
      'desc': 'Аллергии, беременность, подагра или веганство — план идеально подстроится под твой организм.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Калории по фото',
      'desc': 'Ужин в ресторане? Просто сфотографируй — смарт-алгоритм сам всё посчитает и пересчитает план.',
    },
  ];"""

new_usps = """  final List<Map<String, dynamic>> _usps = [
    {
      'icon': Icons.medical_information_outlined,
      'title': 'Смарт-наставник',
      'desc': 'Умные алгоритмы на базе 16 000+ материалов от практикующих экспертов, кандидатов и докторов наук. Никаких случайных мусорных генераций и общих диет.',
    },
    {
      'icon': Icons.restaurant_menu_rounded,
      'title': 'Всё в одном плане',
      'desc': 'Что есть, как готовить, что купить, как тренироваться под твой регион проживания, бюджет и свободное время?',
    },
    {
      'icon': Icons.medication_liquid_rounded,
      'title': 'Витамины работают',
      'desc': 'Железо с кофе — деньги на ветер. Без жиров витамин D3 не усваивается. Составим расписание добавок, которое реально усвоится.',
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'title': 'Учтём все нюансы',
      'desc': 'Аллергии, беременность, диабет или веганство - план идеально подстроится под твой организм.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Калории по фото',
      'desc': 'Ужин в ресторане? Просто сфотографируй — смарт-алгоритм всё сам посчитает и скорректирует план.',
    },
    {
      'icon': Icons.local_drink_outlined,
      'title': 'Напитки и алкоголь',
      'desc': 'Добавляй напитки, которые пьешь в течение дня — воду, кофе, сок, коктейли или алкоголь. Мы учтём их калории, состав и влияние алкоголя, и мягко скорректируем твой план на день.',
    },
    {
      'icon': Icons.fitness_center_outlined,
      'title': 'Полезная активность',
      'desc': 'Добавь активность на неделю — мы подберём тренировки под твоё время, цели и уровень нагрузки, а силовые грамотно распределим по группам мышц.',
    },
  ];"""

if old_usps in content:
    content = content.replace(old_usps, new_usps)
    print("Replaced USPS successfully")
else:
    print("Could not find old_usps")

# Replace Logo sizing
old_logo = """                const SizedBox(height: 50), // Increased from 40 to move down 10px
                // Logo
                Image.asset('assets/logo/ejeweeka-inline-wordmark@2x.png', height: 40),"""

new_logo = """                const SizedBox(height: 60), // Increased from 50 to move down 10px
                // Logo
                Image.asset('assets/logo/ejeweeka-inline-wordmark@2x.png', height: 80),"""

if old_logo in content:
    content = content.replace(old_logo, new_logo)
    print("Replaced Logo sizes successfully")
else:
    print("Could not find old_logo")

with open(path, 'w') as f:
    f.write(content)
