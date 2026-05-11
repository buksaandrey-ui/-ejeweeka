// lib/features/dashboard/presentation/dashboard_screen.dart
// H-1: Dashboard — главный экран приложения
// - CalorieRing (круговой прогресс ккал)
// - MacroBars (Б/Ж/У)
// - NextMealCard — ближайший приём пищи
// - OfflineBanner (если нет плана или план от кеша)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';
import 'package:ejeweeka_app/features/dashboard/data/drink_log_model.dart';
import 'package:ejeweeka_app/features/dashboard/data/eaten_meal_log.dart';
import 'package:ejeweeka_app/features/dashboard/data/snack_log_model.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';
import 'package:ejeweeka_app/features/plan/providers/plan_provider.dart';
import 'package:ejeweeka_app/shared/utils/enum_translator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedDay = 0;
  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  // ── Drink/Snack/Eaten log state (persisted) ───────────────
  List<SnackLog> _snackLogs = [];
  List<DrinkLog> _drinkLogs = [];
  List<EatenMealEntry> _eatenMeals = [];
  static const _snackKey = 'hc_snack_logs';
  static const _drinkKey = 'hc_drink_logs';
  static const _eatenKey = 'hc_eaten_meals';

  @override
  void initState() {
    super.initState();
    _selectedDay = (DateTime.now().weekday - 1).clamp(0, 6);
    _loadExtraLogs();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(planNotifierProvider.notifier);
      await notifier.loadCached();
      // BUG-05: Auto-generate on first launch if no cached plan
      final state = ref.read(planNotifierProvider);
      if (state is PlanIdle) {
        final profile = ref.read(profileProvider);
        if (profile.onboardingComplete) {
          notifier.generate();
        }
      }
    });
  }

  Future<void> _loadExtraLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    // Snacks
    final sRaw = prefs.getString('${_snackKey}_$today');
    if (sRaw != null) {
      try {
        final list = jsonDecode(sRaw) as List;
        _snackLogs = list.map((e) => SnackLog.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    // Drinks
    final dRaw = prefs.getString('${_drinkKey}_$today');
    if (dRaw != null) {
      try {
        final list = jsonDecode(dRaw) as List;
        _drinkLogs = list.map((e) => DrinkLog.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    // Eaten meals
    final eRaw = prefs.getString('${_eatenKey}_$today');
    if (eRaw != null) {
      try {
        _eatenMeals = EatenMealEntry.decodeList(eRaw);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _persistSnacks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_snackKey}_${_todayKey()}',
        jsonEncode(_snackLogs.map((s) => s.toJson()).toList()));
  }

  Future<void> _persistDrinks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_drinkKey}_${_todayKey()}',
        jsonEncode(_drinkLogs.map((d) => d.toJson()).toList()));
  }

  Future<void> _persistEaten() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_eatenKey}_${_todayKey()}',
        EatenMealEntry.encodeList(_eatenMeals));
  }

  void _markMealEaten(String mealType, String name, int kcal,
      double protein, double fat, double carbs, double fiber) {
    _eatenMeals.add(EatenMealEntry(
      mealType: mealType, name: name, calories: kcal,
      protein: protein, fat: fat, carbs: carbs, fiber: fiber,
      timestamp: DateTime.now(),
    ));
    _persistEaten();
    setState(() {});
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Total consumed kcal/macros: eaten meals + snacks + drinks
  double get _totalConsumedKcal {
    double s = 0;
    for (final e in _eatenMeals) s += e.calories;
    for (final l in _snackLogs) s += l.calories;
    for (final l in _drinkLogs) s += l.estimatedKcal;
    return s;
  }
  double get _totalProtein {
    return _eatenMeals.fold(0.0, (a, e) => a + e.protein)
         + _snackLogs.fold(0.0, (a, s) => a + s.protein);
  }
  double get _totalFat {
    return _eatenMeals.fold(0.0, (a, e) => a + e.fat)
         + _snackLogs.fold(0.0, (a, s) => a + s.fat);
  }
  double get _totalCarbs {
    return _eatenMeals.fold(0.0, (a, e) => a + e.carbs)
         + _snackLogs.fold(0.0, (a, s) => a + s.carbs);
  }
  double get _totalFiber {
    return _eatenMeals.fold(0.0, (a, e) => a + e.fiber)
         + _snackLogs.fold(0.0, (a, s) => a + s.fiber);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlanState>(planNotifierProvider, (previous, next) {
      if (next is PlanAwaitingReview) {
        context.push(Routes.planBuilder, extra: next.rawPlan);
      }
    });

    final profile = ref.watch(profileProvider);
    final planState = ref.watch(planNotifierProvider);
    final name = profile.name ?? 'Привет';
    final greeting = _greeting();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(planNotifierProvider.notifier).generate(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting $name',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 22,
                        fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(_todayFormatted(),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                        color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ])),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                    tooltip: 'Уведомления',
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Week day selector ────────────────────────────────
                _buildWeekSelector(),
                const SizedBox(height: 16),

                // ── Plan state banners ───────────────────────────────
                if (planState is PlanLoading) _loadingBanner(),
                if (planState is PlanFailed) _errorBanner((planState).message),
                if (planState is PlanOffline) _offlineBanner(),

                // ── Calorie ring ─────────────────────────────────────
                _buildCalorieSection(planState, profile.targetDailyCalories),
                const SizedBox(height: 16),

                // ── Today's meals ─────────────────────────────────────
                _buildTodayMeals(planState),
                const SizedBox(height: 16),

                // ── Quick stats ──────────────────────────────────────
                _buildQuickStats(profile),
                const SizedBox(height: 16),

                // ── Quick actions ──────────────────────────────────────────
                _buildQuickActions(),
                const SizedBox(height: 16),

                // ── Bloc 5: Upsell banner (White post-trial) ────────
                _buildUpsellBanner(profile),

                // ── Generate plan CTA (if no plan) ──────────────────
                if (planState is PlanIdle || planState is PlanFailed)
                  _generatePlanCta(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Calorie section
  // ──────────────────────────────────────────────────────────────

  Widget _buildCalorieSection(PlanState planState, double? targetKcal) {
    MealPlan? plan;
    if (planState is PlanLoaded) plan = planState.plan;
    if (planState is PlanOffline) plan = (planState).plan;

    final target = plan?.targetKcal.toDouble() ?? targetKcal ?? 0;
    // F1 fix: CalorieRing shows ONLY actually consumed food
    final consumed = _totalConsumedKcal;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    // Macros from eaten meals + snacks (not full plan!)
    final protein = _totalProtein;
    final fat = _totalFat;
    final carbs = _totalCarbs;
    final fiber = _totalFiber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(children: [
          // Calorie ring
          Semantics(
            label: 'Прогресс калорий: съедено ${consumed.toStringAsFixed(0)} из ${target.toStringAsFixed(0)}',
            value: '${(progress * 100).toStringAsFixed(0)} процентов',
            child: SizedBox(width: 100, height: 100, child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: progress, strokeWidth: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                strokeCap: StrokeCap.round,
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(target > 0 ? target.toStringAsFixed(0) : '—',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 20,
                    fontWeight: FontWeight.w800, color: Colors.white)),
                const Text('ккал/день', style: TextStyle(fontFamily: 'Inter',
                  fontSize: 9, color: Colors.white70)),
              ]),
            ],
          ))),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Сегодня',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
            Text(plan?.today != null ? '${plan!.today!.meals.length} приёма запланировано'
                : 'Загрузка плана...',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            // Калорийность
            if (plan != null) ...[
              _whiteStatRow('Базовый обмен', '${plan.bmr} ккал'),
              const SizedBox(height: 2),
              _whiteStatRow('С активностью', '${plan.tdee} ккал'),
            ],
          ])),
        ]),
        const SizedBox(height: 16),
        // Macro bars
        Row(children: [
          _macroPill('Белки', protein, 'Б', const Color(0xFF4CAF50)),
          const SizedBox(width: 6),
          _macroPill('Жиры', fat, 'Ж', const Color(0xFFFFC107)),
          const SizedBox(width: 6),
          _macroPill('Углеводы', carbs, 'У', const Color(0xFF42A5F5)),
          const SizedBox(width: 6),
          _macroPill('Клетчатка', fiber, 'Кл', const Color(0xFF8D6E63)),
        ]),
      ]),
    );
  }

  Widget _whiteStatRow(String label, String value) => Row(children: [
    Text('$label: ', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white60)),
    Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
      fontWeight: FontWeight.w700, color: Colors.white)),
  ]);

  Widget _macroPill(String label, double value, String letter, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(letter, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white70)),
        ]),
        const SizedBox(height: 4),
        Text(value > 0 ? '${value.toStringAsFixed(0)}г' : '—',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white60)),
      ]),
    ),
  );

  // ──────────────────────────────────────────────────────────────
  // Today's meals
  // ──────────────────────────────────────────────────────────────

  Widget _buildTodayMeals(PlanState planState) {
    MealPlan? plan;
    if (planState is PlanLoaded) plan = planState.plan;
    if (planState is PlanOffline) plan = (planState).plan;

    final today = plan?.today;
    if (today == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Приёмы пищи сегодня',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SizedBox(
          height: 120, // Fixed height for horizontal meal cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: today.meals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _mealCard(today.meals[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _mealCard(MealItem meal, int index) {
    final (emoji, timeLabel) = switch (meal.mealType) {
      'breakfast' => ('🌅', '07:00 – 09:00'),
      'lunch'     => ('☀️', '12:00 – 14:00'),
      'dinner'    => ('🌙', '18:00 – 20:00'),
      'snack'     => ('🍎', '15:00 – 16:00'),
      _           => ('🍽️', ''),
    };

    // Check if this meal was already eaten
    final isEaten = _eatenMeals.any((e) => e.name == meal.name && e.mealType == meal.mealType);

    return Container(
      width: 300, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.only(bottom: 4), // Small bottom margin for shadow
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEaten ? const Color(0xFFF0FFF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEaten ? const Color(0xFF10B981) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isEaten
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: isEaten
              ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 24)
              : Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meal.name,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
              decoration: isEaten ? TextDecoration.lineThrough : null,
              color: isEaten ? AppColors.textSecondary : null),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${meal.calories} ккал • $timeLabel',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(meal.macroSummary,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
        ])),
        // «Съел ✅» button (spec P-1 Блок 2)
        if (!isEaten)
          SizedBox(width: 36, height: 36, child: IconButton(
            onPressed: () {
              _markMealEaten(meal.mealType, meal.name, meal.calories,
                  meal.protein, meal.fat, meal.carbs, meal.fiber);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${meal.name} — ${meal.calories} ккал'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2)));
            },
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
            tooltip: 'Съел',
          ))
        else
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Quick stats
  // ──────────────────────────────────────────────────────────────

  Widget _buildQuickStats(profile) {
    return Row(children: [
      _statCard(Icons.monitor_weight_outlined, const Color(0xFF667EEA), 'Текущий вес',
        profile.weight != null ? '${profile.weight!.toStringAsFixed(1)} кг' : '—'),
      const SizedBox(width: 10),
      _statCard(Icons.flag_outlined, const Color(0xFF4CAF50), 'Цель',
        profile.targetWeight != null ? '${profile.targetWeight!.toStringAsFixed(1)} кг' : EnumTranslator.goal(profile.goal)),
      const SizedBox(width: 10),
      _statCard(Icons.analytics_outlined, const Color(0xFFFF9800), 'ИМТ',
        profile.bmi != null ? profile.bmi!.toStringAsFixed(1) : '—'),
    ]);
  }

  Widget _statCard(IconData iconData, Color iconColor, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        Icon(iconData, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
          color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    ),
  );

  // ──────────────────────────────────────────────────────────────
  // Quick actions
  // ──────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Быстрые действия',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        // Quick action circles — scrollable 6 items (Drinks and Snacks prioritized)
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _quickCircle(Icons.local_cafe_outlined, 'Напиток', const Color(0xFF00897B),
                () {
                  if (!hasStatusAccess(ref, RequiredTier.black)) {
                    showLockedSnackbar(context, RequiredTier.black); return;
                  }
                  _showDrinkSheet();
                }),
              const SizedBox(width: 14),
              _quickCircle(Icons.restaurant_outlined, 'Перекус', const Color(0xFFE65100),
                () => _showSnackSheet()),
              const SizedBox(width: 14),
              _quickCircle(Icons.monitor_weight_outlined, 'Вес', const Color(0xFF667EEA),
                () => _showWeightInput()),
              const SizedBox(width: 14),
              _quickCircle(Icons.medication_outlined, 'Витамины', const Color(0xFFFF9800), () {
                if (!hasStatusAccess(ref, RequiredTier.black)) {
                  showLockedSnackbar(context, RequiredTier.black); return;
                }
                context.push(Routes.vitamins);
              }),
              const SizedBox(width: 14),
              _quickCircle(Icons.camera_alt_outlined, 'Фото', const Color(0xFF9C27B0), () {
                if (!hasStatusAccess(ref, RequiredTier.gold)) {
                  showLockedSnackbar(context, RequiredTier.gold); return;
                }
                context.push(Routes.photoAnalysis);
              }),
              const SizedBox(width: 14),
              _quickCircle(Icons.fitness_center_outlined, 'Тренировка', const Color(0xFF4CAF50), () {
                if (!hasStatusAccess(ref, RequiredTier.black)) {
                  showLockedSnackbar(context, RequiredTier.black); return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Тренировки — скоро'), duration: Duration(seconds: 2)));
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Feature cards
        Row(children: [
          _quickActionCard(
            iconData: Icons.camera_alt_outlined,
            title: 'Анализ фото',
            subtitle: 'КБЖУ блюда за 5 секунд',
            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
            onTap: () {
              if (!hasStatusAccess(ref, RequiredTier.gold)) {
                showLockedSnackbar(context, RequiredTier.gold); return;
              }
              context.push(Routes.photoAnalysis);
            },
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            iconData: Icons.forum_outlined,
            title: 'HC-чат',
            subtitle: 'Спросить нутрициолога',
            gradient: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            onTap: () {
              if (!hasStatusAccess(ref, RequiredTier.gold)) {
                showLockedSnackbar(context, RequiredTier.gold); return;
              }
              context.push(Routes.aiChat);
            },
          ),
        ]),
      ],
    );
  }

  Widget _quickCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Drink Bottom Sheet
  // ──────────────────────────────────────────────────────────────

  void _showDrinkSheet() {
    String? selectedDrink;
    int selectedVolume = 250;
    bool hasAlcohol = false;
    final abvCtrl = TextEditingController();
    int estimatedKcal = 0;

    void recalc(StateSetter setSheetState) {
      if (selectedDrink != null) {
        double? customAbv = hasAlcohol ? double.tryParse(abvCtrl.text.replaceAll(',', '.')) : null;
        estimatedKcal = DrinkLog.estimateKcal(selectedDrink!, selectedVolume, customAbv: customAbv);
      }
      setSheetState(() {});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(children: [
              Icon(Icons.local_cafe_outlined, color: Color(0xFF00897B), size: 22),
              SizedBox(width: 8),
              Text('Добавить напиток', style: TextStyle(fontFamily: 'Inter',
                fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),

            // Drink selector
            const Text('Что пьёшь?', style: TextStyle(fontFamily: 'Inter',
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              'Вода', 'Чай', 'Кофе', 'Молочный напиток', 'Газировка', 'Сок', 'Алкоголь', 'Другое'
            ].map((cat) {
              final isSelected = selectedDrink?.startsWith(cat) ?? false;
              return GestureDetector(
                onTap: () {
                  selectedDrink = cat;
                  hasAlcohol = cat == 'Алкоголь';
                  recalc(setSheetState);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00897B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFF00897B) : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(cat, style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                    color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
                ),
              );
            }).toList()),
            
            // Subcategory Selection
            if (selectedDrink != null && selectedDrink != 'Вода') ...[
              const SizedBox(height: 16),
              Builder(builder: (ctx) {
                List<String> subItems = [];
                String baseCat = selectedDrink!.split(' - ').first;
                if (baseCat == 'Чай') subItems = ['Чёрный без сахара', 'Чёрный с сахаром', 'Зелёный без сахара', 'Травяной', 'Другое'];
                if (baseCat == 'Кофе') subItems = ['Эспрессо', 'Американо', 'Капучино', 'Латте', 'Кофе с молоком', 'Кофе с сахаром', 'Другое'];
                if (baseCat == 'Молочный напиток') subItems = ['Молоко 2.5%', 'Кефир 1%', 'Айран', 'Молочный коктейль', 'Другое'];
                if (baseCat == 'Газировка') subItems = ['С сахаром', 'Без сахара', 'Энергетик', 'Другое'];
                if (baseCat == 'Сок') subItems = ['Апельсиновый', 'Яблочный', 'Вишневый', 'Томатный', 'Мультифрукт', 'Гранатовый', 'Грейпфрутовый', 'Морковный', 'Персиковый', 'Свежевыжатый', 'Другое'];
                if (baseCat == 'Алкоголь') subItems = ['Пиво', 'Вино красное', 'Вино белое', 'Водка', 'Коньяк', 'Ром', 'Ликер', 'Виски', 'Другое'];
                
                if (subItems.isEmpty) return const SizedBox.shrink();
                
                return Wrap(spacing: 8, runSpacing: 8, children: subItems.map((sub) {
                  final isSelected = selectedDrink!.contains(sub) || (sub == 'Другое' && selectedDrink!.endsWith(' - Другое'));
                  return GestureDetector(
                    onTap: () {
                      selectedDrink = '$baseCat - $sub';
                      recalc(setSheetState);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE5F6F4) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF00897B) : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                        color: isSelected ? const Color(0xFF00897B) : AppColors.textPrimary)),
                    ),
                  );
                }).toList());
              }),
            ],
            
            // Text field for 'Другое' or main 'Другое'
            if (selectedDrink != null && (selectedDrink!.endsWith('Другое') || selectedDrink == 'Другое')) ...[
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Уточните напиток...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00897B))),
                ),
                onChanged: (v) {
                  // Keep state but don't force rebuild on every char
                },
                onSubmitted: (v) {
                  if (v.isNotEmpty) {
                    if (selectedDrink!.contains(' - ')) {
                      selectedDrink = '${selectedDrink!.split(' - ').first} - $v';
                    } else {
                      selectedDrink = v;
                    }
                    recalc(setSheetState);
                  }
                },
              )
            ],
            
            // ABV input for Alcohol
            if (hasAlcohol) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Крепость (градусы):', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: abvCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => recalc(setSheetState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('%', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                ]
              )
            ],
            
            const SizedBox(height: 16),

            // Volume selector
            const Text('Объём', style: TextStyle(fontFamily: 'Inter',
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [150, 250, 350, 500].map((v) {
              final isSelected = selectedVolume == v;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { selectedVolume = v; recalc(setSheetState); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00897B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF00897B) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text('${v}мл', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary)),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 12),

            // Alcohol checkbox
            Row(children: [
              SizedBox(width: 24, height: 24, child: Checkbox(
                value: hasAlcohol, activeColor: const Color(0xFF00897B),
                onChanged: (v) => setSheetState(() => hasAlcohol = v ?? false),
              )),
              const SizedBox(width: 8),
              const Text('Содержит алкоголь', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
              if (hasAlcohol) ...[
                const SizedBox(width: 12),
                SizedBox(width: 60, child: TextField(
                  controller: abvCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                  onChanged: (v) => recalc(setSheetState),
                  decoration: InputDecoration(
                    suffixText: '%', isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )),
              ],
            ]),
            const SizedBox(height: 12),

            // Estimated kcal
            if (selectedDrink != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.local_fire_department_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('~$estimatedKcal ккал', style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            const SizedBox(height: 16),

            // Submit
            SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(
              onPressed: selectedDrink == null ? null : () {
                final log = DrinkLog(
                  name: selectedDrink!,
                  volumeMl: selectedVolume,
                  estimatedKcal: estimatedKcal,
                  abv: hasAlcohol ? double.tryParse(abvCtrl.text) : null,
                  timestamp: DateTime.now(),
                );
                _drinkLogs.add(log);
                _persistDrinks();
                Navigator.pop(ctx);
                setState(() {}); // update calorie ring
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🥤 $selectedDrink ${selectedVolume}мл — $estimatedKcal ккал'),
                  backgroundColor: const Color(0xFF00897B),
                  duration: const Duration(seconds: 2)));
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Добавить', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          ]),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Snack Bottom Sheet
  // ──────────────────────────────────────────────────────────────

  void _showSnackSheet() {
    String? selectedSnack;
    double selectedPortion = 100;
    int kcal = 0;
    String macros = '';

    bool isCustom = false;
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    final fCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final fibCtrl = TextEditingController();

    void recalc(StateSetter setSheetState) {
      if (isCustom) {
        kcal = int.tryParse(kcalCtrl.text) ?? 0;
        final p = double.tryParse(pCtrl.text) ?? 0;
        final f = double.tryParse(fCtrl.text) ?? 0;
        final c = double.tryParse(cCtrl.text) ?? 0;
        final fib = double.tryParse(fibCtrl.text) ?? 0;
        macros = 'Б ${p.toStringAsFixed(0)} · Ж ${f.toStringAsFixed(0)} · У ${c.toStringAsFixed(0)} · Кл ${fib.toStringAsFixed(0)}';
      } else if (selectedSnack != null) {
        final log = SnackLog.fromPreset(selectedSnack!, selectedPortion);
        kcal = log.calories;
        macros = log.macroSummary;
      }
      setSheetState(() {});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(children: [
              Icon(Icons.restaurant_outlined, color: Color(0xFFE65100), size: 22),
              SizedBox(width: 8),
              Text('Добавить перекус', style: TextStyle(fontFamily: 'Inter',
                fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),

            // Snack selector
            const Text('Что ел(а)?', style: TextStyle(fontFamily: 'Inter',
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ...SnackLog.presets.map((p) {
                final isSelected = !isCustom && selectedSnack == p.name;
                return GestureDetector(
                  onTap: () { isCustom = false; selectedSnack = p.name; recalc(setSheetState); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE65100) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFFE65100) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(p.name, style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }),
              GestureDetector(
                onTap: () { isCustom = true; selectedSnack = null; recalc(setSheetState); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCustom ? const Color(0xFFE65100) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isCustom ? const Color(0xFFE65100) : const Color(0xFFE5E7EB)),
                  ),
                  child: Text('Свой вариант', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                    fontWeight: isCustom ? FontWeight.w700 : FontWeight.w500,
                    color: isCustom ? Colors.white : AppColors.textPrimary)),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (!isCustom) ...[
              // Portion selector
              const Text('Размер порции', style: TextStyle(fontFamily: 'Inter',
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [50.0, 100.0, 150.0, 200.0].map((v) {
                final isSelected = selectedPortion == v;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { selectedPortion = v; recalc(setSheetState); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE65100) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFFE65100) : const Color(0xFFE5E7EB)),
                      ),
                      child: Text('${v.toInt()}г', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary)),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 8),
            ] else ...[
              const Text('Название и КБЖУ', style: TextStyle(fontFamily: 'Inter',
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название', isDense: true)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: kcalCtrl, keyboardType: TextInputType.number, onChanged: (_) => recalc(setSheetState), decoration: const InputDecoration(hintText: 'Ккал', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: pCtrl, keyboardType: TextInputType.number, onChanged: (_) => recalc(setSheetState), decoration: const InputDecoration(hintText: 'Белки', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fCtrl, keyboardType: TextInputType.number, onChanged: (_) => recalc(setSheetState), decoration: const InputDecoration(hintText: 'Жиры', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: cCtrl, keyboardType: TextInputType.number, onChanged: (_) => recalc(setSheetState), decoration: const InputDecoration(hintText: 'Угл.', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fibCtrl, keyboardType: TextInputType.number, onChanged: (_) => recalc(setSheetState), decoration: const InputDecoration(hintText: 'Клетч.', isDense: true))),
              ]),
              const SizedBox(height: 12),
            ],

            // Photo analysis shortcut
            GestureDetector(
              onTap: () { Navigator.pop(ctx); context.push(Routes.photoAnalysis); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCE93D8)),
                ),
                child: const Row(children: [
                  Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF9C27B0)),
                  SizedBox(width: 8),
                  Text('Или сфотографируй — HC посчитает за тебя', style: TextStyle(fontFamily: 'Inter',
                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9C27B0))),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // KBJU preview
            if (selectedSnack != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.local_fire_department_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('~$kcal ккал', style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Text(macros, style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
            const SizedBox(height: 16),

            // Submit
            SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(
              onPressed: (!isCustom && selectedSnack == null) || (isCustom && nameCtrl.text.isEmpty) ? null : () {
                SnackLog log;
                if (isCustom) {
                  log = SnackLog(
                    name: nameCtrl.text,
                    portionG: 100, // Custom assumes total portion
                    calories: int.tryParse(kcalCtrl.text) ?? 0,
                    protein: double.tryParse(pCtrl.text) ?? 0,
                    fat: double.tryParse(fCtrl.text) ?? 0,
                    carbs: double.tryParse(cCtrl.text) ?? 0,
                    fiber: double.tryParse(fibCtrl.text) ?? 0,
                    timestamp: DateTime.now(),
                  );
                } else {
                  log = SnackLog.fromPreset(selectedSnack!, selectedPortion);
                }
                
                _snackLogs.add(log);
                _persistSnacks();
                Navigator.pop(ctx);
                setState(() {}); // update calorie ring
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🍎 ${log.name} — ${log.calories} ккал'),
                  backgroundColor: const Color(0xFFE65100),
                  duration: const Duration(seconds: 2)));
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Добавить', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildWeekSelector() {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final isSelected = _selectedDay == i;
          final isToday = (DateTime.now().weekday - 1) == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary
                      : isToday ? AppColors.primary.withValues(alpha: 0.4)
                      : const Color(0xFFE5E7EB),
                  width: isToday && !isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3),
                )] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_dayNames[i],
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary)),
                if (isToday && !isSelected)
                  Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _quickActionCard({
    required IconData iconData,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient,
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(iconData, size: 28, color: Colors.white),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
            color: Colors.white70, height: 1.3)),
        ]),
      ),
    ),
  );

  // ──────────────────────────────────────────────────────────────
  // Banners
  // ──────────────────────────────────────────────────────────────

  Widget _loadingBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
    child: const Row(children: [
      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      SizedBox(width: 10),
      Text('Генерируем персональный план...', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
        fontWeight: FontWeight.w600, color: AppColors.primary)),
    ]),
  );

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEF9A9A))),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
        color: Color(0xFFC62828)))),
      TextButton(
        onPressed: () => ref.read(planNotifierProvider.notifier).generate(),
        child: const Text('Повторить', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary)),
      ),
    ]),
  );

  Widget _offlineBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFF9E6),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFE082))),
    child: const Row(children: [
      Icon(Icons.wifi_off_rounded, color: Color(0xFFF57F17), size: 18),
      SizedBox(width: 8),
      Expanded(child: Text('Офлайн режим — показываем сохранённый план',
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFF57F17)))),
    ]),
  );

  Widget _generatePlanCta() => GestureDetector(
    onTap: () => ref.read(planNotifierProvider.notifier).generate(),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        const Text('🚀', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        const Text('Создать персональный план', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Нажми, чтобы сгенерировать план питания на основе твоего профиля',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
      ]),
    ),
  );

  String _greeting() {
    final h = DateTime.now().hour;
    final weekday = DateTime.now().weekday;
    final profile = ref.read(profileProvider);
    final goal = profile.goal;

    // Base time greeting
    final timeGreeting = h < 12 ? 'Доброе утро,' : h < 17 ? 'Добрый день,' : h < 22 ? 'Добрый вечер,' : 'Доброй ночи,';

    // Contextual greetings — rotate based on day of week
    final contextGreetings = <String>[
      timeGreeting, // 0: default
      goal == 'lose_weight' ? 'Ты на верном пути,' : 'Отличный день,', // 1
      weekday == 1 ? 'Новая неделя —' : 'Продолжаем,', // 2
      h < 12 ? 'Энергичного утра,' : 'Продуктивного дня,', // 3
      weekday == 5 ? 'Пятница!' : weekday >= 6 ? 'Отдыхаем,' : timeGreeting, // 4
      '🔥', // 5: streak day — just emoji
    ];

    // Pick greeting based on day-of-week rotation
    final idx = weekday % contextGreetings.length;
    return contextGreetings[idx];
  }

  String _todayFormatted() {
    final now = DateTime.now();
    const months = ['января','февраля','марта','апреля','мая','июня',
      'июля','августа','сентября','октября','ноября','декабря'];
    const weekdays = ['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  // ── F4: Weight input dialog (Quick Action «Вес») ──────────────
  void _showWeightInput() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Записать вес', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(suffixText: 'кг', hintText: '70.5'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(
          onPressed: () async {
            final w = double.tryParse(ctrl.text.replaceAll(',', '.'));
            if (w != null && w > 20 && w < 300) {
              Navigator.pop(ctx);
              // Persist weight log
              final prefs = await SharedPreferences.getInstance();
              final key = 'hc_weight_log_${_todayKey()}';
              await prefs.setDouble(key, w);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Вес ${w.toStringAsFixed(1)} кг сохранён'),
                  backgroundColor: const Color(0xFF667EEA),
                  duration: const Duration(seconds: 2)));
              }
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    ));
  }

  // ── F6: Upsell banner (H-1 Блок 5, spec screens-map.md:809-812) ──
  // Shows on White status after trial ends
  Widget _buildUpsellBanner(dynamic profile) {
    final status = profile.subscriptionStatus ?? 'white';
    if (status != 'white') return const SizedBox.shrink();

    // Check trial expired
    final trialStart = profile.trialStart;
    if (trialStart != null) {
      final start = DateTime.tryParse(trialStart.toString());
      if (start != null) {
        final daysSince = DateTime.now().difference(start).inDays;
        if (daysSince < 3) return const SizedBox.shrink(); // Trial still active
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => context.push(Routes.statusScreen),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF374151)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Попробуй Black', style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: 2),
              Text('Рецепты, витамины, умные отчёты', style: TextStyle(fontFamily: 'Inter',
                fontSize: 12, color: Colors.white70)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
          ]),
        ),
      ),
    );
  }
}
