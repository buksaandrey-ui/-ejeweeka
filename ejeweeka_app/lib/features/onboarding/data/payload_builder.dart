// lib/features/onboarding/data/payload_builder.dart
// ProfilePayloadBuilder — маппинг UserProfile → UserProfilePayload JSON
// Зеркало Pydantic-модели UserProfilePayload из plan.py (строки 106-143)

import 'package:ejeweeka_app/features/onboarding/data/profile_model.dart';

/// Converts local [UserProfile] into the JSON payload expected by
/// POST /api/v1/plan/generate  (UserProfilePayload in plan.py)
class ProfilePayloadBuilder {
  static Map<String, dynamic> build(UserProfile p, {List<Map<String, dynamic>> snacks = const [], List<Map<String, dynamic>> drinks = const []}) {
    // Map canonical activity_level → human-readable string for backend
    final trainingSchedule = _trainingSchedule(p.activityLevel);

    // Map fasting_type → bool + string
    final hasFasting = p.fastingType != null && p.fastingType != 'none';
    final fastingStr = _fastingString(p.fastingType);

    // Map meal_pattern → human-readable string
    final mealPatternStr = _mealPatternString(p.mealPattern);

    // Map sleep times → human-readable string
    final sleepSchedule = _sleepSchedule(p.bedtime, p.wakeupTime);

    // Map budget_level → Russian string
    final budgetLabel = _budgetLabel(p.budgetLevel);

    // Map cooking_time → Russian string
    final cookingLabel = _cookingLabel(p.cookingTime);

    // Tier mapping
    final tier = _tierCode(p.subscriptionStatus);

    // Women's health: pass as List<String> to match backend schema Optional[List[str]]
    final womensHealthList = p.womensHealth.isNotEmpty ? p.womensHealth : null;

    // Activity types label for training_schedule
    final activityTypesStr = p.activityTypes.isNotEmpty
        ? ' (${p.activityTypes.join(', ')})'
        : '';
    final trainingScheduleFull = trainingSchedule + activityTypesStr;

    // Medications
    final medications = p.medications?.isNotEmpty == true ? p.medications : 'Нет';
    final supplements = p.supplements?.isNotEmpty == true ? p.supplements : 'Нет';

    return {
      // ─── Required ──────────────────────────────────────────────
      'age': (p.age ?? 0).toInt(),
      'gender': p.gender ?? 'male', // validated: 'male' | 'female'
      'weight': (p.weight ?? 70).toDouble(),
      'height': (p.height ?? 170).toDouble(),
      'goal': _goalString(p.goal),
      'activity_level': trainingSchedule,
      'country': p.country ?? 'RU',

      // ─── Optional biometrics ────────────────────────────────────
      'target_weight': p.targetWeight,
      'target_timeline_weeks': p.targetTimelineWeeks,
      'bmi': p.bmi?.toString(),
      'bmi_class': p.bmiClass,
      'waist': p.waist?.toString(),
      'body_type': p.bodyType,
      'fat_distribution': p.fatDistribution,

      // ─── Location & budget ──────────────────────────────────────
      'city': p.city ?? '',
      'budget_level': budgetLabel,
      'cooking_time': cookingLabel,

      // ─── Diet & allergies ───────────────────────────────────────
      'allergies': p.allergies,
      'restrictions': _buildRestrictions(p.diets),
      'diets': p.diets, // Alias — backend accepts both

      // ─── Health ─────────────────────────────────────────────────
      'diseases': p.diseases,
      'symptoms': p.symptoms,
      'blood_tests': p.bloodTests,

      // ─── Women's health ─────────────────────────────────────────
      'womens_health': womensHealthList,
      'takes_contraceptives': p.takesContraceptives,

      // ─── Medications & supplements ──────────────────────────────
      'medications': medications,
      'supplements': supplements,
      'supplement_openness': p.supplementOpenness,

      // ─── Schedule ───────────────────────────────────────────────
      'fasting_type': fastingStr,
      'daily_format': p.dailyFormat,
      'daily_start': p.dailyStart,
      'daily_meals': p.dailyMeals,
      'daily_window_end': p.dailyWindowEnd,
      'periodic_format': p.periodicFormat,
      'periodic_freq': p.periodicFreq,
      'periodic_days': p.periodicDays,
      'periodic_start': p.periodicStart,
      'meal_pattern': mealPatternStr,
      'ai_personality': p.aiPersonality,
      'training_schedule': trainingScheduleFull,
      'sleep_schedule': sleepSchedule,
      'activity_types': p.activityTypes,
      'activity_duration': p.activityDuration,

      // ─── Preferences ────────────────────────────────────────────
      'liked_foods': p.likedFoods,
      'disliked_foods': p.dislikedFoods,
      'excluded_meal_types': p.excludedMealTypes,
      'motivation_barriers': p.motivationBarriers,

      // ─── Calculated metabolic values ────────────────────────────
      'activity_multiplier': p.activityMultiplier,
      'target_daily_fiber': p.targetDailyFiber,
      'pace_classification': p.paceClassification,

      // ─── Workout Engine Parameters ──────────────────────────────
      'fitness_level': p.fitnessLevel,
      'workout_location': p.workoutLocation,
      'equipment_available': p.equipment,
      'physical_limitations': p.physicalLimitations,
      'training_days': p.trainingDays,

      // ─── Missing medical context ────────────────────────────────
      'custom_condition': p.customCondition,
      'cooking_style': _cookingStyleLabel(p.cookingStyle),
      'shopping_frequency': _shoppingFrequencyLabel(p.shoppingFrequency),
      'sleep_pattern': p.sleepPattern,

      // ─── Subscription tier ──────────────────────────────────────
      'tier': tier,
      
      // ─── Logs for AI Corrections ────────────────────────────────
      'extra_snacks': snacks,
      'beverages': drinks,
    };
  }

