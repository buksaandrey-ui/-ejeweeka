// lib/features/onboarding/presentation/o8_meal_pattern_screen.dart
// O-8: Режим питания и голодание
// screens-map.md spec:
//   Шаг 7/14. Блок 1: кол-во приёмов. Блок 2: Голодание
//   Тип голодания: Ежедневное (интервальное) / Периодическое
//   Передаётся: meal_pattern, fasting_attitude, fasting_type, daily_format, etc.

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

class O8MealPatternScreen extends ConsumerStatefulWidget {
  const O8MealPatternScreen({super.key});

  @override
  ConsumerState<O8MealPatternScreen> createState() => _O8MealPatternScreenState();
}

class _O8MealPatternScreenState extends ConsumerState<O8MealPatternScreen> {
  // ── Блок 1: Режим питания ──────────────────────────────────
  String? _mealPattern; // '2_meals' | '3_meals' | '4_plus' | 'flexible'
  Map<String, TimeOfDay> _mealTimes = {};

  // ── Блок 2: Голодание ──────────────────────────────────────
  String _fastingAttitude = 'no'; // 'no' | 'yes' | 'want'
  String? _fastingKind;           // 'daily' | 'periodic' (тип голодания)

  // Ежедневное (интервальное)
  String? _dailyFormat;  // '14_10' | '16_8' | '18_6' | '20_4'
  TimeOfDay _dailyStart = const TimeOfDay(hour: 12, minute: 0);
  int _dailyMeals = 2;

