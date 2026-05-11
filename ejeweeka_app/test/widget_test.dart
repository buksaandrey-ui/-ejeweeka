// test/widget_test.dart
// App smoke test — verifies the app initializes without errors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ejeweeka_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejeweeka_app/core/storage/isar_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await IsarService.init();
    await tester.pumpWidget(const ProviderScope(child: EjeweekaApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
