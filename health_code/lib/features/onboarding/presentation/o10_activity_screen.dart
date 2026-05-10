// lib/features/onboarding/presentation/o10_activity_screen.dart
// O-10: Физическая активность
// screens-map.md spec:
//   Шаг 9/14. Частота (none/1/2/3/4+), длительность, виды, тоггл плана тренировок
//   Автоматический activity_multiplier: none=1.2, once/twice=1.375, three=1.55, four+=1.725
//   Передаётся: activity_level, activity_duration, activity_types, activity_multiplier

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/utils/bmr_calculator.dart';
import 'package:health_code/features/onboarding/data/profile_repository.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/shared/utils/input_formatter.dart';
import 'package:health_code/shared/widgets/hc_dropdown_field.dart';
import 'package:health_code/shared/widgets/motivating_tip_card.dart';
import 'package:health_code/shared/widgets/onboarding_scaffold.dart';

class O10ActivityScreen extends ConsumerStatefulWidget {
  const O10ActivityScreen({super.key});

  @override
  ConsumerState<O10ActivityScreen> createState() => _O10ActivityScreenState();
}

class _O10ActivityScreenState extends ConsumerState<O10ActivityScreen> {
  String? _frequency; // 'none' | 'once' | 'twice' | 'three' | 'four_plus'
  String? _duration;
  final Set<String> _types = {};
  final List<String> _customTypes = [];
  final _customTypeCtrl = TextEditingController();
  final _customTypeFocus = FocusNode();
  bool _wantsWorkoutPlan = false;

