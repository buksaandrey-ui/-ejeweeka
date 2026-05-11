// lib/features/dashboard/data/drink_log_model.dart
// Модель лога напитков — architecture.md §7: drink_logs (name, volume, abv, timestamp)

import 'dart:convert';

class DrinkLog {
  final String name;
  final int volumeMl;
  final double? abv; // alcohol by volume %
  final int estimatedKcal;
  final DateTime timestamp;

  DrinkLog({
    required this.name,
    required this.volumeMl,
    this.abv,
    required this.estimatedKcal,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'volume_ml': volumeMl,
    'abv': abv,
    'estimated_kcal': estimatedKcal,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DrinkLog.fromJson(Map<String, dynamic> json) => DrinkLog(
    name: json['name'] as String,
    volumeMl: json['volume_ml'] as int,
    abv: (json['abv'] as num?)?.toDouble(),
    estimatedKcal: json['estimated_kcal'] as int? ?? 0,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  static String encodeList(List<DrinkLog> logs) =>
      jsonEncode(logs.map((l) => l.toJson()).toList());

  static List<DrinkLog> decodeList(String s) {
    final list = jsonDecode(s) as List;
    return list.map((e) => DrinkLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Common drink presets with estimated kcal per 100ml
  static const presets = [
    _DrinkPreset('Вода', 0),
    _DrinkPreset('Чай без сахара', 1),
    _DrinkPreset('Чай с сахаром', 16),
    _DrinkPreset('Кофе чёрный', 2),
    _DrinkPreset('Кофе с молоком', 15),
    _DrinkPreset('Латте', 40),
    _DrinkPreset('Капучино', 35),
    _DrinkPreset('Сок апельсиновый', 45),
    _DrinkPreset('Сок яблочный', 42),
    _DrinkPreset('Кефир 1%', 40),
    _DrinkPreset('Молоко 2.5%', 52),
    _DrinkPreset('Смузи', 55),
    _DrinkPreset('Компот', 25),
    _DrinkPreset('Газировка', 42),
    _DrinkPreset('Энергетик', 45),
    _DrinkPreset('Пиво', 43, abv: 5.0),
    _DrinkPreset('Вино красное', 75, abv: 12.0),
    _DrinkPreset('Вино белое', 70, abv: 12.0),
    _DrinkPreset('Водка', 224, abv: 40.0),
    _DrinkPreset('Коньяк', 224, abv: 40.0),
    _DrinkPreset('Ром', 213, abv: 38.0),
  ];

  static int estimateKcal(String name, int volumeMl, {double? customAbv}) {
    final preset = presets.cast<_DrinkPreset?>().firstWhere(
      (p) => p!.name == name, orElse: () => null,
    );
    
    final abv = customAbv ?? preset?.abv;
    if (abv != null && abv > 0) {
      // Формула: Объем (мл) * (ABV / 100) * 0.8 (плотность) * 7 (ккал на грамм этанола)
      double kcal = volumeMl * (abv / 100.0) * 0.8 * 7.0;
      
      // Для пива и вина добавляем средний углеводный коэффициент
      if (name.toLowerCase().contains('пиво')) {
        kcal += (volumeMl / 100) * 3.5 * 4; // ~3.5g carbs/100ml
      } else if (name.toLowerCase().contains('вино')) {
        kcal += (volumeMl / 100) * 2.5 * 4; // ~2.5g carbs/100ml
      }
      return kcal.round();
    }
    
    if (preset != null) return (preset.kcalPer100ml * volumeMl / 100).round();
    return 0;
  }
}

class _DrinkPreset {
  final String name;
  final int kcalPer100ml;
  final double? abv;
  const _DrinkPreset(this.name, this.kcalPer100ml, {this.abv});
}
