// lib/features/photo/data/photo_analysis_result.dart
// Mirrors PhotoAnalysisResponse from photo.py

class PhotoMacros {
  final double proteins;
  final double fats;
  final double carbs;
  final double fiber;

  const PhotoMacros({
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.fiber,
  });

  factory PhotoMacros.fromJson(Map<String, dynamic> j) => PhotoMacros(
    proteins: (j['proteins'] as num?)?.toDouble() ?? 0,
    fats: (j['fats'] as num?)?.toDouble() ?? 0,
    carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
    fiber: (j['fiber'] as num?)?.toDouble() ?? 0,
  );

  String get summary =>
      'Б ${proteins.toStringAsFixed(0)}г / Ж ${fats.toStringAsFixed(0)}г / У ${carbs.toStringAsFixed(0)}г / К ${fiber.toStringAsFixed(0)}г';
}

class PhotoAnalysisResult {
  final String foodName;
  final double confidence;   // 0.0 – 1.0
  final int calories;
  final PhotoMacros macros;
  final int portionGrams;
  final String verdict;
  final List<String> warnings;
  final int caloriesRemaining;
  final String impact;

  const PhotoAnalysisResult({
    required this.foodName,
    required this.confidence,
    required this.calories,
    required this.macros,
    required this.portionGrams,
    required this.verdict,
    required this.warnings,
    required this.caloriesRemaining,
    required this.impact,
  });

  factory PhotoAnalysisResult.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>? ?? j;
    return PhotoAnalysisResult(
      foodName: data['food_name'] as String? ?? 'Блюдо',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.8,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      macros: PhotoMacros.fromJson(data['macros'] as Map<String, dynamic>? ?? {}),
      portionGrams: (data['portion_grams'] as num?)?.toInt() ?? 300,
      verdict: data['verdict'] as String? ?? '',
      warnings: (data['warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      caloriesRemaining: (data['calories_remaining'] as num?)?.toInt() ?? 0,
      impact: data['impact'] as String? ?? '',
    );
  }

  String get confidenceLabel {
    if (confidence >= 0.85) return '✅ Уверен';
    if (confidence >= 0.65) return '⚠️ Вероятно';
    return '❓ Неточно';
  }

  bool get hasWarnings => warnings.isNotEmpty;
}