  static const _standardTypes = {
    'walking', 'running', 'strength', 'home_workout',
    'swimming', 'yoga', 'cycling', 'team_sports', 'pilates'
  };

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.activityLevel != null) _frequency = p.activityLevel;
    if (p.activityDuration != null) _duration = p.activityDuration;
    if (p.activityTypes.isNotEmpty) {
      for (final t in p.activityTypes) {
        if (_standardTypes.contains(t)) {
          _types.add(t);
        } else {
          _customTypes.add(t);
          _types.add(t);
        }
      }
    }
  }

  void _addCustomType(String text) {
    final formatted = InputFormatter.formatHealthData(text);
    if (formatted.isEmpty || _customTypes.contains(formatted)) return;
    setState(() {
      _customTypes.add(formatted);
      _types.add(formatted);
      _customTypeCtrl.clear();
    });
    _saveData();
  }

  void _removeCustomType(String text) {
    setState(() {
      _customTypes.remove(text);
      _types.remove(text);
    });
    _saveData();
  }

  bool get _isValid => _frequency != null &&
      (_frequency == 'none' || _duration != null);

  Future<void> _proceed() async {
    if (!_isValid) return;
    final multiplier = BmrCalculator.activityMultiplier(_frequency ?? 'none', duration: _duration);
    final p = ref.read(profileProvider);
    final bmr = p.bmrKcal ?? p.bmr ?? 0;
    final tdee = BmrCalculator.calculateTdee(bmr: bmr, activityMultiplier: multiplier);
    final targetCal = BmrCalculator.calculateTargetCalories(
      tdee: tdee,
      goal: p.goal ?? '',
      gender: p.gender ?? 'male',
      currentWeight: p.weight,
      targetWeight: p.targetWeight,
      timelineWeeks: p.targetTimelineWeeks,
      paceClassification: p.paceClassification,
    );
    final targetFiber = BmrCalculator.calculateTargetFiber(
      gender: p.gender ?? 'male', age: p.age ?? 30, goal: p.goal);
    await ref.read(profileNotifierProvider.notifier).saveFields({
      'activity_level': _frequency,
      'activity_duration': _duration,
      'activity_types': _types.toList(),
      'activity_multiplier': multiplier.toString(),
      'tdee_calculated': tdee,
      'target_daily_calories': targetCal,
      'target_daily_fiber': targetFiber,
    });
    if (mounted) context.go(Routes.o11Budget);
  }

  void _saveData() {
    final multiplier = BmrCalculator.activityMultiplier(_frequency ?? 'none', duration: _duration);
    ref.read(profileNotifierProvider.notifier).saveFields({
      'activity_level': _frequency,
      'activity_duration': _duration,
      'activity_types': _types.toList(),
      'activity_multiplier': multiplier.toString(),
    });
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _customTypeCtrl.dispose();
    _customTypeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Физическая активность',
      subtitle: 'Рассчитаем суточные калории с учётом нагрузки',
      step: isWeightLoss ? 9 : 8,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o9Sleep),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Частота
          _label('Сколько раз в неделю готов(а) к активности?'),
          const SizedBox(height: 10),
          _frequencyDropdown(),

          // Multiplier badge
          if (_frequency != null) ...[
            const SizedBox(height: 12),
            _multiplierBadge(),
          ],

          // Длительность (если частота ≥1)
          if (_frequency != null && _frequency != 'none') ...[
            const SizedBox(height: 20),
            _label('Сколько времени за тренировку?'),
            const SizedBox(height: 10),
            _durationDropdown(),
            const SizedBox(height: 20),
            _label('Виды активности'),
            const SizedBox(height: 10),
            _activityTypesDropdown(),
            if (_customTypes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customTypes.map((t) => _customChip(t, () => _removeCustomType(t))).toList(),
              ),
            ],
            const SizedBox(height: 10),
            _customInputField(
              controller: _customTypeCtrl,
              focusNode: _customTypeFocus,
              hint: 'Добавить свою активность...',
              onSubmit: _addCustomType,
            ),
          ],

          // Тоггл план тренировок
          const SizedBox(height: 20),
          _workoutPlanToggle(profile.subscriptionStatus),
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Не нужно бегать марафоны. 30 минут ходьбы в день снижают риск сердечно-сосудистых заболеваний на 30%. Если сейчас не готовы к тренировкам — это нормально. Начать с питания — уже 70% результата.',
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));

  Widget _frequencyDropdown() {
    const opts = [
      ('none', 'Не готов(а) сейчас', null),
      ('once', '1 раз в неделю', null),
      ('twice', '2 раза в неделю', null),
      ('three', '3 раза в неделю', null),
      ('four_plus', '4+ раза в неделю', null),
    ];
    final label = _frequency == null
        ? 'Выберите частоту'
        : opts.firstWhere((o) => o.$1 == _frequency, orElse: () => opts.first).$2;

    return HcDropdownField(
      label: label,
      isSelected: _frequency != null,
      onTap: () async {
        final res = await showHcDropdownSheet<String>(
          context: context,
          title: 'Частота активности',
          items: opts,
          selectedValue: _frequency,
        );
        if (res != null) {
          setState(() => _frequency = res);
          _saveData();
        }
      },
    );
  }

  Widget _multiplierBadge() {
    final mult = BmrCalculator.activityMultiplier(_frequency ?? 'none', duration: _duration);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text('Коэффициент активности: ×${mult.toStringAsFixed(3)}',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.primary)),
      ]),
    );
  }

  Widget _durationDropdown() {
    const opts = [
      ('10_15', '10–15 мин', null),
      ('20_30', '20–30 мин', null),
      ('30_45', '30–45 мин', null),
      ('45_60', '45–60 мин', null),
      ('60_plus', 'Более часа', null),
    ];
    final label = _duration == null
        ? 'Выберите длительность'
        : opts.firstWhere((o) => o.$1 == _duration, orElse: () => opts.first).$2;

    return HcDropdownField(
      label: label,
      isSelected: _duration != null,
      onTap: () async {
        final res = await showHcDropdownSheet<String>(
          context: context,
          title: 'Длительность',
          items: opts,
          selectedValue: _duration,
        );
        if (res != null) {
          setState(() => _duration = res);
          _saveData();
        }
      },
    );
  }

  Widget _activityTypesDropdown() {
    const types = [
      ('walking', 'Ходьба', null),
      ('running', 'Бег', null),
      ('strength', 'Силовые', null),
      ('home_workout', 'Домашние', null),
      ('swimming', 'Плавание', null),
      ('yoga', 'Йога/растяжка', null),
      ('cycling', 'Велосипед', null),
      ('team_sports', 'Командные', null),
      ('pilates', 'Пилатес', null),
    ];
    
    String label = 'Выберите виды';
    if (_types.isNotEmpty) {
      if (_types.length == 1) {
        label = types.firstWhere((t) => t.$1 == _types.first, orElse: () => types.first).$2;
      } else {
        label = 'Выбрано видов: ${_types.length}';
      }
    }

    return HcDropdownField(
      label: label,
      isSelected: _types.isNotEmpty,
      onTap: () async {
        final res = await showHcMultiSelectSheet<String>(
          context: context,
          title: 'Виды активности',
          items: types,
          initialSelected: _types,
        );
        if (res != null) {
          setState(() {
            _types.clear();
            _types.addAll(res);
          });
        }
      },
    );
  }

  Widget _workoutPlanToggle(String? tier) {
    // During onboarding (trial) all features are available
    final isAvailable = tier == null || tier == 'gold' || tier == 'family_gold' || tier == 'white';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Хочу план тренировок',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.tierGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
              child: const Text('Gold', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w700, color: AppColors.tierGold)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Персональная программа с учётом твоей активности',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
        ])),
        GestureDetector(
          onTap: () => setState(() => _wantsWorkoutPlan = !_wantsWorkoutPlan),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52, height: 28,
            decoration: BoxDecoration(
              color: _wantsWorkoutPlan ? AppColors.primary : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: 3,
                left: _wantsWorkoutPlan ? 27 : 3,
                child: Container(width: 22, height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x20000000), blurRadius: 4)])),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _customInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required void Function(String) onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (val) { onSubmit(val); focusNode.requestFocus(); },
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.primary),
            onPressed: () { onSubmit(controller.text); focusNode.requestFocus(); },
          ),
        ],
      ),
    );
  }

  Widget _customChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        const SizedBox(width: 6),
        GestureDetector(onTap: onRemove, child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.6))),
      ]),
    );
  }
}
