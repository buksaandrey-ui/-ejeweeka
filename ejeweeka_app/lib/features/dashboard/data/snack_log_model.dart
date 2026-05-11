// lib/features/dashboard/data/snack_log_model.dart
// Модель лога перекусов — ручной ввод + опциональный фото-анализ
// Включает клетчатку (fiber) как 5-й макронутриент наравне с КБЖУ

import 'dart:convert';

class SnackLog {
  final String name;
  final double portionG;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final DateTime timestamp;

  SnackLog({
    required this.name,
    required this.portionG,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.timestamp,
  });

  String get macroSummary =>
      'Б ${protein.toStringAsFixed(0)} · Ж ${fat.toStringAsFixed(0)} · У ${carbs.toStringAsFixed(0)} · Кл ${fiber.toStringAsFixed(0)}';

  Map<String, dynamic> toJson() => {
    'name': name,
    'portion_g': portionG,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SnackLog.fromJson(Map<String, dynamic> json) => SnackLog(
    name: json['name'] as String,
    portionG: (json['portion_g'] as num).toDouble(),
    calories: json['calories'] as int,
    protein: (json['protein'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  static String encodeList(List<SnackLog> logs) =>
      jsonEncode(logs.map((l) => l.toJson()).toList());

  static List<SnackLog> decodeList(String s) {
    final list = jsonDecode(s) as List;
    return list.map((e) => SnackLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Common snack presets (name, kcal/100g, P, F, C, Fiber per 100g)
  static const presets = [
    _SnackPreset('Яблоко', 52, 0.3, 0.2, 14, 2.4),
    _SnackPreset('Банан', 89, 1.1, 0.3, 23, 2.6),
    _SnackPreset('Орехи (микс)', 607, 20, 54, 20, 7.0),
    _SnackPreset('Грецкий орех', 654, 15, 65, 14, 6.7),
    _SnackPreset('Миндаль', 579, 21, 50, 22, 12.5),
    _SnackPreset('Йогурт натуральный', 59, 10, 0.4, 3.6, 0),
    _SnackPreset('Творог 5%', 121, 17, 5, 1.8, 0),
    _SnackPreset('Сыр', 350, 25, 27, 0, 0),
    _SnackPreset('Хлебец', 300, 10, 2, 58, 18.4),
    _SnackPreset('Тёмный шоколад', 546, 5, 35, 60, 11.0),
    _SnackPreset('Протеиновый батончик', 350, 30, 12, 35, 4.0),
    _SnackPreset('Морковь', 41, 0.9, 0.2, 10, 2.8),
    _SnackPreset('Огурец', 15, 0.7, 0.1, 3.6, 0.5),
    _SnackPreset('Варёное яйцо', 155, 13, 11, 1.1, 0),
    _SnackPreset('Хумус', 166, 8, 10, 14, 6.0),
  ];

  static SnackLog fromPreset(String name, double portionG) {
    final p = presets.cast<_SnackPreset?>().firstWhere(
      (p) => p!.name == name, orElse: () => null,
    );
    if (p != null) {
      final mult = portionG / 100;
      return SnackLog(
        name: name,
        portionG: portionG,
        calories: (p.kcal * mult).round(),
        protein: p.protein * mult,
        fat: p.fat * mult,
        carbs: p.carbs * mult,
        fiber: p.fiber * mult,
        timestamp: DateTime.now(),
      );
    }
    return SnackLog(
      name: name, portionG: portionG,
      calories: 0, protein: 0, fat: 0, carbs: 0, fiber: 0,
      timestamp: DateTime.now(),
    );
  }
}

class _SnackPreset {
  final String name;
  final int kcal;
  final double protein, fat, carbs, fiber;
  const _SnackPreset(this.name, this.kcal, this.protein, this.fat, this.carbs, this.fiber);
}
