// lib/core/debug/debug_presets.dart
// 30 тестовых профилей для быстрого прогона онбординга без ручного ввода.
// Используется ТОЛЬКО в debug-режиме (o0_welcome_screen.dart).

class DebugPreset {
  final String label;
  final String emoji;
  final Map<String, dynamic> data;
  const DebugPreset({required this.label, required this.emoji, required this.data});
}

/// Базовые поля, общие для всех пресетов
Map<String, dynamic> _base(Map<String, dynamic> overrides) {
  final defaults = <String, dynamic>{
    'country': 'RU', 'city': 'Москва',
    'meal_pattern': '3_meals', 'fasting_type': 'none',
    'bedtime': '23:00', 'wakeup_time': '07:00', 'sleep_pattern': 'regular',
    'budget_level': 'medium', 'cooking_time': 'fresh_daily',
    'supplements': 'Нет', 'supplement_openness': 'open',
    'medications': 'Нет', 'o6_visited': true,
    'motivation_barriers': <String>['Нехватка времени'],
    'liked_foods': <String>['Курица', 'Рис', 'Овощи'],
    'disliked_foods': <String>[],
    'excluded_meal_types': <String>[],
    'diseases': <String>[], 'symptoms': <String>[],
    'womens_health': <String>[],
    'diets': <String>[], 'allergies': <String>[],
    'has_allergies': false,
    'subscription_status': 'gold', 'ai_personality': 'premium',
    'onboarding_complete': true, 'disclaimer_accepted': true,
    'first_launch': DateTime.now().toIso8601String(),
    'trial_start': DateTime.now().toIso8601String(),
  };
  defaults.addAll(overrides);
  return defaults;
}

