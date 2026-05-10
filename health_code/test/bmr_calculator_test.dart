// test/bmr_calculator_test.dart
// Unit tests for BmrCalculator — Mifflin-St Jeor + TDEE + BMI + pace logic
// Run: flutter test test/bmr_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_code/core/utils/bmr_calculator.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // GROUP 1: BMR (Mifflin-St Jeor)
  // Formula male:   10*W + 6.25*H - 5*A + 5
  // Formula female: 10*W + 6.25*H - 5*A - 161
  // ─────────────────────────────────────────────────────────────
  group('BMR — Mifflin-St Jeor', () {
    test('Мужчина 30 лет, 80 кг, 180 см → 1 870 ккал', () {
      // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      final result = BmrCalculator.calculate(
        weight: 80, height: 180, age: 30, gender: 'male',
      );
      expect(result, closeTo(1780.0, 0.5));
    });

    test('Женщина 25 лет, 60 кг, 165 см → 1 401.25 ккал', () {
      // 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      final result = BmrCalculator.calculate(
        weight: 60, height: 165, age: 25, gender: 'female',
      );
      expect(result, closeTo(1345.25, 0.5));
    });

    test('Мужчина 45 лет, 95 кг, 175 см', () {
      // 10*95 + 6.25*175 - 5*45 + 5 = 950 + 1093.75 - 225 + 5 = 1823.75
      final result = BmrCalculator.calculate(
        weight: 95, height: 175, age: 45, gender: 'male',
      );
      expect(result, closeTo(1823.75, 0.5));
    });

    test('Женщина 55 лет, 70 кг, 160 см', () {
      // 10*70 + 6.25*160 - 5*55 - 161 = 700 + 1000 - 275 - 161 = 1264
      final result = BmrCalculator.calculate(
        weight: 70, height: 160, age: 55, gender: 'female',
      );
      expect(result, closeTo(1264.0, 0.5));
    });

    test('Граничный случай — очень худой мужчина 18 лет, 50 кг, 170 см', () {
      // 10*50 + 6.25*170 - 5*18 + 5 = 500 + 1062.5 - 90 + 5 = 1477.5
      final result = BmrCalculator.calculate(
        weight: 50, height: 170, age: 18, gender: 'male',
      );
      expect(result, closeTo(1477.5, 0.5));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: TDEE = BMR × коэффициент
  // ─────────────────────────────────────────────────────────────
  group('TDEE — BMR × activity multiplier', () {
    test('BMR 1780 × 1.2 (нет активности) = 2136', () {
      final result = BmrCalculator.calculateTdee(bmr: 1780, activityMultiplier: 1.2);
      expect(result, closeTo(2136.0, 0.5));
    });

    test('BMR 1345 × 1.55 (3 раза/нед) = 2084.75', () {
      final result = BmrCalculator.calculateTdee(bmr: 1345, activityMultiplier: 1.55);
      expect(result, closeTo(2084.75, 0.5));
    });

    test('BMR 1800 × 1.725 (4+ раз/нед) = 3105', () {
      final result = BmrCalculator.calculateTdee(bmr: 1800, activityMultiplier: 1.725);
      expect(result, closeTo(3105.0, 0.5));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: activityMultiplier — соответствие O-10 спеке
  // ─────────────────────────────────────────────────────────────
  group('activityMultiplier — точное соответствие screens-map O-10', () {
    test('none → 1.2', () => expect(BmrCalculator.activityMultiplier('none'), 1.2));
    test('once → 1.375', () => expect(BmrCalculator.activityMultiplier('once'), 1.375));
    test('twice → 1.425', () => expect(BmrCalculator.activityMultiplier('twice'), 1.425));
    test('three → 1.55', () => expect(BmrCalculator.activityMultiplier('three'), 1.55));
    test('four_plus → 1.725', () => expect(BmrCalculator.activityMultiplier('four_plus'), 1.725));
    test('unknown → 1.2 (default)', () => expect(BmrCalculator.activityMultiplier('xyz'), 1.2));
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: Целевые калории по цели
  // ─────────────────────────────────────────────────────────────
  group('calculateTargetCalories — цели и пол', () {
    test('weight_loss: TDEE 2000 × 0.8 = 1600', () {
      final result = BmrCalculator.calculateTargetCalories(
        tdee: 2000, goal: 'weight_loss', gender: 'male',
      );
      expect(result, closeTo(1600.0, 0.5));
    });

    test('muscle_gain: TDEE 2000 × 1.15 = 2300', () {
      final result = BmrCalculator.calculateTargetCalories(
        tdee: 2000, goal: 'muscle_gain', gender: 'male',
      );
      expect(result, closeTo(2300.0, 0.5));
    });

    test('maintenance: TDEE 1800 = 1800', () {
      final result = BmrCalculator.calculateTargetCalories(
        tdee: 1800, goal: 'maintenance', gender: 'female',
      );
      expect(result, closeTo(1800.0, 0.5));
    });

    test('Пол floor — женщина: минимум 1000 ккал при дефиците', () {
      // TDEE 1100 × 0.8 = 880 → floor 1000
      final result = BmrCalculator.calculateTargetCalories(
        tdee: 1100, goal: 'weight_loss', gender: 'female',
      );
      expect(result, greaterThanOrEqualTo(1000.0));
    });

    test('Пол floor — мужчина: минимум 1300 ккал при дефиците', () {
      // TDEE 1400 × 0.8 = 1120 → floor 1300
      final result = BmrCalculator.calculateTargetCalories(
        tdee: 1400, goal: 'weight_loss', gender: 'male',
      );
      expect(result, greaterThanOrEqualTo(1300.0));
    });

    test('lose_weight alias работает как weight_loss', () {
      final r1 = BmrCalculator.calculateTargetCalories(
        tdee: 2000, goal: 'weight_loss', gender: 'male',
      );
      final r2 = BmrCalculator.calculateTargetCalories(
        tdee: 2000, goal: 'lose_weight', gender: 'male',
      );
      expect(r1, equals(r2));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 5: BMI = вес / (рост_м)²
  // ─────────────────────────────────────────────────────────────
  group('calculateBmi', () {
    test('70 кг, 175 см → ИМТ 22.86', () {
      final result = BmrCalculator.calculateBmi(weight: 70, height: 175);
      expect(result, closeTo(22.86, 0.05));
    });

    test('90 кг, 170 см → ИМТ 31.14 (ожирение)', () {
      final result = BmrCalculator.calculateBmi(weight: 90, height: 170);
      expect(result, closeTo(31.14, 0.05));
    });

    test('50 кг, 170 см → ИМТ 17.3 (недовес)', () {
      final result = BmrCalculator.calculateBmi(weight: 50, height: 170);
      expect(result, closeTo(17.30, 0.05));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 6: BMI классификация — строгое соответствие ВОЗ / спеке
  // ─────────────────────────────────────────────────────────────
  group('classifyBmi', () {
    test('< 18.5 → underweight', () => expect(BmrCalculator.classifyBmi(17.5), 'underweight'));
    test('18.5 → normal (граница)', () => expect(BmrCalculator.classifyBmi(18.5), 'normal'));
    test('22.0 → normal', () => expect(BmrCalculator.classifyBmi(22.0), 'normal'));
    test('24.9 → normal (верхняя граница)', () => expect(BmrCalculator.classifyBmi(24.9), 'normal'));
    test('25.0 → overweight (граница)', () => expect(BmrCalculator.classifyBmi(25.0), 'overweight'));
    test('27.5 → overweight', () => expect(BmrCalculator.classifyBmi(27.5), 'overweight'));
    test('29.9 → overweight', () => expect(BmrCalculator.classifyBmi(29.9), 'overweight'));
    test('30.0 → obese (граница)', () => expect(BmrCalculator.classifyBmi(30.0), 'obese'));
    test('35.0 → obese', () => expect(BmrCalculator.classifyBmi(35.0), 'obese'));
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 7: Темп похудения (O-4 спека)
  // safe ≤ 0.8% в нед | accelerated ≤ 1.3% | aggressive ≤ 1.7% | impossible > 1.7%
  // ─────────────────────────────────────────────────────────────
  group('classifyWeightLossPace — screens-map O-4', () {
    test('safe: 80 кг → 76 кг за 10 нед (0.5%/нед)', () {
      // weeklyLoss = 0.4 кг/нед; percent = 0.4/80*100 = 0.5%
      expect(
        BmrCalculator.classifyWeightLossPace(
          currentWeight: 80, targetWeight: 76, timelineWeeks: 10,
        ),
        'safe',
      );
    });

    test('accelerated: 80 кг → 70 кг за 10 нед (1.25%/нед)', () {
      // weeklyLoss = 1 кг/нед; percent = 1/80*100 = 1.25%
      expect(
        BmrCalculator.classifyWeightLossPace(
          currentWeight: 80, targetWeight: 70, timelineWeeks: 10,
        ),
        'accelerated',
      );
    });

    test('aggressive: 80 кг → 66 кг за 10 нед (1.75% → impossible, пересчитаем)', () {
      // 1.4 кг/нед; 1.4/80*100 = 1.75% > 1.7 → impossible
      expect(
        BmrCalculator.classifyWeightLossPace(
          currentWeight: 80, targetWeight: 66, timelineWeeks: 10,
        ),
        'impossible',
      );
    });

    test('aggressive: 90 кг → 76.5 кг за 10 нед (1.5%/нед)', () {
      // weeklyLoss = 1.35 кг/нед; percent = 1.35/90*100 = 1.5%
      expect(
        BmrCalculator.classifyWeightLossPace(
          currentWeight: 90, targetWeight: 76.5, timelineWeeks: 10,
        ),
        'aggressive',
      );
    });

    test('impossible: 0 недель → impossible (деление на 0)', () {
      expect(
        BmrCalculator.classifyWeightLossPace(
          currentWeight: 80, targetWeight: 70, timelineWeeks: 0,
        ),
        'impossible',
      );
    });

    test('safe: нет изменения веса (цель = текущий вес) → safe', () {
      // percentPerWeek = 0 ≤ 0.8 → safe
      expect(
        BmrCalculator.classifyWeightLossPace(
          currentWeight: 80, targetWeight: 80, timelineWeeks: 4,
        ),
        'safe',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 8: Интеграционный сценарий (как в приложении на O-3 → O-10)
  // Пользователь: Иван, мужчина, 35 лет, 85 кг, 178 см, 3 раза/нед тренировки
  // ─────────────────────────────────────────────────────────────
  group('Интеграционный сценарий — полный расчёт', () {
    test('Иван: BMR → TDEE → целевые калории при weight_loss', () {
      // BMR = 10*85 + 6.25*178 - 5*35 + 5 = 850 + 1112.5 - 175 + 5 = 1792.5
      final bmr = BmrCalculator.calculate(
        weight: 85, height: 178, age: 35, gender: 'male',
      );
      expect(bmr, closeTo(1792.5, 0.5));

      // TDEE = 1792.5 × 1.55 = 2778.375
      final multiplier = BmrCalculator.activityMultiplier('three');
      final tdee = BmrCalculator.calculateTdee(bmr: bmr, activityMultiplier: multiplier);
      expect(tdee, closeTo(2778.375, 1.0));

      // Target = TDEE × 0.8 = 2222.7
      final target = BmrCalculator.calculateTargetCalories(
        tdee: tdee, goal: 'weight_loss', gender: 'male',
      );
      expect(target, closeTo(2222.7, 5.0));
      expect(target, greaterThan(1300.0)); // выше мужского floor
    });

    test('Маша: ИМТ + BMR + floor защита при экстремальном дефиците', () {
      // 45 кг, 165 см, 20 лет, женщина, нет активности
      final bmi = BmrCalculator.calculateBmi(weight: 45, height: 165);
      expect(BmrCalculator.classifyBmi(bmi), 'underweight');

      final bmr = BmrCalculator.calculate(
        weight: 45, height: 165, age: 20, gender: 'female',
      );
      // 10*45 + 6.25*165 - 5*20 - 161 = 450 + 1031.25 - 100 - 161 = 1220.25
      expect(bmr, closeTo(1220.25, 0.5));

      final tdee = BmrCalculator.calculateTdee(
        bmr: bmr, activityMultiplier: BmrCalculator.activityMultiplier('none'),
      );
      // 1220.25 × 1.2 = 1464.3

      final target = BmrCalculator.calculateTargetCalories(
        tdee: tdee, goal: 'weight_loss', gender: 'female',
      );
      // 1464.3 × 0.8 = 1171.44 → выше 1000 floor
      expect(target, greaterThanOrEqualTo(1000.0));
    });
  });
}
