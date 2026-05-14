// lib/features/plan/data/meal_plan_model.dart
// Local model for a generated meal plan (cached in SharedPreferences)
// Mirrors the normalized JSON response from POST /api/v1/plan/generate

import 'dart:convert';

/// A single meal (dish) within a day
class MealItem {
  final String mealType;    // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final String variantName;
  final String name;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final int prepTimeMin;
  final int servingG;
  final String imageUrl;
  final String wellnessRationale;
  final bool hasProbiotics;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, String>> steps;

  const MealItem({
    required this.mealType,
    this.variantName = 'Основной',
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    this.prepTimeMin = 15,
    this.servingG = 300,
    this.imageUrl = '',
    this.wellnessRationale = '',
    this.hasProbiotics = false,
    this.ingredients = const [],
    this.steps = const [],
  });

  factory MealItem.fromJson(Map<String, dynamic> j) => MealItem(
    mealType: j['meal_type'] as String? ?? 'snack',
    variantName: j['variant_name'] as String? ?? 'Основной',
    name: j['name'] as String? ?? 'Блюдо',
    calories: (j['calories'] as num?)?.toInt() ?? 0,
    protein: (j['protein'] as num?)?.toDouble() ?? 0,
    fat: (j['fat'] as num?)?.toDouble() ?? 0,
    carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
    fiber: (j['fiber'] as num?)?.toDouble() ?? 0,
    prepTimeMin: (j['prep_time_min'] as num?)?.toInt() ?? 15,
    servingG: (j['serving_g'] as num?)?.toInt() ?? 300,
    imageUrl: j['image_url'] as String? ?? '',
    wellnessRationale: j['wellness_rationale'] as String? ?? '',
    hasProbiotics: j['has_probiotics'] as bool? ?? false,
    ingredients: (j['ingredients'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
    steps: (j['steps'] as List<dynamic>?)
        ?.map((e) => Map<String, String>.from((e as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()))))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'meal_type': mealType,
    'variant_name': variantName,
    'name': name,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    'prep_time_min': prepTimeMin,
    'serving_g': servingG,
    'image_url': imageUrl,
    'wellness_rationale': wellnessRationale,
    'has_probiotics': hasProbiotics,
    'ingredients': ingredients,
    'steps': steps,
  };

  /// Total macros in one line for display
  String get macroSummary =>
      'Б: ${protein.toStringAsFixed(0)}г / Ж: ${fat.toStringAsFixed(0)}г / У: ${carbs.toStringAsFixed(0)}г / Кл: ${fiber.toStringAsFixed(0)}г';
}

/// One day of meals
class DayPlan {
  final int dayNumber; // 1..7
  final List<MealItem> meals;
  final int totalCalories;
  final Map<String, dynamic>? workout; // Тренировка на день (если есть)

  DayPlan({required this.dayNumber, required this.meals, this.workout})
      : totalCalories = meals.fold(0, (s, m) => s + m.calories);

  factory DayPlan.fromJson(int dayNumber, dynamic rawData) {
    List<dynamic> jsonMeals = [];
    Map<String, dynamic>? workoutObj;

    // Поддержка как плоского списка (старый API), так и объекта {meals: [], workout: {}}
    if (rawData is List) {
      jsonMeals = rawData;
    } else if (rawData is Map<String, dynamic>) {
      jsonMeals = rawData['meals'] as List<dynamic>? ?? [];
      workoutObj = rawData['workout'] as Map<String, dynamic>?;
    }

    return DayPlan(
      dayNumber: dayNumber,
      meals: jsonMeals.map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList(),
      workout: workoutObj,
    );
  }

  DayPlan copyWith({
    int? dayNumber,
    List<MealItem>? meals,
    Map<String, dynamic>? workout,
  }) {
    return DayPlan(
      dayNumber: dayNumber ?? this.dayNumber,
      meals: meals ?? this.meals,
      workout: workout ?? this.workout,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': dayNumber,
    'meals': meals.map((m) => m.toJson()).toList(),
    if (workout != null) 'workout': workout,
  };
}

/// Full generated plan (3 or 7 days depending on tier)
class MealPlan {
  final String generatedAt; // ISO8601
  final int targetKcal;
  final int bmr;
  final int tdee;
  final int daysGenerated;
  final int mealsPerDay;
  final String modelUsed;
  final List<DayPlan> days;
  final List<String> allergenWarnings;
  final int? estimatedCost;
  final List<String> prohibitedFoodsSheet;

  const MealPlan({
    required this.generatedAt,
    required this.targetKcal,
    required this.bmr,
    required this.tdee,
    required this.daysGenerated,
    required this.mealsPerDay,
    required this.modelUsed,
    required this.days,
    this.allergenWarnings = const [],
    this.prohibitedFoodsSheet = const [],
    this.estimatedCost,
  });

