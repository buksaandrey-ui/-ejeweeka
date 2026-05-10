import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_code/core/storage/isar_service.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/core/utils/bmr_calculator.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await IsarService.init(); // Assuming this initializes prefs
  });

  test('Scenario 1: Weight Loss (Male, 16:8 fasting)', () async {
    final container = ProviderContainer();
    final notifier = container.read(profileNotifierProvider.notifier);

    // O-2
    await notifier.saveField('goal', 'weight_loss');
    
    // O-1
    await notifier.saveFields({'country': 'Россия', 'city': 'Москва'});
    
    // O-3
    final bmr = BmrCalculator.calculate(gender: 'male', weight: 95, height: 180, age: 35);
    await notifier.saveFields({
      'name': 'Алексей',
      'gender': 'male',
      'age': 35,
      'height': 180.0,
      'weight': 95.0,
      'bmr_kcal': bmr,
    });

    // O-4
    await notifier.saveFields({
      'target_weight': 80.0,
      'target_timeline_weeks': 12,
      'pace_classification': 'accelerated',
    });

    // O-8 Fasting
    await notifier.saveFields({
      'meal_pattern': '3_meals',
      'fasting_attitude': 'want',
      'fasting_type': 'daily',
      'daily_format': '16_8',
    });

    // O-10 Activity
    final multiplier = BmrCalculator.activityMultiplier('three', duration: '45_60');
    final tdee = BmrCalculator.calculateTdee(bmr: bmr, activityMultiplier: multiplier);
    final targetKcal = BmrCalculator.calculateTargetCalories(tdee: tdee, goal: 'weight_loss', gender: 'male');
    
    await notifier.saveFields({
      'activity_level': 'three',
      'activity_multiplier': multiplier.toString(),
      'tdee_calculated': tdee,
      'target_daily_calories': targetKcal,
    });

    // Check final state
    final profile = container.read(profileProvider);
    expect(profile.goal, 'weight_loss');
    expect(profile.name, 'Алексей');
    expect(profile.bmrKcal, isNotNull);
    expect(profile.tdeeCalculated, isNotNull);
    expect(profile.targetDailyCalories! < profile.tdeeCalculated!, true);
    expect(profile.fastingType, 'daily');
    expect(profile.fastingType, 'daily');
  });

  test('Scenario 2: Female Health & Maintenance', () async {
    final container = ProviderContainer();
    final notifier = container.read(profileNotifierProvider.notifier);

    await notifier.saveField('goal', 'maintenance');
    await notifier.saveFields({
      'gender': 'female',
      'womens_health': ['pregnancy'],
      'fasting_attitude': 'no',
      'fasting_type': 'none',
      'excluded_meal_types': ['raw_fish', 'alcohol'],
    });

    final profile = container.read(profileProvider);
    expect(profile.gender, 'female');
    expect(profile.womensHealth.contains('pregnancy'), true);
    expect(profile.fastingType, 'none');
    expect(profile.excludedMealTypes.contains('raw_fish'), true);
  });
}
