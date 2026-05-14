// lib/features/onboarding/presentation/o9_sleep_screen.dart
// O-9: Режим сна
// screens-map.md spec:
//   Шаг 8/14. bedtime + wakeup + авторасчёт длительности + конфликт с голоданием.
//   Передаётся: sleep_time, wake_time, sleep_pattern

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/hc_dropdown_field.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';

class O9SleepScreen extends ConsumerStatefulWidget {
  const O9SleepScreen({super.key});

  @override
  ConsumerState<O9SleepScreen> createState() => _O9SleepScreenState();
}

class _O9SleepScreenState extends ConsumerState<O9SleepScreen> {
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeup;
  bool _bedtimeVaries = false;
  bool _wakeupVaries = false;
  String? _sleepPattern;

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    
    if (p.bedtime == 'varies') {
      _bedtimeVaries = true;
    } else {
      _bedtime = (p.bedtime != null ? _parseTime(p.bedtime!) : null) ?? const TimeOfDay(hour: 23, minute: 0);
    }

    if (p.wakeupTime == 'varies') {
      _wakeupVaries = true;
    } else {
      _wakeup = (p.wakeupTime != null ? _parseTime(p.wakeupTime!) : null) ?? const TimeOfDay(hour: 7, minute: 0);
    }

    if (p.sleepPattern != null) _sleepPattern = p.sleepPattern;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveData();
    });
  }

  TimeOfDay? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  bool get _hasBedtime => _bedtimeVaries || _bedtime != null;
  bool get _hasWakeup => _wakeupVaries || _wakeup != null;
  bool get _isValid => _hasBedtime && _hasWakeup && (_sleepPattern != null || (!_bedtimeVaries && !_wakeupVaries));

  double? _sleepHours() {
    if (_bedtime == null || _wakeup == null) return null;
    double startHour = _bedtime!.hour + _bedtime!.minute / 60;
    double endHour = _wakeup!.hour + _wakeup!.minute / 60;
    if (endHour < startHour) endHour += 24;
    return endHour - startHour;
  }

  void _saveData() {
    final b = _bedtime;
    final w = _wakeup;
    final hours = _sleepHours();
    ref.read(profileNotifierProvider.notifier).saveFields({
      'bedtime': b != null ? '${b.hour.toString().padLeft(2,'0')}:${b.minute.toString().padLeft(2,'0')}' : (_bedtimeVaries ? 'varies' : null),
      'wakeup_time': w != null ? '${w.hour.toString().padLeft(2,'0')}:${w.minute.toString().padLeft(2,'0')}' : (_wakeupVaries ? 'varies' : null),
      'sleep_pattern': _sleepPattern ?? 'regular',
      'sleep_duration_hours': hours,
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (GoRouterState.of(context).uri.queryParameters["fromSummary"] == "true") return;
    if (mounted) context.go(Routes.o10Activity);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    super.dispose();
  }

  String _fmt(TimeOfDay? t) => t != null ? '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}' : '--:--';

  // ── Fasting conflict detection ──────────────────────────
  bool _hasFastingConflict(dynamic profile) {
    if (_bedtime == null) return false;
    final raw = ProfileRepository.getRawJson();
    if (raw['fasting_type'] != 'daily') return false;
    final windowEnd = raw['daily_window_end'] as String?;
    if (windowEnd == null) return false;
    final parts = windowEnd.split(':');
    if (parts.length != 2) return false;
    final endH = int.tryParse(parts[0]) ?? 0;
    final bedH = _bedtime!.hour + (_bedtime!.minute / 60);
    final endHour = endH.toDouble();
    return bedH < endHour;
  }

  String? _fastingWindowEnd() {
    final raw = ProfileRepository.getRawJson();
    return raw['daily_window_end'] as String?;
  }

  String? _fastingWindowStart() {
    final raw = ProfileRepository.getRawJson();
    return raw['daily_start'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';
    final hours = _sleepHours();
    final raw = ProfileRepository.getRawJson();
    final hasDailyFasting = raw['fasting_type'] == 'daily';

    return OnboardingScaffold(
      title: 'Режим сна',
      subtitle: 'Подстроим время приёмов пищи и витаминов под твой график',
      step: isWeightLoss ? 8 : 7,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o8MealPattern),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleep duration arc display
          if (hours != null) _sleepArc(hours),
          if (hours != null) const SizedBox(height: 20),

          // Bedtime
          _label('Ложусь спать в'),
          const SizedBox(height: 8),
          _timePicker(
            value: _bedtime, varies: _bedtimeVaries,
            onPick: () async {
              final t = await showTimePicker(context: context, initialTime: _bedtime ?? const TimeOfDay(hour: 23, minute: 0));
              if (t != null) { setState(() { _bedtime = t; _bedtimeVaries = false; }); _saveData(); }
            },
            onVaries: () { setState(() { _bedtimeVaries = !_bedtimeVaries; if (_bedtimeVaries) _bedtime = null; }); _saveData(); },
          ),
          const SizedBox(height: 12),

          // Wakeup
          _label('Просыпаюсь в'),
          const SizedBox(height: 8),
          _timePicker(
            value: _wakeup, varies: _wakeupVaries,
            onPick: () async {
              final t = await showTimePicker(context: context, initialTime: _wakeup ?? const TimeOfDay(hour: 7, minute: 0));
              if (t != null) { setState(() { _wakeup = t; _wakeupVaries = false; }); _saveData(); }
            },
            onVaries: () { setState(() { _wakeupVaries = !_wakeupVaries; if (_wakeupVaries) _wakeup = null; }); _saveData(); },
          ),

          // Fasting conflict warning
          if (_hasFastingConflict(profile)) ...[            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 20),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Ты ложитесь спать до окончания окна питания. Рекомендуем сдвинуть первый приём.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFE65100), height: 1.4),
                )),
              ]),
            ),
          ],

          // Fasting recommendation
          if (hasDailyFasting && _fastingWindowEnd() != null && !_hasFastingConflict(profile)) ...[            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Исходя из твоего окна питания ${_fastingWindowStart() ?? ""} – ${_fastingWindowEnd()}, рекомендуем ложиться не ранее ${_recommendedBedtime()}.',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF1565C0), height: 1.4),
              ),
            ),
          ],

          // Regular mode tip
          if (!hasDailyFasting && _bedtime != null && !_bedtimeVaries) ...[            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Последний приём пищи за 2–3 часа до сна оптимален для качества сна и пищеварения.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],

          // Sleep pattern (if varies)
          if (_bedtimeVaries || _wakeupVaries) ...[
            const SizedBox(height: 16),
            _label('Уточни режим'),
            const SizedBox(height: 8),
            _sleepPatternDropdown(),
          ],
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Плохой сон буквально меняет пищевое поведение. Всего одна ночь менее 6 часов повышает уровень грелина (гормон голода) на 28% и снижает лептин (гормон сытости). В итоге — незаметные лишние 300–400 ккал в день и постоянное ощущение, что «что-то не так». Время ужина и витамины мы рассчитаем под твой режим сна. Работаешь посменно или часто летаешь со сменой часовых поясов? Хаотичный сон — это не приговор для здорового питания, но он требует особого подхода. Мы учтём нестабильный режим и предложим гибкое расписание приёмов пищи, которое не рассыплется при пересменке.',
      ),
    );
  }

  String _recommendedBedtime() {
    final windowEnd = _fastingWindowEnd();
    if (windowEnd == null) return '';
    final parts = windowEnd.split(':');
    final h = (int.tryParse(parts[0]) ?? 0) + 2;
    return '${(h % 24).toString().padLeft(2, '0')}:${parts.length > 1 ? parts[1] : '00'}';
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));

  Widget _timePicker({required TimeOfDay? value, required bool varies, required VoidCallback onPick, required VoidCallback onVaries}) {
    return Column(
      children: [
        GestureDetector(
          onTap: varies ? null : onPick,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: varies ? const Color(0xFFF5F5F5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: value != null ? AppColors.primary : const Color(0xFFE5E7EB),
                width: value != null ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(Icons.access_time_rounded,
                color: varies ? AppColors.textDisabled : AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(varies ? 'По-разному' : _fmt(value),
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600,
                  color: varies ? AppColors.textDisabled : AppColors.textPrimary)),
              const Spacer(),
              if (!varies) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onVaries,
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: varies ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: varies ? AppColors.primary : const Color(0xFFD1D5DB), width: 2),
              ),
              child: varies ? const Icon(Icons.check_rounded, color: Colors.white, size: 11) : null,
            ),
            const SizedBox(width: 6),
            const Text('По-разному',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),
      ],
    );
  }

  Widget _sleepArc(double hours) {
    // 3-tier quality classification
    final String label;
    final Color color;
    final IconData icon;
    final String feedback;

    if (hours < 7) {
      label = 'Слишком мало';
      color = const Color(0xFFF44336);
      icon = Icons.warning_rounded;
      feedback = 'Недосып повышает грелин и снижает лептин — ты будешь переедать незаметно.';
    } else if (hours <= 9) {
      label = 'Идеально';
      color = const Color(0xFF52B044);
      icon = Icons.check_circle_rounded;
      feedback = 'Отлично! Здоровый сон снижает тягу к сладкому и помогает придерживаться плана.';
    } else {
      label = 'Много';
      color = const Color(0xFFF09030);
      icon = Icons.info_outline_rounded;
      feedback = 'Избыток сна может замедлять метаболизм. Мы адаптируем расписание приёмов пищи.';
    }

    final h = hours.floor();
    final m = ((hours - h) * 60).round();

    // Position for the indicator (0.0 = left, 1.0 = right)
    // Map: 4h = 0.0, 7h = 0.33, 9h = 0.67, 12h = 1.0
    final clampedHours = hours.clamp(4.0, 12.0);
    final indicatorPos = (clampedHours - 4.0) / 8.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Duration display
        const Text('ПРОДОЛЖИТЕЛЬНОСТЬ СНА',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Text('$h ч $m мин',
          style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 12),

        // Visual gradient bar
        SizedBox(
          height: 8,
          child: LayoutBuilder(builder: (ctx, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(children: [
              // Gradient background bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(colors: [
                    Color(0xFFF44336), // too little
                    Color(0xFFFFA726), // transition
                    Color(0xFF52B044), // ideal start
                    Color(0xFF52B044), // ideal end
                    Color(0xFFFFA726), // transition
                    Color(0xFFF09030), // too much
                  ], stops: [0.0, 0.3, 0.37, 0.62, 0.7, 1.0]),
                ),
              ),
              // Position indicator
              Positioned(
                left: (indicatorPos * barWidth - 6).clamp(0, barWidth - 12),
                top: -2,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.5),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                ),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 6),

        // Labels under bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Слишком мало', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: hours < 7 ? FontWeight.w700 : FontWeight.w500,
            color: hours < 7 ? const Color(0xFFF44336) : AppColors.textSecondary)),
          Text('Идеально', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: hours >= 7 && hours <= 9 ? FontWeight.w700 : FontWeight.w500,
            color: hours >= 7 && hours <= 9 ? const Color(0xFF52B044) : AppColors.textSecondary)),
          Text('Много', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: hours > 9 ? FontWeight.w700 : FontWeight.w500,
            color: hours > 9 ? const Color(0xFFF09030) : AppColors.textSecondary)),
        ]),
        const SizedBox(height: 10),

        // Feedback row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(feedback,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: color, fontWeight: FontWeight.w600, height: 1.4))),
        ]),
      ]),
    );
  }

  Widget _sleepPatternDropdown() {
    const List<(String, String, String?)> opts = [
      ('similar', 'Примерно одинаковый, но плавает', null),
      ('shift', 'Работаю посменно', null),
      ('irregular', 'Сплю мало и нерегулярно', null),
    ];
    
    String label = 'Выбери вариант';
    if (_sleepPattern != null) {
      final match = opts.where((o) => o.$1 == _sleepPattern).toList();
      if (match.isNotEmpty) {
        label = match.first.$2;
      } else {
        label = opts.first.$2;
      }
    }

    return HcDropdownField(
      label: label,
      isSelected: _sleepPattern != null,
      onTap: () async {
        final res = await showHcDropdownSheet<String>(
          context: context,
          title: 'Уточни режим',
          items: opts,
          selectedValue: _sleepPattern,
        );
        if (res != null) {
          setState(() { _sleepPattern = res; });
        }
      },
    );
  }
}
