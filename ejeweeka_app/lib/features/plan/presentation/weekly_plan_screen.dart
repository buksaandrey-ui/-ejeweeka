// lib/features/plan/presentation/weekly_plan_screen.dart
// P-1: Недельный план — список дней с карточками блюд
// Данные берутся из planNotifierProvider (MealPlan)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';
import 'package:ejeweeka_app/features/plan/presentation/meal_detail_screen.dart';
import 'package:ejeweeka_app/features/plan/presentation/meal_swap_screen.dart';
import 'package:ejeweeka_app/features/plan/providers/plan_provider.dart';
import 'package:ejeweeka_app/features/workout/presentation/workout_detail_screen.dart';

class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  ConsumerState<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends ConsumerState<WeeklyPlanScreen> {
  int _selectedDay = 0; // index in days list

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _dayNamesFull = [
    'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'
  ];

  @override
  void initState() {
    super.initState();
    // Select today
    _selectedDay = (DateTime.now().weekday - 1).clamp(0, 6);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planNotifierProvider.notifier).loadCached();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planNotifierProvider);

    MealPlan? plan;
    if (planState is PlanLoaded) plan = planState.plan;
    if (planState is PlanOffline) plan = (planState).plan;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('План питания',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800)),
                  if (plan != null)
                    Text('${plan.targetKcal} ккал/день • ${plan.daysGenerated} дней',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                        color: AppColors.textSecondary)),
                ])),
                // Refresh button
                IconButton(
                  onPressed: () => ref.read(planNotifierProvider.notifier).generate(),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Day selector ───────────────────────────────────────
            if (plan != null) _daySelector(plan),
            const SizedBox(height: 12),

            // ── Content ────────────────────────────────────────────
            Expanded(child: _buildContent(planState, plan)),
          ],
        ),
      ),
    );
  }

  Widget _daySelector(MealPlan plan) {
    return SizedBox(
      height: 68,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: plan.days.length,
        itemBuilder: (_, i) {
          final day = plan.days[i];
          final isSelected = _selectedDay == i;
          final isToday = (DateTime.now().weekday - 1) == i;

          // Spec B2: White sees only today + next day
          final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
          final isLocked = !hasStatusAccess(ref, RequiredTier.black)
              && i != todayIdx && i != (todayIdx + 1) % 7;

          return GestureDetector(
            onTap: () {
              if (isLocked) {
                showLockedSnackbar(context, RequiredTier.black);
                return;
              }
              setState(() => _selectedDay = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary
                      : isToday ? AppColors.primary.withValues(alpha: 0.4)
                      : const Color(0xFFE5E7EB),
                  width: isToday && !isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10, offset: const Offset(0, 4),
                )] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_dayNames[i % 7],
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('${day.totalCalories}',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textPrimary)),
                Text('ккал',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 9,
                    color: isSelected ? Colors.white70 : AppColors.textSecondary)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(PlanState planState, MealPlan? plan) {
    if (planState is PlanLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (planState is PlanFailed) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text((planState).message, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        SizedBox(width: 220, child: FilledButton.icon(
          onPressed: () => ref.read(planNotifierProvider.notifier).generate(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Сгенерировать план'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        )),
      ]));
    }

    if (plan == null) {
      return _emptyState();
    }

    if (planState is PlanIdle) return _emptyState();

    final dayIndex = _selectedDay.clamp(0, plan.days.length - 1);
    final day = plan.days[dayIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Day header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(_dayNamesFull[dayIndex % 7],
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
            const Spacer(),
            Text('${day.totalCalories} ккал',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800,
                color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 14),

        // Macro summary
        _macroBar(day),
        const SizedBox(height: 14),

        // Meals
        ...day.meals.asMap().entries.map((entry) => _mealCard(entry.value, entry.key)),

        // Тренировка дня
        if (day.workout != null) ...[
          const SizedBox(height: 14),
          _workoutCard(day.workout!),
        ],

        // ── Блок 3: Витаминный блок (spec P-1, screens-map.md:839-841) ──
        const SizedBox(height: 14),
        _vitaminBlock(),
      ],
    );
  }

  Widget _workoutCard(Map<String, dynamic> workout) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workout: workout),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937), // Dark premium card
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(workout['target_goal'] ?? 'Тренировка', style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
                const Spacer(),
                Text('~ ${workout['estimated_minutes'] ?? 45} мин',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(workout['title'] ?? 'Комплексная тренировка',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Группа: ${workout['muscle_group'] ?? 'Всё тело'} • Уровень: ${workout['difficulty'] ?? 'Новичок'}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white60)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitaminBlock() {
    final isLocked = !hasStatusAccess(ref, RequiredTier.black);
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          showLockedSnackbar(context, RequiredTier.black);
          return;
        }
        context.push(Routes.vitamins);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF3F4F6) : const Color(0xFFF0FFF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLocked ? const Color(0xFFD1D5DB) : const Color(0xFF86EFAC)),
        ),
        child: Row(children: [
          Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.medication_outlined,
            color: isLocked ? AppColors.textSecondary : const Color(0xFF10B981),
            size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            isLocked ? 'Витамины на сегодня (Black+)' : 'Витамины на сегодня',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
              color: isLocked ? AppColors.textSecondary : const Color(0xFF10B981)))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14,
            color: isLocked ? AppColors.textSecondary : const Color(0xFF10B981)),
        ]),
      ),
    );
  }

  Widget _macroBar(DayPlan day) {
    double p = 0, f = 0, c = 0, fb = 0;
    for (final m in day.meals) { p += m.protein; f += m.fat; c += m.carbs; fb += m.fiber; }
    final total = p + f + c + fb;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Row(children: [
          _macroLabel('Белки', p, const Color(0xFF4CAF50)),
          _macroLabel('Жиры', f, const Color(0xFFFFC107)),
          _macroLabel('Углеводы', c, const Color(0xFF42A5F5)),
          _macroLabel('Клетчатка', fb, const Color(0xFF8D6E63)),
        ]),
        const SizedBox(height: 10),
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(height: 8, child: Row(children: [
            Flexible(flex: (p / total * 100).round(), child: Container(color: const Color(0xFF4CAF50))),
            Flexible(flex: (f / total * 100).round(), child: Container(color: const Color(0xFFFFC107))),
            Flexible(flex: (c / total * 100).round(), child: Container(color: const Color(0xFF42A5F5))),
            Flexible(flex: (fb / total * 100).round().clamp(1, 100), child: Container(color: const Color(0xFF8D6E63))),
          ])),
        ),
      ]),
    );
  }

  Widget _macroLabel(String label, double value, Color color) => Expanded(
    child: Column(children: [
      Text('${value.toStringAsFixed(0)}г',
        style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );

  Widget _mealCard(MealItem meal, int mealIndex) {
    final (emoji, label) = switch (meal.mealType) {
      'breakfast' => ('🌅', 'Завтрак'),
      'lunch'     => ('☀️', 'Обед'),
      'dinner'    => ('🌙', 'Ужин'),
      _           => ('🍎', 'Перекус'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: type label + kcal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              ),
              const Spacer(),
              Text('${meal.calories} ккал',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('• ${meal.prepTimeMin} мин',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          // Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Text(meal.name,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
          ),
          // Macros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(meal.macroSummary,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ),
          // Wellness rationale (if any)
          if (meal.wellnessRationale.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(meal.wellnessRationale,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                      color: Color(0xFF2E7D32), height: 1.4))),
                ]),
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              _actionBtn(Icons.check_circle_outline_rounded, 'Съел', const Color(0xFF4CAF50), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${meal.name} — отмечено!'),
                    backgroundColor: const Color(0xFF4CAF50),
                    duration: const Duration(seconds: 2)));
              }),
              const SizedBox(width: 8),
              _actionBtn(Icons.swap_horiz_rounded, 'Заменить', AppColors.textSecondary, () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MealSwapScreen(
                    currentMeal: meal,
                    dayIndex: _selectedDay,
                    mealIndex: mealIndex,
                  )));
              }),
              const SizedBox(width: 8),
              _actionBtn(Icons.menu_book_rounded, 'Рецепт', AppColors.primary, () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MealDetailScreen(meal: meal)));
              }),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.restaurant_menu_outlined, size: 56, color: AppColors.textSecondary),
    const SizedBox(height: 16),
    const Text('Нет плана питания', style: TextStyle(fontFamily: 'Inter', fontSize: 18,
      fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Завершите онбординг или нажмите\n«Сгенерировать» на дашборде',
      textAlign: TextAlign.center,
      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
    const SizedBox(height: 24),
    SizedBox(width: 200, child: FilledButton.icon(
      onPressed: () => ref.read(planNotifierProvider.notifier).generate(),
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('Создать план'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
    )),
  ]));
}
