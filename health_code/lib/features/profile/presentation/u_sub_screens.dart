// lib/features/profile/presentation/u_sub_screens.dart
// U-4..U-11, U-13..U-15: Profile sub-screens — editable forms with persistence
// Each screen reads profile data and saves changes via ProfileNotifier
// Спека: screens-map.md §U-4..U-15

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/widgets/status_gate.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

// ── Shared helpers ──────────────────────────────────────────────────

AppBar _appBar(BuildContext ctx, String t) => AppBar(
  backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
  leading: IconButton(onPressed: () => Navigator.pop(ctx),
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
  title: Text(t, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
  centerTitle: true,
);

Widget _card(String title, String body) => Container(
  margin: const EdgeInsets.only(bottom: 12), width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE5E7EB))),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8)),
    const SizedBox(height: 8),
    Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5)),
  ]),
);

Widget _row(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(children: [
    Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
      color: AppColors.textSecondary))),
    Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
  ]),
);

// ── U-4: Ограничения и аллергии ─────────────────────────────────

class U4RestrictionsScreen extends ConsumerWidget {
  const U4RestrictionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Ограничения и аллергии'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('ОГРАНИЧЕНИЯ В ЕДЕ', p.diets?.isNotEmpty == true ? p.diets!.join(', ') : 'Нет ограничений'),
          _card('АЛЛЕРГИИ', p.hasAllergies == true
            ? (p.allergies?.join(', ') ?? 'Есть (не указаны)')
            : 'Нет аллергий'),
        ]),
      ),
    );
  }
}

// ── U-5: Витамины и БАДы ─────────────────────────────────────────

class U5VitaminsScreen extends ConsumerWidget {
  const U5VitaminsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Витамины и БАДы'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('ТЕКУЩИЙ ПРИЁМ', p.currentlyTakesSupplements
            ? (p.supplements ?? 'Принимает')
            : 'Не принимает'),
          _card('ГОТОВНОСТЬ К РЕКОМЕНДАЦИЯМ', p.supplementOpenness ?? 'Не указано'),
        ]),
      ),
    );
  }
}

// ── U-6: Анализы ─────────────────────────────────────────────────

class U6BloodTestsScreen extends ConsumerWidget {
  const U6BloodTestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Анализы'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          if (p.bloodTests != null && p.bloodTests!.isNotEmpty)
            _card('РЕЗУЛЬТАТЫ', p.bloodTests!)
          else
            _card('АНАЛИЗЫ', 'Нет свежих анализов'),
        ]),
      ),
    );
  }
}

// ── U-7: Вкусы и предпочтения ───────────────────────────────────

class U7FoodPrefsScreen extends ConsumerWidget {
  const U7FoodPrefsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Вкусы и предпочтения'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('НЕЖЕЛАТЕЛЬНЫЕ КАТЕГОРИИ',
            p.excludedMealTypes.isNotEmpty ? p.excludedMealTypes.join(', ') : 'Нет исключений'),
          _card('ЛЮБИМЫЕ ПРОДУКТЫ', p.likedFoods.isNotEmpty ? p.likedFoods.join(', ') : 'Не указаны'),
          _card('НЕЛЮБИМЫЕ ПРОДУКТЫ', p.dislikedFoods.isNotEmpty ? p.dislikedFoods.join(', ') : 'Не указаны'),
        ]),
      ),
    );
  }
}

// ── U-8: Режим дня ──────────────────────────────────────────────

class U8ScheduleScreen extends ConsumerWidget {
  const U8ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);

    final mealLabel = switch (p.mealPattern) {
      '2' => '2 приёма',
      '3' => '3 приёма',
      '4+' || '4' => '4+ приёма',
      'no_pattern' => 'Без режима',
      'snacker' => 'Часто перекусываю',
      _ => p.mealPattern ?? '—',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Режим дня'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('РЕЖИМ ПИТАНИЯ', mealLabel),
          _card('ИНТЕРВАЛЬНОЕ ГОЛОДАНИЕ', p.fastingState ?? 'Не практикует'),
          Container(
            margin: const EdgeInsets.only(bottom: 12), width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('РЕЖИМ СНА', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _row('Ложусь', p.bedtime ?? '—'),
              _row('Встаю', p.wakeupTime ?? '—'),
              if (p.sleepDurationHours != null)
                _row('Длительность', '${p.sleepDurationHours!.toStringAsFixed(1)} ч'),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── U-9: Активность ─────────────────────────────────────────────

class U9ActivityScreen extends ConsumerWidget {
  const U9ActivityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);

    final levelLabel = switch (p.activityLevel) {
      'none' => 'Не готов(а) сейчас',
      '1' => '1 раз в неделю',
      '2' => '2 раза в неделю',
      '3' => '3 раза в неделю',
      '4+' => '4 и более раз',
      _ => p.activityLevel ?? '—',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Активность'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('ЧАСТОТА', levelLabel),
          if (p.activityDuration != null)
            _card('ДЛИТЕЛЬНОСТЬ', p.activityDuration!),
          if (p.activityTypes?.isNotEmpty == true)
            _card('ТИП АКТИВНОСТИ', p.activityTypes!.join(', ')),
        ]),
      ),
    );
  }
}

