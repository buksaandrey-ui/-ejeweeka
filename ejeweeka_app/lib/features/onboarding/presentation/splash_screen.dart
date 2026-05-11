// lib/features/onboarding/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Remove native splash to reveal this exact identical screen
      FlutterNativeSplash.remove();
      
      // 2. Start animation
      _ctrl.forward().then((_) {
        // 3. Navigate after animation
        _navigate();
      });
    });
  }

  void _navigate() {
    final isOnboarded = ref.read(isOnboardedProvider);
    if (isOnboarded) {
      context.go(Routes.dashboard);
    } else {
      context.go(Routes.o0Welcome);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Matches native splash
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Image.asset(
              'assets/logo/eje-mark-transparent@3x.png',
              width: 144, // Native splash uses roughly this size
            ),
          ),
        ),
      ),
    );
  }
}
