// lib/features/plan/presentation/plan_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';
import 'package:ejeweeka_app/features/plan/providers/plan_provider.dart';

class PlanBuilderScreen extends ConsumerStatefulWidget {
  final MealPlan rawPlan;

  const PlanBuilderScreen({super.key, required this.rawPlan});

  @override
  ConsumerState<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends ConsumerState<PlanBuilderScreen> {
  // Map of "dayNumber_mealType" -> selected index in the variants list
  final Map<String, int> _selections = {};

  @override
  void initState() {
    super.initState();
    // Initialize default selections (index 0) for each day and meal type
    for (final day in widget.rawPlan.days) {
      final types = <String>{};
      for (final meal in day.meals) {
        types.add(meal.mealType);
      }
      for (final t in types) {
        _selections['${day.dayNumber}_$t'] = 0;
      }
    }
  }

  void _confirmPlan() {
    // Reconstruct MealPlan with only selected variants
    final finalDays = <DayPlan>[];
    for (final day in widget.rawPlan.days) {
      final finalMeals = <MealItem>[];
      final Map<String, List<MealItem>> groupedMeals = {};
      
      for (final meal in day.meals) {
        groupedMeals.putIfAbsent(meal.mealType, () => []).add(meal);
      }

      for (final entry in groupedMeals.entries) {
        final mealType = entry.key;
        final variants = entry.value;
        final selectedIdx = _selections['${day.dayNumber}_$mealType'] ?? 0;
        finalMeals.add(variants[selectedIdx.clamp(0, variants.length - 1)]);
      }

      finalDays.add(DayPlan(
        dayNumber: day.dayNumber,
        meals: finalMeals,
        workout: day.workout,
      ));
    }

    final finalPlan = MealPlan(
      generatedAt: widget.rawPlan.generatedAt,
      targetKcal: widget.rawPlan.targetKcal,
      bmr: widget.rawPlan.bmr,
      tdee: widget.rawPlan.tdee,
      daysGenerated: widget.rawPlan.daysGenerated,
      mealsPerDay: widget.rawPlan.mealsPerDay,
      modelUsed: widget.rawPlan.modelUsed,
      days: finalDays,
      allergenWarnings: widget.rawPlan.allergenWarnings,
      estimatedCost: widget.rawPlan.estimatedCost,
    );

    ref.read(planNotifierProvider.notifier).confirmPlan(finalPlan);
    context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Сборка плана',
            style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: widget.rawPlan.days.length,
              itemBuilder: (context, i) {
                final day = widget.rawPlan.days[i];
                return _buildDayBlock(day);
              },
            ),
          ),
          // CTA Bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _confirmPlan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Подтвердить и собрать корзину',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBlock(DayPlan day) {
    // Group variants by mealType
    final Map<String, List<MealItem>> groupedMeals = {};
    for (final m in day.meals) {
      groupedMeals.putIfAbsent(m.mealType, () => []).add(m);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('День ${day.dayNumber}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...groupedMeals.entries.map((e) => _buildMealVariantsSelector(day.dayNumber, e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildMealVariantsSelector(int dayNumber, String mealType, List<MealItem> variants) {
    final selectionKey = '${dayNumber}_$mealType';
    final selectedIdx = _selections[selectionKey] ?? 0;
    
    final label = switch (mealType) {
      'breakfast' => 'Завтрак',
      'lunch' => 'Обед',
      'dinner' => 'Ужин',
      _ => 'Перекус',
    };

    if (variants.length == 1) {
      // White tier (no choices)
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(variants[0].name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
      );
    }

    // Black / Gold tier (carousel of choices)
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Вариант ${selectedIdx + 1} из ${variants.length}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 156,
            child: PageView.builder(
              itemCount: variants.length,
              onPageChanged: (idx) {
                setState(() => _selections[selectionKey] = idx);
              },
              itemBuilder: (context, idx) {
                final v = variants[idx];
                final isSelected = idx == selectedIdx;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10)] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tierGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(v.variantName, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tierGold)),
                      ),
                      const SizedBox(height: 8),
                      Text(v.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, height: 1.2)),
                      const Spacer(),
                      Row(
                        children: [
                          Text('${v.calories} ккал', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('Б:${v.protein} Ж:${v.fat} У:${v.carbs} Кл:${v.fiber}',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
