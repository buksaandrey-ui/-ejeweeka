// lib/core/utils/bmr_calculator.dart
// Mifflin-St Jeor formula — mirrors assembler.py backend logic

class BmrCalculator {
  /// Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor
  /// gender: 'male' | 'female'
  static double calculate({
    required double weight, // kg
    required double height, // cm
    required int age,
    required String gender,
  }) {
    final base = 10 * weight + 6.25 * height - 5 * age;
    return gender == 'female' ? base - 161 : base + 5;
  }

  /// TDEE = BMR × activity multiplier
  static double calculateTdee({
    required double bmr,
    required double activityMultiplier,
  }) {
    return bmr * activityMultiplier;
  }

  /// Target daily calories based on goal
  static double calculateTargetCalories({
    required double tdee,
    required String goal,
    required String gender,
    double? currentWeight,
    double? targetWeight,
    int? timelineWeeks,
    String? paceClassification,
  }) {
    final floorCalories = gender == 'female' ? 1200.0 : 1500.0;
    double target = tdee;

    if (goal.contains('weight_loss') || goal.contains('lose_weight')) {
      if (currentWeight != null && targetWeight != null && timelineWeeks != null && timelineWeeks > 0) {
        final deltaWeight = currentWeight - targetWeight;
        if (deltaWeight > 0) {
          // 7700 kcal per kg of fat
          double dailyDeficit = (deltaWeight * 7700) / (timelineWeeks * 7);
          
          // Guardrail: Deficit shouldn't exceed 25% of TDEE unless aggressive pace
          final maxSafeDeficit = tdee * 0.25;
          if (paceClassification != 'aggressive' && dailyDeficit > maxSafeDeficit) {
            dailyDeficit = maxSafeDeficit;
          }
          target = tdee - dailyDeficit;
        } else {
          target = tdee * 0.8; // Fallback
        }
      } else {
        target = tdee * 0.8; // Fallback 20% deficit
      }
    } else if (goal.contains('muscle_gain') || goal.contains('gain_muscle')) {
      target = tdee * 1.15; // 15% surplus
    }

    return target < floorCalories ? floorCalories : target;
  }

  /// BMI calculation
  static double calculateBmi({
    required double weight,
    required double height,
  }) {
    return weight / ((height / 100) * (height / 100));
  }

  /// BMI classification
  static String classifyBmi(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25.0) return 'normal';
    if (bmi < 30.0) return 'overweight';
    return 'obese';
  }

  /// Daily fiber target (g) based on WHO/AHA guidelines
  /// Women: 25g baseline, Men: 30-38g baseline
  /// Adjustments: age 50+ → +5g, weight_loss goal → +5g (satiety benefit)
  /// Returns recommended fiber intake in grams per day
  static double calculateTargetFiber({
    required String gender,
    required int age,
    required String? goal,
  }) {
    double base = gender == 'female' ? 25.0 : 30.0;
    // Older adults benefit from higher fiber (improved gut motility)
    if (age >= 50) base += 5;
    // Weight loss: higher fiber improves satiety
    if (goal == 'weight_loss') base += 5;
    // Active males under 50 can aim higher
    if (gender == 'male' && age < 50) base = 38;
    return base;
  }

  /// Weight loss pace classification (from screens-map.md O-4 spec)
  static String classifyWeightLossPace({
    required double currentWeight,
    required double targetWeight,
    required int timelineWeeks,
  }) {
    if (timelineWeeks <= 0) return 'impossible';
    final weeklyLoss = (currentWeight - targetWeight) / timelineWeeks;
    final percentPerWeek = (weeklyLoss / currentWeight) * 100;

    if (percentPerWeek <= 1.0) return 'safe';
    if (percentPerWeek <= 1.3) return 'accelerated';
    if (percentPerWeek <= 1.7) return 'aggressive';
    return 'impossible'; // >1.7%
  }

  /// Activity multiplier from frequency + optional duration adjustment
  /// Base multipliers from Mifflin-St Jeor standard tiers.
  /// Duration modifier adds 0–0.075 on top of base for longer sessions.
  static double activityMultiplier(String activityLevel, {String? duration}) {
    double base;
    switch (activityLevel) {
      case 'none': base = 1.2;
      case 'once': base = 1.375;
      case 'twice': base = 1.425;
      case 'three': base = 1.55;
      case 'four_plus': base = 1.725;
      default: base = 1.2;
    }
    // Duration intensity modifier
    if (activityLevel != 'none' && duration != null) {
      switch (duration) {
        case '10_15': base -= 0.025;  // short sessions slightly lower
        case '20_30': break;           // baseline
        case '30_45': base += 0.025;
        case '45_60': base += 0.05;
        case '60_plus': base += 0.075;
      }
    }
    return base;
  }
}
