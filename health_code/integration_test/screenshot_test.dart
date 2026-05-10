import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_code/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/storage/isar_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final mockProfile = {
    'gender': 'male',
    'age': 30,
    'weight': 80.0,
    'height': 180.0,
    'goal': 'Сбалансированное питание',
    'tier': 'family_gold',
    'onboardingComplete': true,
    'name': 'Иван',
    'country': 'Россия',
    'targetDailyCalories': 2200,
  };

  final mockPlan = {
    'generated_at': DateTime.now().toIso8601String(),
    'target_kcal': 2200,
    'bmr': 1800,
    'tdee': 2400,
    'days_generated': 1,
    'meals_per_day': 3,
    'model_used': 'mock-model',
    'allergen_warnings': [],
    'days': [
      {
        'day': 1,
        'meals': [
          {
            'mealType': 'breakfast',
            'name': 'Овсянка с ягодами',
            'calories': 450,
            'protein': 15.0,
            'fat': 12.0,
            'carbs': 60.0,
            'fiber': 8.0,
            'ingredients': [
              {'name': 'Овсяные хлопья', 'amount': 60, 'unit': 'г'},
              {'name': 'Ягоды', 'amount': 50, 'unit': 'г'},
            ],
            'steps': [
              {'title': 'Шаг 1', 'text': 'Сварите овсянку'},
              {'title': 'Шаг 2', 'text': 'Добавьте ягоды'},
            ]
          },
          {
            'mealType': 'lunch',
            'name': 'Куриная грудка с киноа',
            'calories': 650,
            'protein': 45.0,
            'fat': 15.0,
            'carbs': 70.0,
            'fiber': 12.0,
            'ingredients': [
              {'name': 'Куриная грудка', 'amount': 150, 'unit': 'г'},
              {'name': 'Киноа', 'amount': 80, 'unit': 'г'},
            ],
            'steps': []
          },
          {
            'mealType': 'dinner',
            'name': 'Запеченный лосось',
            'calories': 550,
            'protein': 40.0,
            'fat': 25.0,
            'carbs': 20.0,
            'fiber': 10.0,
            'ingredients': [
              {'name': 'Лосось', 'amount': 150, 'unit': 'г'},
              {'name': 'Брокколи', 'amount': 200, 'unit': 'г'},
            ],
            'steps': []
          }
        ]
      }
    ]
  };

  testWidgets('Generate App Store Screenshots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'aidiet_profile': jsonEncode(mockProfile),
      'cached_meal_plan': jsonEncode(mockPlan),
      'hc_auth_token': 'mock-token',
    });
    await IsarService.init();

    await tester.pumpWidget(const ProviderScope(child: HealthCodeApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await Future.delayed(const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    print('📸 Taking screenshot: 1_dashboard');
    await binding.takeScreenshot('1_dashboard');

    print('📸 Navigating to Plan Tab');
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot('2_meal_plan');

    print('📸 Navigating to Recipe Detail');
    final recipeFinder = find.text('Овсянка с ягодами');
    if (recipeFinder.evaluate().isNotEmpty) {
      await tester.tap(recipeFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot('3_recipe');
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
    } else {
      print('⚠️ Recipe card not found!');
    }

    print('📸 Navigating to Shopping Tab');
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot('4_shopping');

    print('📸 Navigating to Photo Analysis');
    await tester.tap(find.byType(NavigationDestination).at(0));
    await tester.pumpAndSettle();
    
    final scannerBtn = find.text('Сканер еды');
    if (scannerBtn.evaluate().isNotEmpty) {
      await tester.tap(scannerBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot('5_photo');
    }

    print('✅ All screenshots captured successfully.');
  });
}