  // Периодическое
  String? _periodicFormat; // '24h' | '36h' | '5_2'
  String _periodicFreq = 'weekly'; // 'weekly' | 'biweekly'
  final Set<int> _periodicDays = {}; // 0=Пн .. 6=Вс
  TimeOfDay _periodicStart = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.mealPattern != null) _mealPattern = p.mealPattern;

    // Restore meal times based on pattern
    if (_mealPattern == '2_meals') {
      _mealTimes = {'Приём 1': const TimeOfDay(hour: 12, minute: 0), 'Приём 2': const TimeOfDay(hour: 18, minute: 0)};
    } else if (_mealPattern == '3_meals') {
      _mealTimes = {'Завтрак': const TimeOfDay(hour: 8, minute: 0), 'Обед': const TimeOfDay(hour: 13, minute: 0), 'Ужин': const TimeOfDay(hour: 19, minute: 0)};
    } else if (_mealPattern == '4_plus') {
      _mealTimes = {'Завтрак': const TimeOfDay(hour: 8, minute: 0), 'Обед': const TimeOfDay(hour: 13, minute: 0), 'Перекус': const TimeOfDay(hour: 16, minute: 0), 'Ужин': const TimeOfDay(hour: 19, minute: 0)};
    }

    final raw = ProfileRepository.getRawJson();

    // Restore fasting attitude
    if (raw.containsKey('fasting_attitude')) {
      _fastingAttitude = raw['fasting_attitude'] as String? ?? 'no';
    }

    // Restore fasting type and all sub-fields
    if (raw.containsKey('fasting_type')) {
      final ft = raw['fasting_type'] as String? ?? 'none';
      if (ft == 'daily') {
        _fastingKind = 'daily';
        _dailyFormat = raw['daily_format'] as String?;
        // Restore daily start time
        final ds = raw['daily_start'] as String?;
        if (ds != null) {
          final parts = ds.split(':');
          if (parts.length == 2) {
            _dailyStart = TimeOfDay(hour: int.tryParse(parts[0]) ?? 12, minute: int.tryParse(parts[1]) ?? 0);
          }
        }
        // Restore meals in window
        if (raw.containsKey('daily_meals')) {
          _dailyMeals = (raw['daily_meals'] as num?)?.toInt() ?? 2;
        }
      } else if (ft == 'periodic') {
        _fastingKind = 'periodic';
        _periodicFormat = raw['periodic_format'] as String?;
        // Restore periodic frequency
        if (raw.containsKey('periodic_freq')) {
          _periodicFreq = raw['periodic_freq'] as String? ?? 'weekly';
        }
        // Restore periodic days
        if (raw.containsKey('periodic_days')) {
          final days = raw['periodic_days'];
          if (days is List) {
            _periodicDays.clear();
            for (final d in days) {
              _periodicDays.add((d as num).toInt());
            }
          }
        }
        // Restore periodic start time
        final ps = raw['periodic_start'] as String?;
        if (ps != null) {
          final parts = ps.split(':');
          if (parts.length == 2) {
            _periodicStart = TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts[1]) ?? 0);
          }
        }
      }
    }
  }

  bool get _isValid => _mealPattern != null;

  int _windowHours(String? fmt) => switch (fmt) {
    '14_10' => 10, '16_8' => 8, '18_6' => 6, '20_4' => 4, _ => 8,
  };

  String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dailyEndTime() {
    final hours = _windowHours(_dailyFormat);
    final endHour = (_dailyStart.hour + hours) % 24;
    return '${endHour.toString().padLeft(2, '0')}:${_dailyStart.minute.toString().padLeft(2, '0')}';
  }

  void _saveData() {
    final String fastingType;
    if (_fastingAttitude == 'no' || _fastingKind == null) {
      fastingType = 'none';
    } else {
      fastingType = _fastingKind!;
    }
    ref.read(profileNotifierProvider.notifier).saveFields({
      'meal_pattern': _mealPattern,
      'fasting_attitude': _fastingAttitude,
      'fasting_type': fastingType,
      if (fastingType == 'daily') ...{
        'daily_format': _dailyFormat,
        'daily_start': _fmtTime(_dailyStart),
        'daily_meals': _dailyMeals,
        'daily_window_end': _dailyEndTime(),
      },
      if (fastingType == 'periodic') ...{
        'periodic_format': _periodicFormat,
        'periodic_freq': _periodicFreq,
        'periodic_days': _periodicDays.toList()..sort(),
        'periodic_start': _fmtTime(_periodicStart),
      },
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (mounted) context.go(Routes.o9Sleep);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Режим питания',
      subtitle: 'Встроим здоровое питание в твою реальную жизнь',
      step: isWeightLoss ? 7 : 6,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => profile.gender == 'female'
          ? context.go(Routes.o7WomensHealth)
          : context.go(Routes.o6Health),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Блок 1: Сколько раз в день ────────────────────────
          _label('Сколько раз в день ты обычно ешь?'),
          const SizedBox(height: 10),
          _mealPatternDropdown(),

          const SizedBox(height: 24),

          // ── Блок 2: Голодание ─────────────────────────────────
          _label('Голодание (интервальное / периодическое)'),
          const SizedBox(height: 10),
          _fastingAttitudeDropdown(),

          // ── Тип голодания (если да/хочу) ─────────────────────
          if (_fastingAttitude != 'no') ...[
            const SizedBox(height: 16),
            if (_fastingAttitude == 'want') Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '✨ Рекомендуем начать с 16:8 — самый популярный формат. Пропускаешь завтрак, ешь в окне 8 часов.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),

            // Тип голодания: Ежедневное / Периодическое
            _label('Тип голодания'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _kindBtn('Ежедневное', 'daily')),
              const SizedBox(width: 10),
              Expanded(child: _kindBtn('Периодическое', 'periodic')),
            ]),

            // ── Ежедневное (интервальное) ──────────────────────
            if (_fastingKind == 'daily') ...[
              const SizedBox(height: 16),
              _label('Формат'),
              const SizedBox(height: 8),
              _dailyFormats(),
              if (_dailyFormat != null) ...[
                const SizedBox(height: 12),
                _windowBadge(),
                const SizedBox(height: 12),
                _label('Первый приём пищи'),
                const SizedBox(height: 8),
                _timePicker(_dailyStart, (t) { setState(() => _dailyStart = t); _saveData(); }),
                const SizedBox(height: 12),
                _label('Приёмов в окне питания'),
                const SizedBox(height: 8),
                _mealsInWindow(),
              ],
            ],

            // ── Периодическое ──────────────────────────────────
            if (_fastingKind == 'periodic') ...[
              const SizedBox(height: 16),
              _label('Формат'),
              const SizedBox(height: 8),
              _periodicFormats(),
              if (_periodicFormat != null) ...[
                const SizedBox(height: 12),
                _label('Частота'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _freqBtn('Раз в неделю', 'weekly')),
                  const SizedBox(width: 10),
                  Expanded(child: _freqBtn('Раз в 2 недели', 'biweekly')),
                ]),
                const SizedBox(height: 12),
                _label('Дни голодания'),
                const SizedBox(height: 8),
                _dayPicker(),
                const SizedBox(height: 12),
                _label('Время начала голодания'),
                const SizedBox(height: 8),
                _timePicker(_periodicStart, (t) { setState(() => _periodicStart = t); _saveData(); }),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'В обычные дни — режим питания из блока выше (${_mealPatternLabel()}).',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF1565C0), height: 1.4),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Нет плохого режима питания — есть неподходящий лично тебе. Если ты не завтракаешь — не нужно заставлять себя.',
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));

  String _mealPatternLabel() {
    const map = {'2_meals': '2 приёма', '3_meals': '3 приёма', '4_plus': '4+', 'flexible': 'Гибко'};
    return map[_mealPattern] ?? 'не выбран';
  }

  // ── Блок 1: Режим питания dropdown ──────────────────────────
  Widget _mealPatternDropdown() {
    const options = [
      ('2_meals',   '2 приёма', null),
      ('3_meals',   '3 приёма', 'Классика'),
      ('4_plus',    '4 и более', 'Дробно'),
      ('flexible',  'Как получится', 'Гибко'),
    ];
    final label = _mealPattern == null
        ? 'Выбери режим'
        : options.firstWhere((o) => o.$1 == _mealPattern, orElse: () => options.first).$2;

    return Column(children: [
      HcDropdownField(
        label: label,
        isSelected: _mealPattern != null,
        onTap: () async {
          final res = await showHcDropdownSheet<String>(
            context: context,
            title: 'Сколько раз в день ешь?',
            items: options,
            selectedValue: _mealPattern,
          );
          if (res != null) {
            setState(() {
              _mealPattern = res;
              if (res == '2_meals') {
                _mealTimes = {'Приём 1': const TimeOfDay(hour: 12, minute: 0), 'Приём 2': const TimeOfDay(hour: 18, minute: 0)};
              } else if (res == '3_meals') {
                _mealTimes = {'Завтрак': const TimeOfDay(hour: 8, minute: 0), 'Обед': const TimeOfDay(hour: 13, minute: 0), 'Ужин': const TimeOfDay(hour: 19, minute: 0)};
              } else if (res == '4_plus') {
                _mealTimes = {'Завтрак': const TimeOfDay(hour: 8, minute: 0), 'Обед': const TimeOfDay(hour: 13, minute: 0), 'Перекус': const TimeOfDay(hour: 16, minute: 0), 'Ужин': const TimeOfDay(hour: 19, minute: 0)};
              }
            });
            _saveData();
          }
        },
      ),
      // Meal time pickers (only if no fasting or periodic fasting — not daily)
      if (_mealPattern != null && _mealPattern != 'flexible' && _fastingKind != 'daily') ...[
        const SizedBox(height: 16),
        ..._mealTimes.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _timePicker(e.value, (t) { setState(() => _mealTimes[e.key] = t); _saveData(); },
            prefix: e.key),
        )),
      ],
    ]);
  }

  // ── Блок 2: Голодание ──────────────────────────────────────
  Widget _fastingAttitudeDropdown() {
    const opts = [
      ('no',   'Не практикую и не планирую', null),
      ('yes',  'Да, практикую', null),
      ('want', 'Хочу попробовать', null),
    ];
    final label = opts.firstWhere((o) => o.$1 == _fastingAttitude, orElse: () => opts.first).$2;

    return HcDropdownField(
      label: label,
      isSelected: true,
      onTap: () async {
        final res = await showHcDropdownSheet<String>(
          context: context,
          title: 'Голодание',
          items: opts,
          selectedValue: _fastingAttitude,
        );
        if (res != null) {
          setState(() {
            _fastingAttitude = res;
            if (res == 'want') {
              _fastingKind = 'daily';
              _dailyFormat = '16_8';
            }
            if (res == 'yes' && _fastingKind == null) {
              _fastingKind = 'daily';
            }
            if (res == 'no') {
              _fastingKind = null;
            }
          });
          _saveData();
        }
      },
    );
  }

  // ── Тип: Ежедневное / Периодическое ───────────────────────
  Widget _kindBtn(String label, String value) {
    final sel = _fastingKind == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _fastingKind = value;
          if (value == 'daily' && _dailyFormat == null) _dailyFormat = '16_8';
          if (value == 'periodic' && _periodicFormat == null) _periodicFormat = '24h';
        });
        _saveData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
          color: sel ? AppColors.primary : AppColors.textPrimary))),
      ),
    );
  }

  // ── Ежедневное: форматы ────────────────────────────────────
  Widget _dailyFormats() {
    const fmts = [
      ('14_10', '14:10', 'Мягкий'),
      ('16_8', '16:8', 'Классика'),
      ('18_6', '18:6', 'Строгий'),
      ('20_4', '20:4', 'Экстрим'),
    ];
    return Row(children: fmts.map((f) {
      final sel = _dailyFormat == f.$1;
      return Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () { setState(() => _dailyFormat = f.$1); _saveData(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFFFF7ED) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
            ),
            child: Column(children: [
              Text(f.$2, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700,
                color: sel ? AppColors.primary : AppColors.textPrimary)),
              Text(f.$3, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ),
        ),
      ));
    }).toList());
  }

  // ── Ежедневное: приёмы в окне ──────────────────────────────
  Widget _mealsInWindow() {
    return Row(children: [2, 3].map((n) {
      final windowH = _windowHours(_dailyFormat);
      final enabled = windowH >= 8 || n == 2;
      final sel = _dailyMeals == n;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: enabled ? () { setState(() => _dailyMeals = n); _saveData(); } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64, height: 48,
            decoration: BoxDecoration(
              color: !enabled ? const Color(0xFFF5F5F5) : sel ? const Color(0xFFFFF7ED) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
            ),
            child: Center(child: Text('$n',
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700,
                color: !enabled ? AppColors.textDisabled : sel ? AppColors.primary : AppColors.textPrimary))),
          ),
        ),
      );
    }).toList());
  }

  // ── Ежедневное: плашка окна питания ────────────────────────
  Widget _windowBadge() {
    final hours = _windowHours(_dailyFormat);
    final start = _fmtTime(_dailyStart);
    final end = _dailyEndTime();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF52B044), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Окно питания: $start — $end (${hours}ч). $_dailyMeals приёма.',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32)))),
      ]),
    );
  }

  // ── Периодическое: форматы ─────────────────────────────────
  Widget _periodicFormats() {
    const fmts = [
      ('24h', '24 часа', '1 день'),
      ('36h', '36 часов', '1.5 дня'),
      ('5_2', '5:2', '2 дня'),
    ];
    return Row(children: fmts.map((f) {
      final sel = _periodicFormat == f.$1;
      return Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _periodicFormat = f.$1;
              // Reset days if limit changed
              final maxDays = f.$1 == '5_2' ? 2 : 1;
              while (_periodicDays.length > maxDays) {
                _periodicDays.remove(_periodicDays.last);
              }
            });
            _saveData();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFFFF7ED) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
            ),
            child: Column(children: [
              Text(f.$2, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700,
                color: sel ? AppColors.primary : AppColors.textPrimary)),
              Text(f.$3, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ),
        ),
      ));
    }).toList());
  }

  // ── Периодическое: частота ─────────────────────────────────
  Widget _freqBtn(String label, String value) {
    final sel = _periodicFreq == value;
    return GestureDetector(
      onTap: () { setState(() => _periodicFreq = value); _saveData(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
          color: sel ? AppColors.primary : AppColors.textPrimary))),
      ),
    );
  }

  // ── Периодическое: выбор дней ──────────────────────────────
  Widget _dayPicker() {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final maxDays = _periodicFormat == '5_2' ? 2 : 1;
    return Row(children: List.generate(7, (i) {
      final sel = _periodicDays.contains(i);
      final canSelect = sel || _periodicDays.length < maxDays;
      return Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: canSelect ? () {
            setState(() {
              if (sel) { _periodicDays.remove(i); }
              else { _periodicDays.add(i); }
            });
            _saveData();
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 42,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : (!canSelect ? const Color(0xFFF5F5F5) : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Center(child: Text(days[i], style: TextStyle(
              fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
              color: sel ? Colors.white : (!canSelect ? AppColors.textDisabled : AppColors.textPrimary)))),
          ),
        ),
      ));
    }));
  }

  // ── Универсальный time picker ───────────────────────────────
  Widget _timePicker(TimeOfDay value, ValueChanged<TimeOfDay> onChanged, {String? prefix}) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: value);
        if (t != null) onChanged(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(children: [
          if (prefix != null) ...[
            Text(prefix, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
          ],
          const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(_fmtTime(value),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
          if (prefix == null) ...[
            const Spacer(),
            const Text('Нажми чтобы изменить',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ],
        ]),
      ),
    );
  }
}