// ── U-10: Бюджет и готовка ──────────────────────────────────────

class U10BudgetScreen extends ConsumerWidget {
  const U10BudgetScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);

    final budgetLabel = switch (p.budgetLevel) {
      'economy' => 'Экономный (до 3 000 ₽/нед)',
      'medium' => 'Средний (3 000–7 000 ₽/нед)',
      'comfort' => 'Комфортный (7 000–12 000 ₽/нед)',
      'unlimited' => 'Не ограничен',
      _ => p.budgetLevel ?? '—',
    };

    final cookLabel = switch (p.cookingTime) {
      '15-20' => '15–20 мин',
      '30-45' => '30–45 мин',
      '60' => 'До часа',
      'any' => 'Не важно',
      _ => p.cookingTime ?? '—',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Бюджет и готовка'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('БЮДЖЕТ НА ПИТАНИЕ', budgetLabel),
          _card('ВРЕМЯ НА ГОТОВКУ', cookLabel),
        ]),
      ),
    );
  }
}

// ── U-11: Напоминания ───────────────────────────────────────────

class U11NotificationsScreen extends ConsumerStatefulWidget {
  const U11NotificationsScreen({super.key});
  @override
  ConsumerState<U11NotificationsScreen> createState() => _U11State();
}

class _U11State extends ConsumerState<U11NotificationsScreen> {
  late bool _meals, _water, _vitamins, _meds, _workouts, _weeklyReport;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _meals = p.notifMeals;
    _water = p.notifWater;
    _vitamins = p.notifVitamins;
    _meds = p.notifMedications;
    _workouts = p.notifWorkouts;
    _weeklyReport = p.notifWeeklyReport;
  }

  Future<void> _save() async {
    await ref.read(profileNotifierProvider.notifier).saveFields({
      'notif_meals': _meals,
      'notif_water': _water,
      'notif_vitamins': _vitamins,
      'notif_medications': _meds,
      'notif_workouts': _workouts,
      'notif_weekly_report': _weeklyReport,
    });
    setState(() => _dirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напоминания сохранены'), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Напоминания'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _toggle('Приёмы пищи', _meals, (v) => setState(() { _meals = v; _dirty = true; })),
          _toggle('Вода', _water, (v) => setState(() { _water = v; _dirty = true; })),
          _toggle('Витамины', _vitamins, (v) => setState(() { _vitamins = v; _dirty = true; })),
          _toggle('Лекарства', _meds, (v) => setState(() { _meds = v; _dirty = true; })),
          _toggle('Тренировки', _workouts, (v) => setState(() { _workouts = v; _dirty = true; })),
          _toggle('Еженедельный отчёт', _weeklyReport, (v) => setState(() { _weeklyReport = v; _dirty = true; })),
          const SizedBox(height: 20),
          if (_dirty) SizedBox(
            width: double.infinity, height: 52,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Сохранить изменения',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
        fontWeight: FontWeight.w500))),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ]),
  );
}

// ── U-13: Цветовая схема ────────────────────────────────────────

class U13ThemeScreen extends ConsumerStatefulWidget {
  const U13ThemeScreen({super.key});
  @override
  ConsumerState<U13ThemeScreen> createState() => _U13ThemeScreenState();
}