  factory MealPlan.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final days = <DayPlan>[];

    for (int i = 1; i <= 7; i++) {
      final key = 'day_$i';
      if (data.containsKey(key)) {
        final raw = data[key];
        if (raw is List || raw is Map) {
          days.add(DayPlan.fromJson(i, raw));
        }
      }
    }

    return MealPlan(
      generatedAt: DateTime.now().toIso8601String(),
      targetKcal: (json['target_kcal'] as num?)?.toInt() ?? 0,
      bmr: (json['bmr'] as num?)?.toInt() ?? 0,
      tdee: (json['tdee'] as num?)?.toInt() ?? 0,
      daysGenerated: (json['days_generated'] as num?)?.toInt() ?? 3,
      mealsPerDay: (json['meals_per_day'] as num?)?.toInt() ?? 3,
      modelUsed: json['model_used'] as String? ?? '',
      days: days,
      allergenWarnings: (json['allergen_warnings'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      prohibitedFoodsSheet: (data['prohibited_foods_sheet'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      estimatedCost: (data['estimated_cost'] as num?)?.toInt(),
    );
  }

  MealPlan copyWith({
    String? generatedAt,
    int? targetKcal,
    int? bmr,
    int? tdee,
    int? daysGenerated,
    int? mealsPerDay,
    String? modelUsed,
    List<DayPlan>? days,
    List<String>? allergenWarnings,
    List<String>? prohibitedFoodsSheet,
    int? estimatedCost,
  }) {
    return MealPlan(
      generatedAt: generatedAt ?? this.generatedAt,
      targetKcal: targetKcal ?? this.targetKcal,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      daysGenerated: daysGenerated ?? this.daysGenerated,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      modelUsed: modelUsed ?? this.modelUsed,
      days: days ?? this.days,
      allergenWarnings: allergenWarnings ?? this.allergenWarnings,
      prohibitedFoodsSheet: prohibitedFoodsSheet ?? this.prohibitedFoodsSheet,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  Map<String, dynamic> toJson() => {
    'generated_at': generatedAt,
    'target_kcal': targetKcal,
    'bmr': bmr,
    'tdee': tdee,
    'days_generated': daysGenerated,
    'meals_per_day': mealsPerDay,
    'model_used': modelUsed,
    'days': days.map((d) => d.toJson()).toList(),
    'allergen_warnings': allergenWarnings,
    'prohibited_foods_sheet': prohibitedFoodsSheet,
    'estimated_cost': estimatedCost,
  };

  String toJsonString() => jsonEncode(toJson());

  factory MealPlan.fromJsonString(String s) {
    final j = jsonDecode(s) as Map<String, dynamic>;
    final rawDays = (j['days'] as List<dynamic>?) ?? [];
    final days = rawDays.map((d) {
      final dm = d as Map<String, dynamic>;
      // dm['meals'] can be a List, but dm itself is not what DayPlan.fromJson expects here for 'rawData'
      // Wait, DayPlan.fromJson expects rawData which can be a List or a Map with {meals:[], workout:{}}.
      // If dm is exactly what DayPlan.toJson produced, then DayPlan.toJson produced:
      // {'day': dayNumber, 'meals': [...], 'workout': {...}}
      // So dm IS exactly the rawData we want (it has 'meals' and optional 'workout')!
      return DayPlan.fromJson(dm['day'] as int, dm);
    }).toList();
    return MealPlan(
      generatedAt: j['generated_at'] as String? ?? '',
      targetKcal: (j['target_kcal'] as num?)?.toInt() ?? 0,
      bmr: (j['bmr'] as num?)?.toInt() ?? 0,
      tdee: (j['tdee'] as num?)?.toInt() ?? 0,
      daysGenerated: (j['days_generated'] as num?)?.toInt() ?? 3,
      mealsPerDay: (j['meals_per_day'] as num?)?.toInt() ?? 3,
      modelUsed: j['model_used'] as String? ?? '',
      days: days,
      allergenWarnings: (j['allergen_warnings'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      prohibitedFoodsSheet: (j['prohibited_foods_sheet'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      estimatedCost: (j['estimated_cost'] as num?)?.toInt(),
    );
  }

  bool get isStale {
    if (generatedAt.isEmpty) return true;
    final generated = DateTime.tryParse(generatedAt);
    if (generated == null) return true;
    return DateTime.now().difference(generated).inDays >= 7;
  }

  DayPlan? get today {
    if (days.isEmpty) return null;
    final weekday = DateTime.now().weekday; // 1=Mon…7=Sun
    final index = (weekday - 1) % days.length;
    return days[index];
  }
}
