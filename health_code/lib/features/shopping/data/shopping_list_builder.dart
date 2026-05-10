// lib/features/shopping/data/shopping_list_builder.dart
// Builds a structured shopping list from a MealPlan
// Groups ingredients by category, deduplicates, sums quantities

import 'package:health_code/features/plan/data/meal_plan_model.dart';

class ShoppingItem {
  final String name;
  double quantity;
  final String unit;
  final String category;
  bool checked;

  ShoppingItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.checked = false,
  });
}

class ShoppingListBuilder {
  static const _categoryMap = {
    'мясо': '🥩 Мясо и птица',
    'куриц': '🥩 Мясо и птица',
    'курин': '🥩 Мясо и птица',
    'говядин': '🥩 Мясо и птица',
    'рыб': '🐟 Рыба и морепродукты',
    'лосос': '🐟 Рыба и морепродукты',
    'тунец': '🐟 Рыба и морепродукты',
    'яйц': '🥚 Яйца и молочное',
    'молок': '🥚 Яйца и молочное',
    'творог': '🥚 Яйца и молочное',
    'сыр': '🥚 Яйца и молочное',
    'йогурт': '🥚 Яйца и молочное',
    'гречк': '🌾 Крупы и хлеб',
    'рис': '🌾 Крупы и хлеб',
    'овёс': '🌾 Крупы и хлеб',
    'хлеб': '🌾 Крупы и хлеб',
    'макарон': '🌾 Крупы и хлеб',
    'помидор': '🥦 Овощи и зелень',
    'огурец': '🥦 Овощи и зелень',
    'капуст': '🥦 Овощи и зелень',
    'брокол': '🥦 Овощи и зелень',
    'морков': '🥦 Овощи и зелень',
    'лук': '🥦 Овощи и зелень',
    'чеснок': '🥦 Овощи и зелень',
    'перец': '🥦 Овощи и зелень',
    'шпинат': '🥦 Овощи и зелень',
    'зелен': '🥦 Овощи и зелень',
    'яблок': '🍎 Фрукты и ягоды',
    'банан': '🍎 Фрукты и ягоды',
    'ягод': '🍎 Фрукты и ягоды',
    'апельсин': '🍎 Фрукты и ягоды',
    'фрукт': '🍎 Фрукты и ягоды',
    'орех': '🥜 Орехи и масла',
    'масл': '🥜 Орехи и масла',
    'авокадо': '🥜 Орехи и масла',
    'бобов': '🫘 Бобовые',
    'фасол': '🫘 Бобовые',
    'чечевиц': '🫘 Бобовые',
    'горох': '🫘 Бобовые',
  };

  static String _categorize(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '🛒 Прочее';
  }

  static Map<String, List<ShoppingItem>> build(MealPlan plan) {
    // Flatten all ingredients across all days
    final Map<String, ShoppingItem> merged = {};

    for (final day in plan.days) {
      for (final meal in day.meals) {
        for (final ing in meal.ingredients) {
          final rawName = (ing['name'] as String? ?? '').trim();
          if (rawName.isEmpty) continue;

          final qty = (ing['amount'] as num? ?? ing['quantity'] as num? ?? 1).toDouble();
          final unit = (ing['unit'] as String? ?? 'шт').trim();
          final key = rawName.toLowerCase();
          final category = _categorize(rawName);

          if (merged.containsKey(key)) {
            merged[key]!.quantity += qty;
          } else {
            merged[key] = ShoppingItem(
              name: rawName,
              quantity: qty,
              unit: unit,
              category: category,
            );
          }
        }
      }
    }

    // Group by category
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in merged.values) {
      (grouped[item.category] ??= []).add(item);
    }

    // Sort categories
    final ordered = <String, List<ShoppingItem>>{};
    const catOrder = [
      '🥩 Мясо и птица', '🐟 Рыба и морепродукты', '🥚 Яйца и молочное',
      '🌾 Крупы и хлеб', '🥦 Овощи и зелень', '🍎 Фрукты и ягоды',
      '🥜 Орехи и масла', '🫘 Бобовые', '🛒 Прочее',
    ];
    for (final cat in catOrder) {
      if (grouped.containsKey(cat)) ordered[cat] = grouped[cat]!..sort((a, b) => a.name.compareTo(b.name));
    }

    return ordered;
  }
}
