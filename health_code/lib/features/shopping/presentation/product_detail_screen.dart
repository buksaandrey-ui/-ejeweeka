// lib/features/shopping/presentation/product_detail_screen.dart
// S-2: Детали продукта
// Спека: screens-map.md §S-2
//   Блок 1 — Продукт (название, категория, количество)
//   Блок 2 — В каких блюдах используется
//   Блок 3 — Замена (альтернативный продукт с экономией)

import 'package:flutter/material.dart';
import 'package:health_code/core/theme/app_theme.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productName;
  final String category;
  final String amount;

  const ProductDetailScreen({
    super.key,
    required this.productName,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: Text(productName,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Продукт ───────────────────────────────────
          _productCard(),
          const SizedBox(height: 20),

          // ── Блок 2: В каких блюдах ────────────────────────────
          _usedInMeals(context),
          const SizedBox(height: 20),

          // ── Блок 3: Замена ────────────────────────────────────
          _substitutionCard(context),
        ]),
      ),
    );
  }

  Widget _productCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary.withValues(alpha: 0.06), AppColors.primary.withValues(alpha: 0.02)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
    ),
    child: Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14)),
        child: Icon(_categoryIcon(category), size: 28, color: AppColors.primary),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(productName, style: const TextStyle(fontFamily: 'Inter', fontSize: 20,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _categoryColor(category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
            child: Text(category, style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              fontWeight: FontWeight.w600, color: _categoryColor(category))),
          ),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        ]),
      ])),
    ]),
  );

  Widget _usedInMeals(BuildContext context) {
    // Placeholder meals — in production, cross-referenced from meal plan
    final meals = [
      _MealRef('Куриная грудка с рисом', 'Обед', '☀️'),
      _MealRef('Салат Цезарь', 'Ужин', '🌙'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ИСПОЛЬЗУЕТСЯ В БЛЮДАХ', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
        fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      ...meals.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ListTile(
          onTap: () {
            // In production: navigate to P-2 with this meal
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('→ ${m.name}'), duration: const Duration(seconds: 1)));
          },
          leading: Text(m.emoji, style: const TextStyle(fontSize: 20)),
          title: Text(m.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w600)),
          subtitle: Text(m.mealType, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
            color: AppColors.textSecondary)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      )),
    ]);
  }

  Widget _substitutionCard(BuildContext context) {
    // Placeholder substitution — in production from backend
    final sub = _Substitution('Форель', 'Вместо $productName', '~200 ₽ экономия');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('АЛЬТЕРНАТИВА', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
        fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sub.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                fontWeight: FontWeight.w700)),
              Text(sub.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6)),
              child: Text(sub.savings, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 40,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🔄 $productName → ${sub.name}'),
                  backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Заменить', style: TextStyle(fontFamily: 'Inter',
                fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    ]);
  }

  IconData _categoryIcon(String cat) => switch (cat) {
    'Овощи' => Icons.eco_outlined,
    'Фрукты' => Icons.apple,
    'Мясо/Рыба' => Icons.set_meal_outlined,
    'Молочные' => Icons.water_drop_outlined,
    'Крупы' => Icons.grain_outlined,
    'Специи' => Icons.local_florist_outlined,
    _ => Icons.shopping_basket_outlined,
  };

  Color _categoryColor(String cat) => switch (cat) {
    'Овощи' => const Color(0xFF10B981),
    'Фрукты' => const Color(0xFFF59E0B),
    'Мясо/Рыба' => const Color(0xFFEF4444),
    'Молочные' => const Color(0xFF06B6D4),
    'Крупы' => const Color(0xFF8B5CF6),
    _ => AppColors.primary,
  };
}

class _MealRef {
  final String name;
  final String mealType;
  final String emoji;
  _MealRef(this.name, this.mealType, this.emoji);
}

class _Substitution {
  final String name;
  final String description;
  final String savings;
  _Substitution(this.name, this.description, this.savings);
}
