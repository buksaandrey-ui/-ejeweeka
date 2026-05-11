// lib/features/plan/presentation/meal_detail_screen.dart
// P-2: Карточка блюда — детальная информация
// screens-map.md spec:
//   Блок 1 — Фото блюда (16:10)
//   Блок 2 — Название + нутриент-чипы (kcal, Б, Ж, У, Кл) + время
//   Блок 3 — Ингредиенты (White: видно, рецепт заблокирован)
//   Блок 4 — Пошаговый рецепт (White: замок, Black+: полный)
//   Блок 5 — «Съел ✅» + «Выбрать другое» → P-3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';
import 'package:ejeweeka_app/features/plan/presentation/full_recipe_screen.dart';
import 'package:ejeweeka_app/features/plan/presentation/meal_swap_screen.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class MealDetailScreen extends ConsumerWidget {
  final MealItem meal;
  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Блок 1: Фото блюда (16:10) ───────────────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width * 10 / 16,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: _backButton(context),
            flexibleSpace: FlexibleSpaceBar(
              background: meal.imageUrl.isNotEmpty
                  ? Image.network(meal.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage())
                  : _placeholderImage(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Блок 2: Информация ─────────────────────────
                  _buildInfo(),
                  const SizedBox(height: 20),

                  // ── Блок 3: Ингредиенты ────────────────────────
                  _buildIngredients(context, ref),
                  const SizedBox(height: 20),

                  // ── Блок 4: Пошаговый рецепт ───────────────────
                  _buildRecipe(context, ref),
                  const SizedBox(height: 24),

                  // ── Блок 5: Действия ───────────────────────────
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Back button ──────────────────────────────────────────────
  Widget _backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }

  // ── Placeholder image ────────────────────────────────────────
  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.restaurant_outlined, size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(meal.name, style: const TextStyle(fontFamily: 'Inter',
            fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Блок 2: Название + нутриенты + время ─────────────────────
  Widget _buildInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Meal type badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _mealTypeColor(meal.mealType).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_mealTypeLabel(meal.mealType),
          style: TextStyle(fontFamily: 'Inter', fontSize: 11,
            fontWeight: FontWeight.w700, color: _mealTypeColor(meal.mealType))),
      ),
      const SizedBox(height: 8),

      // Name
      Text(meal.name, style: const TextStyle(fontFamily: 'Inter',
        fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
      const SizedBox(height: 12),

      // Nutrient chips — spec: kcal, белки, жиры, углеводы, клетчатка
      Wrap(spacing: 8, runSpacing: 8, children: [
        _nutrientChip('${meal.calories}', 'ккал', const Color(0xFF4C1D95)),
        _nutrientChip('${meal.protein.toStringAsFixed(0)}г', 'Белки', const Color(0xFF667EEA)),
        _nutrientChip('${meal.fat.toStringAsFixed(0)}г', 'Жиры', const Color(0xFFEF4444)),
        _nutrientChip('${meal.carbs.toStringAsFixed(0)}г', 'Углеводы', const Color(0xFF10B981)),
        _nutrientChip('${meal.fiber.toStringAsFixed(0)}г', 'Клетчатка', const Color(0xFF8D6E63)),
        if (meal.hasProbiotics)
          _nutrientChip('✓', 'Пробиотики', const Color(0xFF7C3AED)),
      ]),
      const SizedBox(height: 12),

      // Prep time + serving
      Row(children: [
        Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text('${meal.prepTimeMin} мин', style: const TextStyle(fontFamily: 'Inter',
          fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Icon(Icons.restaurant_outlined, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text('${meal.servingG}г', style: const TextStyle(fontFamily: 'Inter',
          fontSize: 13, color: AppColors.textSecondary)),
      ]),

      // Wellness rationale
      if (meal.wellnessRationale.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.medical_information_outlined, size: 16, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Expanded(child: Text(meal.wellnessRationale, style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: Color(0xFF0369A1), height: 1.4))),
          ]),
        ),
      ],
    ]);
  }

  Widget _nutrientChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 16,
          fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10,
          fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }

  // ── Блок 3: Ингредиенты ──────────────────────────────────────
  // Spec: White — видно, Black+ — полный список
  Widget _buildIngredients(BuildContext context, WidgetRef ref) {
    if (meal.ingredients.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.shopping_basket_outlined, size: 18, color: Color(0xFF6B7280)),
        SizedBox(width: 8),
        Text('Ингредиенты', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
          fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: meal.ingredients.asMap().entries.map((entry) {
            final i = entry.value;
            final name = i['name'] ?? i['ingredient'] ?? '';
            final amount = i['amount'] ?? i['quantity'] ?? '';
            final isLast = entry.key == meal.ingredients.length - 1;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name.toString(), style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500))),
                  Text(amount.toString(), style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ),
              if (!isLast) Divider(height: 1, color: const Color(0xFFF3F4F6)),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }

  // ── Блок 4: Пошаговый рецепт ─────────────────────────────────
  // Spec: White → замок + баннер «Открой рецепты с Black»
  // Black+ → полные шаги
  Widget _buildRecipe(BuildContext context, WidgetRef ref) {
    if (meal.steps.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF6B7280)),
        SizedBox(width: 8),
        Text('Рецепт', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
          fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),

      // StatusGate: Black+ only, preview mode for White
      StatusGate(
        requiredTier: RequiredTier.black,
        previewMode: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: meal.steps.asMap().entries.map((entry) {
              final stepNum = entry.key + 1;
              final step = entry.value;
              final desc = step['description'] ?? step['step'] ?? '';
              final duration = step['duration'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Step number circle
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C1D95), Color(0xFFE85D04)]),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('$stepNum', style: const TextStyle(fontFamily: 'Inter',
                      fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(desc.toString(), style: const TextStyle(fontFamily: 'Inter',
                      fontSize: 14, height: 1.5)),
                    if (duration != null && duration.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF4C1D95)),
                            const SizedBox(width: 4),
                            Text(duration.toString(), style: const TextStyle(fontFamily: 'Inter',
                              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95))),
                          ]),
                        ),
                      ),
                  ])),
                ]),
              );
            }).toList(),
          ),
        ),
      ),

      // ── P-4 CTA: Cooking mode button ──────────────────────
      if (hasStatusAccess(ref, RequiredTier.black)) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 44,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => FullRecipeScreen(meal: meal))),
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: const Text('Режим готовки',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4C1D95),
              side: const BorderSide(color: Color(0xFF4C1D95)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    ]);
  }

  // ── Блок 5: Действия ─────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Row(children: [
      // «Съел ✅»
      Expanded(
        child: SizedBox(height: 48, child: FilledButton.icon(
          onPressed: () {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('✅ ${meal.name} — ${meal.calories} ккал отмечено'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2)));
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Съел', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ),
      const SizedBox(width: 12),
      // «Выбрать другое» → P-3
      Expanded(
        child: SizedBox(height: 48, child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => MealSwapScreen(
                currentMeal: meal, dayIndex: 0, mealIndex: 0)));
          },
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Заменить', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ),
    ]);
  }

  // ── Helpers ──────────────────────────────────────────────────
  static String _mealTypeLabel(String t) => switch (t) {
    'breakfast' => 'Завтрак',
    'lunch' => 'Обед',
    'dinner' => 'Ужин',
    'snack' => 'Перекус',
    _ => t,
  };

  static Color _mealTypeColor(String t) => switch (t) {
    'breakfast' => const Color(0xFFF59E0B),
    'lunch' => const Color(0xFF10B981),
    'dinner' => const Color(0xFF6366F1),
    'snack' => const Color(0xFFEC4899),
    _ => AppColors.primary,
  };
}
