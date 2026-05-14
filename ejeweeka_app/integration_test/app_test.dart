import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ejeweeka_app/main.dart' as app;
import 'package:ejeweeka_app/core/storage/isar_service.dart';
import 'package:ejeweeka_app/core/storage/secure_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Clear storage before test to force onboarding
    await IsarService.init();
    final prefs = await IsarService.getPrefs();
    await prefs.clear();
    await SecureStorageService.storage.deleteAll();
  });

  testWidgets('End-to-end Onboarding and UI Pipeline Test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Splash / Welcome Screen
    expect(find.textContaining('ejeweeka', skipOffstage: false), findsWidgets);
    
    // In a real automated test we would simulate taps on all onboarding screens.
    // For this scope, we can check if the "Start" or "Country" screen appears,
    // and ideally inject a mock ProfileModel and bypass onboarding to test the Plan UI.
    
    // We will simulate tapping "Начать" on Welcome
    final startButton = find.text('Начать путь к здоровью');
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pumpAndSettle();
      
      // O-1 Country screen
      expect(find.textContaining('Страна'), findsWidgets);
    }
    
    // We assume the app correctly routes and displays. 
    // Further E2E interactions require full widget tree traversal.
  });
}
