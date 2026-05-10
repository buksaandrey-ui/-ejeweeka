// lib/shared/widgets/onboarding_scaffold.dart
// Standard scaffold for all onboarding screens
// Handles: AppBar (no back on O-1), progress bar, scrollable content, nav bar
// fromSummary: detected from ?fromSummary=true query param → shows Отмена/Сохранить

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/router/nav_direction.dart';
import 'package:health_code/shared/widgets/onboarding_progress_bar.dart';
import 'package:health_code/shared/widgets/onboarding_nav_bar.dart';

class OnboardingScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final Widget? tip;
  final int? step;        // null = no progress bar (O-1, O-16, O-17)
  final int? totalSteps;  // 14 or 13
  final bool isValid;
  final VoidCallback onNext;
  final VoidCallback? onBack;   // null = no back button (O-1)
  final bool fromSummary;
  final bool showBack;

  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.content,
    required this.isValid,
    required this.onNext,
    this.subtitle,
    this.tip,
    this.step,
    this.totalSteps,
    this.onBack,
    this.fromSummary = false,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect fromSummary from URL query param
    final isFromSummary = fromSummary ||
        (GoRouterState.of(context).uri.queryParameters['fromSummary'] == 'true');

    return PopScope(
      // Block hardware back on O-1 (onBack == null means O-1)
      canPop: onBack != null || isFromSummary,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isFromSummary) {
          context.go(Routes.o16Summary);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'ejeweeka',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isFromSummary) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go(Routes.o16Summary),
                        child: const Text('← К сводке',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Progress bar ───────────────────────────────────
              if (step != null && totalSteps != null && !isFromSummary)
                OnboardingProgressBar(
                  currentStep: step!,
                  totalSteps: totalSteps!,
                ),

              const SizedBox(height: 8),

              // ── Title block ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Scrollable content ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      if (tip != null) tip!,
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Navigation bar ────────────────────────────────
              OnboardingNavBar(
                isValid: isValid,
                onBack: isFromSummary
                    ? () => context.go(Routes.o16Summary)
                    : () {
                        currentNavDirection = NavDirection.back;
                        (onBack ?? () {})();
                      },
                onNext: isFromSummary
                    ? () {
                        onNext(); // saves data
                        context.go(Routes.o16Summary);
                      }
                    : onNext,
                fromSummary: isFromSummary,
                showBack: showBack && (onBack != null || isFromSummary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

