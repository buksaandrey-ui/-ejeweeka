// lib/features/onboarding/presentation/o2_5_ai_personality_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/features/onboarding/data/profile_repository.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/shared/widgets/motivating_tip_card.dart';
import 'package:health_code/shared/widgets/onboarding_scaffold.dart';
import 'package:health_code/shared/widgets/hc_check_item.dart';

const _personalities = [
  ('premium', '🎩 Эстет (Стандарт)', 'Уважительный, строгий, статусный. Обращается как консьерж.'),
  ('buddy', '🤝 Свой человек', 'Теплый, свойский. Общается как лучший друг с легким сленгом.'),
  ('strict', '🦾 Железный тренер', 'Требовательный, нацеленный на дисциплину и результат.'),
  ('sassy', '😈 Дерзкий', 'Остроумный, подкалывает, мотивирует через вызов и сарказм.'),
];

class O25AiPersonalityScreen extends ConsumerStatefulWidget {
  const O25AiPersonalityScreen({super.key});

  @override
  ConsumerState<O25AiPersonalityScreen> createState() => _O25AiPersonalityScreenState();
}

class _O25AiPersonalityScreenState extends ConsumerState<O25AiPersonalityScreen> {
  String? _selectedPersonality;

  @override
  void initState() {
    super.initState();
    _selectedPersonality = ProfileRepository.getOrCreate().aiPersonality;
  }

  bool get _isValid => _selectedPersonality != null && _selectedPersonality!.isNotEmpty;

  Future<void> _proceed() async {
    if (!_isValid) return;
    await ref.read(profileNotifierProvider.notifier).saveField('ai_personality', _selectedPersonality);
    if (!mounted) return;
    context.go(Routes.o16Summary);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Выбери характер наставника',
      subtitle: 'Как нейросети с тобой общаться? Можно изменить позже',
      step: isWeightLoss ? 15 : 14,
      totalSteps: isWeightLoss ? 15 : 14,
      isValid: _isValid,
      onBack: () => context.go(Routes.o15FoodPrefs),
      onNext: _proceed,
      content: Column(
        children: _personalities.map((p) {
          final isSelected = _selectedPersonality == p.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HcCheckItem(
              label: p.$2,
              description: p.$3,
              selected: isSelected,
              onTap: () {
                setState(() => _selectedPersonality = p.$1);
                ref.read(profileNotifierProvider.notifier).saveField('ai_personality', p.$1);
              },
            ),
          );
        }).toList(),
      ),
      tip: const MotivatingTipCard(
        text: 'Выбор характера определяет тональность уведомлений, отчетов и генерации плана питания. Если сомневаешься — оставляй "Эстета", это наш премиальный стандарт.',
      ),
    );
  }
}
