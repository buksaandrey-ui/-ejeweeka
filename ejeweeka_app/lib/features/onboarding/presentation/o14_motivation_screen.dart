// lib/features/onboarding/presentation/o14_motivation_screen.dart
// O-14: Мотивация и срывы
// screens-map.md: множественный выбор до 5 пунктов + «Другое» → текстовое поле
// Список: Постоянный голод / Тяга к сладкому / Срывы вечером /
//   Нет времени готовить / Ем на ходу / Сложно отказаться / Эмоциональное переедание /
//   Праздники / Не вижу результата / Пока не пробовал / Другое

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';

class O14MotivationScreen extends ConsumerStatefulWidget {
  const O14MotivationScreen({super.key});

  @override
  ConsumerState<O14MotivationScreen> createState() => _O14MotivationScreenState();
}

class _O14MotivationScreenState extends ConsumerState<O14MotivationScreen> {
  final Set<String> _barriers = {};
  final _otherCtrl = TextEditingController();
  static const _maxBarriers = 5;

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.motivationBarriers.isNotEmpty) _barriers.addAll(p.motivationBarriers);
  }

  bool get _isValid => _barriers.isNotEmpty;

  static const _options = <(String, String)>[
    ('hunger', 'Постоянный голод'),
    ('sweets', 'Тяга к сладкому'),
    ('evening_binge', 'Срывы вечером или ночью'),
    ('no_time', 'Нет времени готовить'),
    ('on_the_go', 'Ем на ходу или в разъездах'),
    ('hard_to_refuse', 'Сложно отказаться от привычной еды'),
    ('emotional', 'Эмоциональное переедание'),
    ('social', 'Праздники, семья, окружение'),
    ('no_results', 'Не вижу результата и теряю мотивацию'),
    ('never_tried', 'Пока не пробовал(а) всерьёз'),
  ];

  void _toggleBarrier(String key) {
    setState(() {
      if (_barriers.contains(key)) {
        _barriers.remove(key);
      } else if (_barriers.length < _maxBarriers) {
        _barriers.add(key);
      }
    });
    _saveData();
  }

  void _saveData() {
    final barriers = _barriers.toList();
    final other = _otherCtrl.text.trim();
    if (other.isNotEmpty && !barriers.contains('other')) barriers.add('other');
    ref.read(profileNotifierProvider.notifier).saveFields({
      'motivation_barriers': barriers,
      if (other.isNotEmpty) 'motivation_other': other,
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (mounted) context.go(Routes.o15FoodPrefs);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Что мешает питаться правильно?',
      subtitle: 'Выбери до $_maxBarriers пунктов — это поможет нам поддержать тебя',
      step: isWeightLoss ? 13 : 12,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o13Supplements),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._options.map((o) {
            final sel = _barriers.contains(o.$1);
            final canSelect = sel || _barriers.length < _maxBarriers;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: canSelect ? () => _toggleBarrier(o.$1) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFFF7ED) : (!canSelect ? const Color(0xFFF9F9F9) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: sel ? AppColors.primary : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                      child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(o.$2, style: TextStyle(
                      fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
                      color: sel ? AppColors.primary : (!canSelect ? AppColors.textDisabled : AppColors.textPrimary)))),
                  ]),
                ),
              ),
            );
          }),

          // «Другое» — текстовое поле
          const SizedBox(height: 4),
          _label('Другое (свой вариант)'),
          const SizedBox(height: 8),
          TextField(
            controller: _otherCtrl,
            decoration: const InputDecoration(
              hintText: 'Напишите свой вариант...',
            ),
            onChanged: (_) => _saveData(),
            maxLines: 1,
          ),

          // Счётчик
          const SizedBox(height: 8),
          Text('Выбрано: ${_barriers.length}/$_maxBarriers',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12,
              color: _barriers.length >= _maxBarriers ? AppColors.primary : AppColors.textSecondary)),
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'У 70% людей, начинающих менять питание, главный враг — не еда, а привычки и окружение. Если вечером срываешься на сладкое — это недоедание днём. Мы учтём твои барьеры и обойдём их.',
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));
}
