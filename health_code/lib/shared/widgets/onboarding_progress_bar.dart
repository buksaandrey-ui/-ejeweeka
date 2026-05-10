// lib/shared/widgets/onboarding_progress_bar.dart
// Progress bar for onboarding O-2..O-15 (шаг X/14 или X/13)

import 'package:flutter/material.dart';
import 'package:health_code/core/theme/app_theme.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;  // 1-based
  final int totalSteps;   // 14 or 13 (if O-4 skipped)

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Шаг $currentStep из $totalSteps',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