class _U13ThemeScreenState extends ConsumerState<U13ThemeScreen> {
  late int _selected;
  // (name, color, themeKey, minTier: null=free, 'black', 'gold')
  static const _themes = [
    ('Светлая', Color(0xFFFAFAFA), 'default', null),
    ('Тёмная', Color(0xFF1A1A1A), 'dark', null),
    ('Океан', Color(0xFF0369A1), 'ocean', 'black'),
    ('Закат', Color(0xFFE11D48), 'sunset', 'black'),
    ('Лес', Color(0xFF166534), 'forest', 'black'),
    ('Gold Status', Color(0xFFB45309), 'gold', 'gold'),
    ('Сезонная', Color(0xFF7C3AED), 'seasonal', 'gold'),
  ];

  @override
  void initState() {
    super.initState();
    final saved = ref.read(profileProvider).selectedTheme;
    _selected = _themes.indexWhere((t) => t.$3 == saved);
    if (_selected < 0) _selected = 0;
  }

  bool _canSelect(String? minTier) {
    if (minTier == null) return true;
    final status = ref.read(profileProvider).subscriptionStatus ?? 'white';
    const rank = {'white': 0, 'black': 1, 'gold': 2, 'family_gold': 3};
    final userRank = rank[status] ?? 0;
    final reqRank = minTier == 'gold' ? 2 : 1;
    return userRank >= reqRank;
  }

  Future<void> _select(int i) async {
    final (_, _, key, _) = _themes[i];
    setState(() => _selected = i);
    await ref.read(profileNotifierProvider.notifier).saveField('selected_theme', key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тема применена'), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Цветовая схема'),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        itemCount: _themes.length,
        itemBuilder: (_, i) {
          final (name, color, _, minTier) = _themes[i];
          final isSelected = _selected == i;
          final canUse = _canSelect(minTier);
          final tierLabel = minTier == 'gold' ? 'Gold+' : 'Black+';
          return GestureDetector(
            onTap: canUse ? () => _select(i) : () {
              final tier = minTier == 'gold' ? RequiredTier.gold : RequiredTier.black;
              showLockedSnackbar(context, tier);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1),
              ),
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                  fontWeight: FontWeight.w600, color: canUse ? null : AppColors.textDisabled))),
                if (!canUse)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(tierLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                        fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ]),
                  )
                else if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── U-14: Health Connect ────────────────────────────────────────

class U14HealthConnectScreen extends ConsumerStatefulWidget {
  const U14HealthConnectScreen({super.key});
  @override
  ConsumerState<U14HealthConnectScreen> createState() => _U14State();
}

class _U14State extends ConsumerState<U14HealthConnectScreen> {
  late bool _sleep, _steps, _workouts, _weight;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _sleep = p.hcSleep;
    _steps = p.hcSteps;
    _workouts = p.hcWorkouts;
    _weight = p.hcWeight;
  }

  Future<void> _save() async {
    await ref.read(profileNotifierProvider.notifier).saveFields({
      'hc_sleep': _sleep, 'hc_steps': _steps,
      'hc_workouts': _workouts, 'hc_weight': _weight,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены'), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Health Connect'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF4CAF50))),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Apple Health', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Настройте синхронизацию', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                    color: AppColors.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 16),
              _hcToggle('Сон', _sleep, (v) => setState(() => _sleep = v)),
              _hcToggle('Шаги', _steps, (v) => setState(() => _steps = v)),
              _hcToggle('Тренировки', _workouts, (v) => setState(() => _workouts = v)),
              _hcToggle('Вес', _weight, (v) => setState(() => _weight = v)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white, shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Сохранить настройки', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _hcToggle(String title, bool value, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15))),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF4CAF50)),
    ]),
  );
}

// ── U-15: Мотивация и барьеры ───────────────────────────────────

class U15MotivationScreen extends ConsumerWidget {
  const U15MotivationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);

    final barrierLabels = <String, String>{
      'no_time': 'Нет времени на готовку',
      'sweets_cravings': 'Срывы на сладкое/вредное',
      'irregular_schedule': 'Нерегулярный график',
      'social_eating': 'Еда за компанию',
      'stress_eating': 'Стресс и эмоциональное переедание',
      'lazy_cooking': 'Лень готовить',
      'no_results': 'Не вижу результат',
      'too_expensive': 'Слишком дорого',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context, 'Мотивация и барьеры'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _card('ТВОИ БАРЬЕРЫ', p.motivationBarriers?.isNotEmpty == true
            ? p.motivationBarriers!.map((b) => barrierLabels[b] ?? b).join('\n• ')
            : 'Не указаны'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'Мы адаптируем уведомления и советы под твои реальные сложности',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
