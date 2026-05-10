// lib/features/onboarding/presentation/o2_goal_screen.dart
// O-2: Главная цель
// screens-map.md spec:
//   - Шаг 1/14. Одиночный выбор из 9 вариантов.
//   - Ветвление: 'Снизить вес' → O-4, 'Набрать мышцы'/'Поддержание' → сразу O-5
//   - Передаётся: goal

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/data/profile_repository.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/shared/widgets/motivating_tip_card.dart';
import 'package:health_code/shared/widgets/onboarding_scaffold.dart';
import 'package:health_code/shared/widgets/hc_check_item.dart';

const _goals = [
  ('weight_loss',        'Снизить вес'),
  ('muscle_gain',        'Набрать мышечную массу'),
  ('skin_hair_nails',    'Питание для кожи, ногтей, волос'),
  ('health_restrictions','Питание при ограничениях по здоровью'),
  ('age_adaptation',     'Адаптировать питание к возрасту (40+ / 50+ / 60+)'),
  ('reduce_cravings',    'Снизить тягу к сладкому и голод'),
  ('improve_energy',     'Улучшить самочувствие и энергию'),
  ('recovery',           'Восстановление после болезни/стресса'),
  ('maintenance',        'Поддержание веса'),
];

class O2GoalScreen extends ConsumerStatefulWidget {
  const O2GoalScreen({super.key});

  @override
  ConsumerState<O2GoalScreen> createState() => _O2GoalScreenState();
}

class _O2GoalScreenState extends ConsumerState<O2GoalScreen> {
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = ProfileRepository.getOrCreate().goal;
  }

  bool get _isValid => _selectedGoal != null;

  Future<void> _proceed() async {
    if (!_isValid) return;
    await ref.read(profileNotifierProvider.notifier).saveField('goal', _selectedGoal);
    if (!mounted) return;
    // Routing: weight_loss → O-4 (will be handled by GoRouter redirect)
    // All others → O-3 → O-5 (O-4 is conditionally skipped)
    context.go(Routes.o3Profile);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Какая у тебя главная цель?',
      subtitle: 'Выбери один вариант — это определит весь план',
      step: 1,
      totalSteps: 14,
      isValid: _isValid,
      onBack: () => context.go(Routes.o1Country),
      onNext: _proceed,
      content: Column(
        children: _goals.map((g) {
          final isSelected = _selectedGoal == g.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HcCheckItem(
              label: g.$2,
              selected: isSelected,
              onTap: () {
                setState(() => _selectedGoal = g.$1);
                ref.read(profileNotifierProvider.notifier).saveField('goal', g.$1);
              },
            ),
          );
        }).toList(),
      ),
      tip: const MotivatingTipCard(
        text: 'Разные цели — принципиально разные планы. При похудении важен дефицит калорий и контроль инсулина. При наборе массы — белок и тайминг питания. При усталости — железо, B12 и магний. Один шаблон не подходит всем. Именно твоя цель определяет всё: соотношение БЖУ, режим питания и приоритеты по витаминам.',
      ),
    );
  }
}
