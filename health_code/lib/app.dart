// lib/app.dart
// Root application widget — wires router and theme engine

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/router/app_router.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class HealthCodeApp extends ConsumerWidget {
  const HealthCodeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeKey = ref.watch(profileProvider).selectedTheme;
    final activeTheme = AppTheme.forKey(themeKey);

    return MaterialApp.router(
      title: 'ejeweeka',
      theme: activeTheme,
      // If user chose 'default', system dark mode falls back to materialDark
      darkTheme: themeKey == 'default' ? AppTheme.materialDark : null,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
