// lib/features/plan/presentation/meal_swap_screen.dart
// P-3: Замена блюда — альтернативные варианты
// Спека: screens-map.md §P-3
//   Блок 1 — Текущее блюдо (затемнённое)
//   Блок 2 — Альтернативы (White=1, Black=3, Gold=5)
//   Кнопка «Выбрать» → заменяет в плане, возврат к P-1

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/widgets/status_gate.dart';
import 'package:health_code/features/plan/data/meal_plan_model.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class MealSwapScreen extends ConsumerWidget {
  final MealItem currentMeal;
  final int dayIndex;
  final int mealIndex;

  const MealSwapScreen({
    super.key,
    required this.currentMeal,
    required this.dayIndex,
    required this.mealIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    // Tier-based alt count: White=1, Black=3, Gold/FamilyGold=5
    final altCount = switch (profile.subscriptionStatus) {
      'gold' || 'family_gold' => 5,
      'black' => 3,
      _ => 1,
    };

    // Generate placeholder alternatives based on current meal type
    // In production, this would call the backend /api/v1/plan/swap endpoint
    final alternatives = _generatePlaceholderAlts(altCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Заменить блюдо',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Текущее блюдо (затемнённое) ──────────────
          _currentMealCard(),
          const SizedBox(height: 20),

          // ── Блок 2: Альтернативы ────────────────────────────
          Row(children: [
            const Text('АЛЬТЕРНАТИВЫ',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 0.8)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6)),
              child: Text('$altCount вариант${altCount > 1 ? (altCount < 5 ? 'а' : 'ов') : ''}',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                  fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 12),
          ...alternatives.map((alt) => _altCard(context, alt)),

          // ── CTA banner for White users ─────────────────────
          if (!hasStatusAccess(ref, RequiredTier.black)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Больше вариантов с Black',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                    fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 4),
                Text('3 альтернативы вместо 1.\nGold — до 5 вариантов.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                    color: Colors.white70, height: 1.4)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _currentMealCard() {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(children: [
          // Meal type emoji
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_mealEmoji(currentMeal.mealType),
              style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(currentMeal.name,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.lineThrough)),
            const SizedBox(height: 2),
            Text('${currentMeal.calories} ккал • ${currentMeal.prepTimeMin} мин',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _altCard(BuildContext context, _AltMeal alt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_mealEmoji(currentMeal.mealType),
              style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alt.name,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${alt.calories} ккал • ${alt.prepTime} мин',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 8),
        // Macro chips
        Wrap(spacing: 6, runSpacing: 4, children: [
          _macroChip('Б: ${alt.protein}г', const Color(0xFF667EEA)),
          _macroChip('Ж: ${alt.fat}г', const Color(0xFFEF4444)),
          _macroChip('У: ${alt.carbs}г', const Color(0xFF10B981)),
        ]),
        const SizedBox(height: 10),
        // Select button
        SizedBox(
          width: double.infinity, height: 40,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🔄 ${alt.name} заменяет ${currentMeal.name}'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2)));
              // TODO: actually swap in the plan via PlanNotifier.swapMeal()
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Выбрать',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _macroChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 11,
      fontWeight: FontWeight.w600, color: color)),
  );

  String _mealEmoji(String type) => switch (type) {
    'breakfast' => '🌅',
    'lunch' => '☀️',
    'dinner' => '🌙',
    _ => '🍎',
  };

  // Placeholder alternatives — in production these come from the API
  List<_AltMeal> _generatePlaceholderAlts(int count) {
    final baseKcal = currentMeal.calories;
    final alts = <_AltMeal>[
      _AltMeal('${currentMeal.name} (лайт версия)', (baseKcal * 0.85).round(), 15, 20, 8, 25),
      _AltMeal('Альтернатива 2', baseKcal, 20, 22, 10, 30),
      _AltMeal('Альтернатива 3', (baseKcal * 1.1).round(), 25, 18, 12, 28),
      _AltMeal('Альтернатива 4 (протеин)', (baseKcal * 0.95).round(), 30, 25, 6, 22),
      _AltMeal('Альтернатива 5 (быстрая)', (baseKcal * 0.9).round(), 10, 20, 10, 35),
    ];
    return alts.take(count).toList();
  }
}

class _AltMeal {
  final String name;
  final int calories;
  final int prepTime;
  final int protein;
  final int fat;
  final int carbs;

  const _AltMeal(this.name, this.calories, this.prepTime, this.protein, this.fat, this.carbs);
}
