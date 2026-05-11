// lib/features/dashboard/data/eaten_meal_log.dart
// Лог съеденных блюд из плана — «Съел ✅» persistence
// CalorieRing должен считать ТОЛЬКО реально съеденное, а не весь план дня.
// Хранится в SharedPreferences с ключом по дате.

import 'dart:convert';

class EatenMealEntry {
  final String mealType;   // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final String name;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final DateTime timestamp;

  const EatenMealEntry({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'meal_type': mealType,
    'name': name,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    'timestamp': timestamp.toIso8601String(),
  };

  factory EatenMealEntry.fromJson(Map<String, dynamic> j) => EatenMealEntry(
    mealType: j['meal_type'] as String? ?? '',
    name: j['name'] as String? ?? '',
    calories: (j['calories'] as num?)?.toInt() ?? 0,
    protein: (j['protein'] as num?)?.toDouble() ?? 0,
    fat: (j['fat'] as num?)?.toDouble() ?? 0,
    carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
    fiber: (j['fiber'] as num?)?.toDouble() ?? 0,
    timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  static String encodeList(List<EatenMealEntry> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<EatenMealEntry> decodeList(String s) {
    final list = jsonDecode(s) as List;
    return list.map((e) => EatenMealEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