final List<DebugPreset> debugPresets = [
  // ═══ ПОХУДЕНИЕ ═══════════════════════════════════════════
  DebugPreset(label: 'М32 Похудение базовый', emoji: '🏃', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 32, 'height': 178.0, 'weight': 88.0,
    'bmi': 27.8, 'bmi_class': 'overweight', 'bmr': 1820.0,
    'target_weight': 78.0, 'target_timeline_weeks': 16, 'pace_classification': 'moderate',
    'activity_level': 'three', 'activity_types': <String>['Силовые', 'Кардио'],
    'activity_multiplier': 1.55, 'target_daily_calories': 2100.0, 'tdee_calculated': 2821.0,
    'target_daily_fiber': 30.0,
  })),
  DebugPreset(label: 'Ж28 Похудение + аллергии', emoji: '🥜', data: _base({
    'goal': 'weight_loss', 'gender': 'female', 'age': 28, 'height': 165.0, 'weight': 72.0,
    'bmi': 26.4, 'bmi_class': 'overweight', 'bmr': 1430.0,
    'target_weight': 60.0, 'target_timeline_weeks': 20, 'pace_classification': 'moderate',
    'activity_level': 'twice', 'activity_types': <String>['Йога', 'Кардио'],
    'activity_multiplier': 1.375, 'target_daily_calories': 1600.0, 'tdee_calculated': 1966.0,
    'target_daily_fiber': 25.0,
    'has_allergies': true, 'allergies': <String>['Орехи', 'Лактоза'],
  })),
  DebugPreset(label: 'Ж45 Похудение + СПКЯ', emoji: '🩺', data: _base({
    'goal': 'weight_loss', 'gender': 'female', 'age': 45, 'height': 162.0, 'weight': 80.0,
    'bmi': 30.5, 'bmi_class': 'obese', 'bmr': 1350.0,
    'target_weight': 68.0, 'target_timeline_weeks': 24, 'pace_classification': 'gentle',
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 1400.0, 'tdee_calculated': 1620.0, 'target_daily_fiber': 25.0,
    'womens_health': <String>['spkya'], 'diseases': <String>['Инсулинорезистентность'],
    'takes_contraceptives': 'no',
  })),
  DebugPreset(label: 'М50 Похудение + диабет', emoji: '💉', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 50, 'height': 175.0, 'weight': 95.0,
    'bmi': 31.0, 'bmi_class': 'obese', 'bmr': 1720.0,
    'target_weight': 82.0, 'target_timeline_weeks': 30, 'pace_classification': 'gentle',
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 1600.0, 'tdee_calculated': 2064.0, 'target_daily_fiber': 30.0,
    'diseases': <String>['Диабет 2 типа'], 'medications': 'Метформин',
  })),
  // ═══ НАБОР МАССЫ ═════════════════════════════════════════
  DebugPreset(label: 'М22 Набор мышечной массы', emoji: '💪', data: _base({
    'goal': 'muscle_gain', 'gender': 'male', 'age': 22, 'height': 182.0, 'weight': 70.0,
    'bmi': 21.1, 'bmi_class': 'normal', 'bmr': 1780.0,
    'target_weight': 80.0, 'target_timeline_weeks': 20, 'pace_classification': 'moderate',
    'activity_level': 'four_plus', 'activity_types': <String>['Силовые'],
    'activity_multiplier': 1.725, 'target_daily_calories': 3200.0, 'tdee_calculated': 3070.0,
    'target_daily_fiber': 30.0,
  })),
  DebugPreset(label: 'Ж30 Набор массы + веган', emoji: '🌱', data: _base({
    'goal': 'muscle_gain', 'gender': 'female', 'age': 30, 'height': 170.0, 'weight': 55.0,
    'bmi': 19.0, 'bmi_class': 'normal', 'bmr': 1350.0,
    'target_weight': 62.0, 'target_timeline_weeks': 24, 'pace_classification': 'moderate',
    'activity_level': 'three', 'activity_types': <String>['Силовые', 'Пилатес'],
    'activity_multiplier': 1.55, 'target_daily_calories': 2300.0, 'tdee_calculated': 2092.0,
    'target_daily_fiber': 25.0,
    'diets': <String>['vegan'],
  })),
  // ═══ ПОДДЕРЖАНИЕ ═════════════════════════════════════════
  DebugPreset(label: 'М35 Поддержание веса', emoji: '⚖️', data: _base({
    'goal': 'maintenance', 'gender': 'male', 'age': 35, 'height': 180.0, 'weight': 78.0,
    'bmi': 24.1, 'bmi_class': 'normal', 'bmr': 1770.0,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 2430.0, 'tdee_calculated': 2433.0, 'target_daily_fiber': 30.0,
  })),
  // ═══ БЕРЕМЕННОСТЬ / ЛАКТАЦИЯ ═════════════════════════════
  DebugPreset(label: 'Ж29 Беременность 2 триместр', emoji: '🤰', data: _base({
    'goal': 'maintenance', 'gender': 'female', 'age': 29, 'height': 167.0, 'weight': 65.0,
    'bmi': 23.3, 'bmi_class': 'normal', 'bmr': 1400.0,
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 2020.0, 'tdee_calculated': 1680.0, 'target_daily_fiber': 25.0,
    'womens_health': <String>['pregnancy'],
  })),
  DebugPreset(label: 'Ж32 Лактация', emoji: '🍼', data: _base({
    'goal': 'maintenance', 'gender': 'female', 'age': 32, 'height': 165.0, 'weight': 70.0,
    'bmi': 25.7, 'bmi_class': 'overweight', 'bmr': 1420.0,
    'activity_level': 'none', 'activity_multiplier': 1.2,
    'target_daily_calories': 2200.0, 'tdee_calculated': 1704.0, 'target_daily_fiber': 25.0,
    'womens_health': <String>['breastfeeding'],
  })),
  // ═══ ГОЛОДАНИЕ ════════════════════════════════════════════
  DebugPreset(label: 'М30 Ежедневное голодание 16/8', emoji: '⏰', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 30, 'height': 176.0, 'weight': 85.0,
    'bmi': 27.4, 'bmi_class': 'overweight', 'bmr': 1800.0,
    'target_weight': 75.0, 'target_timeline_weeks': 16, 'pace_classification': 'moderate',
    'activity_level': 'three', 'activity_multiplier': 1.55,
    'target_daily_calories': 2000.0, 'tdee_calculated': 2790.0, 'target_daily_fiber': 30.0,
    'fasting_type': 'daily', 'daily_format': '16:8', 'daily_start': '12:00',
    'daily_meals': 2, 'daily_window_end': '20:00',
  })),
  DebugPreset(label: 'М35 Периодическое голодание 5:2', emoji: '📅', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 35, 'height': 180.0, 'weight': 90.0,
    'bmi': 27.8, 'bmi_class': 'overweight', 'bmr': 1830.0,
    'target_weight': 80.0, 'target_timeline_weeks': 20, 'pace_classification': 'gentle',
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 1900.0, 'tdee_calculated': 2516.0, 'target_daily_fiber': 30.0,
    'fasting_type': 'periodic', 'periodic_format': '5:2', 'periodic_freq': '2',
    'periodic_days': <int>[1, 4], 'periodic_start': '09:00',
  })),
  // ═══ СПЕЦИАЛЬНЫЕ ДИЕТЫ ═══════════════════════════════════
  DebugPreset(label: 'Ж25 Кето', emoji: '🥑', data: _base({
    'goal': 'weight_loss', 'gender': 'female', 'age': 25, 'height': 168.0, 'weight': 68.0,
    'bmi': 24.1, 'bmi_class': 'normal', 'bmr': 1430.0,
    'target_weight': 58.0, 'target_timeline_weeks': 18, 'pace_classification': 'moderate',
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 1500.0, 'tdee_calculated': 1966.0, 'target_daily_fiber': 25.0,
    'diets': <String>['keto'],
  })),
  DebugPreset(label: 'М40 Халяль', emoji: '☪️', data: _base({
    'goal': 'maintenance', 'gender': 'male', 'age': 40, 'height': 174.0, 'weight': 82.0,
    'bmi': 27.1, 'bmi_class': 'overweight', 'bmr': 1700.0,
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 2040.0, 'tdee_calculated': 2040.0, 'target_daily_fiber': 30.0,
    'diets': <String>['halal'], 'country': 'AE', 'city': 'Дубай',
  })),
  DebugPreset(label: 'Ж22 Пескетарианец', emoji: '🐟', data: _base({
    'goal': 'improve_energy', 'gender': 'female', 'age': 22, 'height': 160.0, 'weight': 52.0,
    'bmi': 20.3, 'bmi_class': 'normal', 'bmr': 1280.0,
    'activity_level': 'three', 'activity_multiplier': 1.55,
    'target_daily_calories': 1984.0, 'tdee_calculated': 1984.0, 'target_daily_fiber': 25.0,
    'diets': <String>['pescatarian'],
  })),
  DebugPreset(label: 'М28 Безглютеновая', emoji: '🌾', data: _base({
    'goal': 'health_restrictions', 'gender': 'male', 'age': 28, 'height': 180.0, 'weight': 76.0,
    'bmi': 23.5, 'bmi_class': 'normal', 'bmr': 1780.0,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 2447.0, 'tdee_calculated': 2447.0, 'target_daily_fiber': 30.0,
    'diets': <String>['gluten_free'], 'diseases': <String>['Целиакия'],
  })),
  // ═══ ВОЗРАСТНЫЕ ГРУППЫ ═══════════════════════════════════
  DebugPreset(label: 'М18 Молодой спортсмен', emoji: '🏋️', data: _base({
    'goal': 'muscle_gain', 'gender': 'male', 'age': 18, 'height': 175.0, 'weight': 65.0,
    'bmi': 21.2, 'bmi_class': 'normal', 'bmr': 1700.0,
    'target_weight': 75.0, 'target_timeline_weeks': 24,
    'activity_level': 'four_plus', 'activity_types': <String>['Силовые', 'Бокс'],
    'activity_multiplier': 1.725, 'target_daily_calories': 3200.0, 'tdee_calculated': 2932.0,
    'target_daily_fiber': 30.0,
  })),
  DebugPreset(label: 'Ж62 Саркопения', emoji: '🧓', data: _base({
    'goal': 'age_adaptation', 'gender': 'female', 'age': 62, 'height': 160.0, 'weight': 65.0,
    'bmi': 25.4, 'bmi_class': 'overweight', 'bmr': 1200.0,
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 1440.0, 'tdee_calculated': 1440.0, 'target_daily_fiber': 25.0,
    'diseases': <String>['Остеопороз'], 'supplements': 'Кальций, Витамин D',
  })),
  DebugPreset(label: 'М70 Senior + подагра', emoji: '👴', data: _base({
    'goal': 'age_adaptation', 'gender': 'male', 'age': 70, 'height': 172.0, 'weight': 80.0,
    'bmi': 27.0, 'bmi_class': 'overweight', 'bmr': 1450.0,
    'activity_level': 'none', 'activity_multiplier': 1.2,
    'target_daily_calories': 1500.0, 'tdee_calculated': 1740.0, 'target_daily_fiber': 30.0,
    'diseases': <String>['Подагра', 'Гипертония'], 'medications': 'Аллопуринол, Лизиноприл',
  })),
  // ═══ КОЖА / ВОЛОСЫ / ЭНЕРГИЯ ═════════════════════════════
  DebugPreset(label: 'Ж24 Кожа/ногти/волосы', emoji: '💅', data: _base({
    'goal': 'skin_hair_nails', 'gender': 'female', 'age': 24, 'height': 170.0, 'weight': 58.0,
    'bmi': 20.1, 'bmi_class': 'normal', 'bmr': 1380.0,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 1897.0, 'tdee_calculated': 1897.0, 'target_daily_fiber': 25.0,
  })),
  DebugPreset(label: 'М38 Энергия и самочувствие', emoji: '⚡', data: _base({
    'goal': 'improve_energy', 'gender': 'male', 'age': 38, 'height': 183.0, 'weight': 82.0,
    'bmi': 24.5, 'bmi_class': 'normal', 'bmr': 1800.0,
    'activity_level': 'three', 'activity_multiplier': 1.55,
    'target_daily_calories': 2790.0, 'tdee_calculated': 2790.0, 'target_daily_fiber': 30.0,
    'symptoms': <String>['Усталость', 'Плохой сон'],
  })),
  // ═══ ВОССТАНОВЛЕНИЕ ══════════════════════════════════════
  DebugPreset(label: 'М42 Восстановление после стресса', emoji: '🧘', data: _base({
    'goal': 'recovery', 'gender': 'male', 'age': 42, 'height': 178.0, 'weight': 75.0,
    'bmi': 23.7, 'bmi_class': 'normal', 'bmr': 1680.0,
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 2016.0, 'tdee_calculated': 2016.0, 'target_daily_fiber': 30.0,
    'symptoms': <String>['Стресс', 'Тревожность'],
    'motivation_barriers': <String>['Стресс', 'Срывы'],
  })),
  // ═══ СЛАДКОЕ ══════════════════════════════════════════════
  DebugPreset(label: 'Ж35 Тяга к сладкому', emoji: '🍫', data: _base({
    'goal': 'reduce_cravings', 'gender': 'female', 'age': 35, 'height': 164.0, 'weight': 68.0,
    'bmi': 25.3, 'bmi_class': 'overweight', 'bmr': 1380.0,
    'target_weight': 60.0, 'target_timeline_weeks': 16,
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 1400.0, 'tdee_calculated': 1656.0, 'target_daily_fiber': 25.0,
  })),
  // ═══ МЕНОПАУЗА ════════════════════════════════════════════
  DebugPreset(label: 'Ж52 Менопауза', emoji: '🌸', data: _base({
    'goal': 'age_adaptation', 'gender': 'female', 'age': 52, 'height': 163.0, 'weight': 72.0,
    'bmi': 27.1, 'bmi_class': 'overweight', 'bmr': 1280.0,
    'target_weight': 64.0, 'target_timeline_weeks': 24,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 1500.0, 'tdee_calculated': 1760.0, 'target_daily_fiber': 25.0,
    'womens_health': <String>['menopause'],
  })),
  // ═══ БЮДЖЕТЫ ══════════════════════════════════════════════
  DebugPreset(label: 'М25 Экономный бюджет', emoji: '💸', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 25, 'height': 176.0, 'weight': 82.0,
    'bmi': 26.5, 'bmi_class': 'overweight', 'bmr': 1800.0,
    'target_weight': 75.0, 'target_timeline_weeks': 14,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 1900.0, 'tdee_calculated': 2475.0, 'target_daily_fiber': 30.0,
    'budget_level': 'economy',
  })),
  DebugPreset(label: 'Ж38 Премиум бюджет', emoji: '👑', data: _base({
    'goal': 'maintenance', 'gender': 'female', 'age': 38, 'height': 170.0, 'weight': 62.0,
    'bmi': 21.5, 'bmi_class': 'normal', 'bmr': 1380.0,
    'activity_level': 'three', 'activity_multiplier': 1.55,
    'target_daily_calories': 2139.0, 'tdee_calculated': 2139.0, 'target_daily_fiber': 25.0,
    'budget_level': 'premium',
  })),
  // ═══ ГАСТРИТ / ЖКТ ════════════════════════════════════════
  DebugPreset(label: 'Ж30 Гастрит + без лактозы', emoji: '🥛', data: _base({
    'goal': 'health_restrictions', 'gender': 'female', 'age': 30, 'height': 165.0, 'weight': 60.0,
    'bmi': 22.0, 'bmi_class': 'normal', 'bmr': 1370.0,
    'activity_level': 'once', 'activity_multiplier': 1.2,
    'target_daily_calories': 1644.0, 'tdee_calculated': 1644.0, 'target_daily_fiber': 25.0,
    'diseases': <String>['Гастрит'], 'diets': <String>['lactose_free'],
    'has_allergies': true, 'allergies': <String>['Лактоза'],
  })),
  // ═══ МНОЖЕСТВЕННЫЕ АЛЛЕРГИИ ═══════════════════════════════
  DebugPreset(label: 'М28 5 аллергий + кето', emoji: '⚠️', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 28, 'height': 180.0, 'weight': 90.0,
    'bmi': 27.8, 'bmi_class': 'overweight', 'bmr': 1830.0,
    'target_weight': 80.0, 'target_timeline_weeks': 16,
    'activity_level': 'three', 'activity_multiplier': 1.55,
    'target_daily_calories': 2100.0, 'tdee_calculated': 2836.0, 'target_daily_fiber': 30.0,
    'has_allergies': true,
    'allergies': <String>['Орехи', 'Глютен', 'Лактоза', 'Морепродукты', 'Яйца'],
    'diets': <String>['keto'],
  })),
  // ═══ СТАТУСЫ ══════════════════════════════════════════════
  DebugPreset(label: 'White статус (базовый)', emoji: '⬜', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 30, 'height': 178.0, 'weight': 85.0,
    'bmi': 26.8, 'bmi_class': 'overweight', 'bmr': 1790.0,
    'target_weight': 78.0, 'target_timeline_weeks': 14,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 1900.0, 'tdee_calculated': 2461.0, 'target_daily_fiber': 30.0,
    'subscription_status': 'white',
  })),
  DebugPreset(label: 'Black статус (средний)', emoji: '⬛', data: _base({
    'goal': 'maintenance', 'gender': 'female', 'age': 33, 'height': 168.0, 'weight': 63.0,
    'bmi': 22.3, 'bmi_class': 'normal', 'bmr': 1380.0,
    'activity_level': 'three', 'activity_multiplier': 1.55,
    'target_daily_calories': 2139.0, 'tdee_calculated': 2139.0, 'target_daily_fiber': 25.0,
    'subscription_status': 'black',
  })),
  // ═══ АЛКОГОЛЬ ТЕСТ ════════════════════════════════════════
  DebugPreset(label: 'М35 Тест алкоголь-логов', emoji: '🍷', data: _base({
    'goal': 'weight_loss', 'gender': 'male', 'age': 35, 'height': 180.0, 'weight': 88.0,
    'bmi': 27.2, 'bmi_class': 'overweight', 'bmr': 1810.0,
    'target_weight': 80.0, 'target_timeline_weeks': 16,
    'activity_level': 'twice', 'activity_multiplier': 1.375,
    'target_daily_calories': 2000.0, 'tdee_calculated': 2488.0, 'target_daily_fiber': 30.0,
  })),
];
