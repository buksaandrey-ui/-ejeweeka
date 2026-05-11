// lib/main.dart — updated: uses SharedPreferences instead of Isar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:ejeweeka_app/core/storage/isar_service.dart';
import 'package:ejeweeka_app/core/storage/secure_storage.dart';
import 'package:ejeweeka_app/app.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 1. Initialize SharedPreferences (profile store)
  await IsarService.init();

  // 2. Ensure anonymous UUID exists in Keychain/Keystore
  await SecureStorageService.ensureAnonymousUuid();

  // 3. Firebase (push notifications, analytics)
  // NOTE: Requires `flutterfire configure` to generate firebase_options.dart
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase init skipped (run `flutterfire configure`): $e');
  }

  // 4. Sentry error monitoring
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 0.1;
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(
      const ProviderScope(child: EjeweekaApp()),
    ),
  );
}
