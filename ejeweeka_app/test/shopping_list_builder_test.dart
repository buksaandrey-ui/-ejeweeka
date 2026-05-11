// test/shopping_list_builder_test.dart
// Unit tests for ShoppingListBuilder — ingredient deduplication, categorization, sorting
// Run: flutter test test/shopping_list_builder_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ejeweeka_app/features/shopping/data/shopping_list_builder.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';

MealItem _meal(String name, String type, List<Map<String, dynamic>> ingredients) =>
    MealItem(
      name: name,
      mealType: type,
      calories: 400,
      protein: 30,
      fat: 15,
      carbs: 40,
      fiber: 5,
      ingredients: ingredients,
      steps: const [{'step': 'Готовить'}],
      wellnessRationale: '',
    );

DayPlan _day(List<MealItem> meals) => DayPlan(dayNumber: 1, meals: meals);

MealPlan _plan(List<DayPlan> days) => MealPlan(
  generatedAt: DateTime.now().toIso8601String(),
  targetKcal: 2000, bmr: 1700, tdee: 2300,
  daysGenerated: days.length, mealsPerDay: 3,
  modelUsed: 'test', days: days,
);

void main() {
  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Category detection
  // ─────────────────────────────────────────────────────────────
  group('Категоризация продуктов', () {
    test('Куриная грудка → Мясо и птица', () {
      final plan = _plan([_day([
        _meal('Обед', 'lunch', [
          {'name': 'Куриная грудка', 'amount': 200, 'unit': 'г'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      expect(grouped.containsKey('🥩 Мясо и птица'), true);
      expect(grouped['🥩 Мясо и птица']!.first.name, 'Куриная грудка');
    });

    test('Помидоры → Овощи и зелень', () {
      final plan = _plan([_day([
        _meal('Обед', 'lunch', [
          {'name': 'Помидоры', 'amount': 2, 'unit': 'шт'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      expect(grouped.containsKey('🥦 Овощи и зелень'), true);
    });

    test('Неизвестный продукт → Прочее', () {
      final plan = _plan([_day([
        _meal('Ужин', 'dinner', [
          {'name': 'Кунжутная паста', 'amount': 50, 'unit': 'г'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      expect(grouped.containsKey('🛒 Прочее'), true);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: Deduplication — same ingredient sums quantities
  // ─────────────────────────────────────────────────────────────
  group('Дедупликация ингредиентов', () {
    test('Одинаковый продукт суммируется', () {
      final plan = _plan([_day([
        _meal('Завтрак', 'breakfast', [
          {'name': 'Яйцо', 'amount': 2, 'unit': 'шт'},
        ]),
        _meal('Обед', 'lunch', [
          {'name': 'Яйцо', 'amount': 3, 'unit': 'шт'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      final eggs = grouped.values.expand((l) => l).where((i) => i.name.toLowerCase().contains('яйц'));
      expect(eggs.length, 1);
      expect(eggs.first.quantity, 5.0);
    });

    test('Разный регистр → один продукт', () {
      final plan = _plan([_day([
        _meal('Завтрак', 'breakfast', [
          {'name': 'Молоко', 'amount': 200, 'unit': 'мл'},
        ]),
        _meal('Ужин', 'dinner', [
          {'name': 'молоко', 'amount': 300, 'unit': 'мл'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      final milkItems = grouped.values.expand((l) => l).where((i) => i.name.toLowerCase() == 'молоко');
      expect(milkItems.length, 1);
      expect(milkItems.first.quantity, 500.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: Empty/edge cases
  // ─────────────────────────────────────────────────────────────
  group('Edge cases', () {
    test('Пустой план → пустой список', () {
      final plan = _plan([]);
      final grouped = ShoppingListBuilder.build(plan);
      expect(grouped.isEmpty, true);
    });

    test('Блюдо без ингредиентов → пустой список', () {
      final plan = _plan([_day([
        _meal('Обед', 'lunch', []),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      expect(grouped.isEmpty, true);
    });

    test('Ингредиент с пустым именем пропускается', () {
      final plan = _plan([_day([
        _meal('Обед', 'lunch', [
          {'name': '', 'amount': 100, 'unit': 'г'},
          {'name': 'Рис', 'amount': 200, 'unit': 'г'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      final totalItems = grouped.values.fold(0, (s, l) => s + l.length);
      expect(totalItems, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: Category sort order
  // ─────────────────────────────────────────────────────────────
  group('Порядок категорий', () {
    test('Мясо идёт перед Крупами', () {
      final plan = _plan([_day([
        _meal('Обед', 'lunch', [
          {'name': 'Гречка', 'amount': 200, 'unit': 'г'},
          {'name': 'Куриная грудка', 'amount': 200, 'unit': 'г'},
        ]),
      ])]);
      final grouped = ShoppingListBuilder.build(plan);
      final keys = grouped.keys.toList();
      final meatIdx = keys.indexOf('🥩 Мясо и птица');
      final grainIdx = keys.indexOf('🌾 Крупы и хлеб');
      expect(meatIdx, lessThan(grainIdx));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 5: Multi-day deduplication
  // ─────────────────────────────────────────────────────────────
  group('Мульти-день дедупликация', () {
    test('3 дня с рисом → один элемент, сумма количеств', () {
      final plan = _plan([
        _day([_meal('Обед', 'lunch', [{'name': 'Рис', 'amount': 100, 'unit': 'г'}])]),
        _day([_meal('Ужин', 'dinner', [{'name': 'Рис', 'amount': 150, 'unit': 'г'}])]),
        _day([_meal('Обед', 'lunch', [{'name': 'Рис', 'amount': 200, 'unit': 'г'}])]),
      ]);
      final grouped = ShoppingListBuilder.build(plan);
      final rice = grouped.values.expand((l) => l).where((i) => i.name.toLowerCase() == 'рис');
      expect(rice.length, 1);
      expect(rice.first.quantity, 450.0);
    });
  });
}