  // ──────────────────────────────────────────────────────────────
  // Mappers
  // ──────────────────────────────────────────────────────────────

  static String _goalString(String? goal) => switch (goal) {
    'weight_loss'        => 'Снизить вес',
    'maintenance'        => 'Поддержание веса',
    'muscle_gain'        => 'Набрать мышечную массу',
    'skin_hair_nails'    => 'Питание для кожи, ногтей, волос',
    'health_restrictions'=> 'Питание при ограничениях по здоровью',
    'age_adaptation'     => 'Адаптировать питание к возрасту',
    'reduce_cravings'    => 'Снизить тягу к сладкому',
    'improve_energy'     => 'Улучшить самочувствие и энергию',
    'recovery'           => 'Восстановление после болезни/стресса',
    _                    => goal ?? 'Поддержание веса',
  };

  static String _trainingSchedule(String? level) => switch (level) {
    'none'     => 'Без регулярных тренировок',
    'once'     => '1 раз в неделю',
    'twice'    => '2 раза в неделю',
    'three'    => '3 раза в неделю',
    'four_plus'=> '4+ раз в неделю',
    _          => 'Без регулярных тренировок',
  };

  static String? _fastingString(String? type) {
    if (type == 'daily' || type == 'periodic' || type == 'none') return type;
    return null;
  }

  static String _mealPatternString(String? pattern) => switch (pattern) {
    '2_meals'  => '2 приёма (обед, ужин)',
    '3_meals'  => '3 приёма (завтрак, обед, ужин)',
    '4_plus'   => '4+ приёма (дробное питание)',
    'flexible' => 'Гибкий режим',
    _          => '3 приема (завтрак, обед, ужин)',
  };

  static String _sleepSchedule(String? bedtime, String? wakeup) {
    if (bedtime == null || wakeup == null) return '8 часов';
    if (bedtime == 'varies' || wakeup == 'varies') return 'Нерегулярный сон';
    return 'Засыпаю в $bedtime, просыпаюсь в $wakeup';
  }

  static String _budgetLabel(String? budget) => switch (budget) {
    'economy' => 'Экономный',
    'medium'  => 'Средний',
    'premium' => 'Премиум',
    _         => 'Средний',
  };

  static String _cookingLabel(String? cooking) => switch (cooking) {
    'fresh_daily'      => 'Готовлю свежее каждый день',
    'batch_cook'       => 'Готовлю заранее (meal prep)',
    'minimal_cooking'  => 'Минимум готовки',
    _                  => 'Без разницы',
  };

  static String _tierCode(String? status) => switch (status) {
    'white'       => 'T1',
    'black'       => 'T2',
    'gold'        => 'T3',
    'family_gold' => 'T3',
    _             => 'T1',
  };

  static String? _cookingStyleLabel(String? style) => switch (style) {
    'daily' => 'Готовлю каждый день',
    'batch_2_3_days' => 'Готовлю заранее (на 2-3 дня)',
    'batch_weekly' => 'Раз в неделю (заготовки)',
    'none'  => 'Не готовлю',
    _       => null,
  };

  static String? _shoppingFrequencyLabel(String? freq) => switch (freq) {
    'daily' => 'Каждый день',
    'few_days' => 'Каждые 2-3 дня',
    'weekly' => 'Раз в неделю',
    _ => null,
  };

  static List<String> _buildRestrictions(List<String> diets) {
    // Remove 'none' placeholder — backend doesn't need it
    return diets.where((d) => d != 'none').toList();
  }
}
