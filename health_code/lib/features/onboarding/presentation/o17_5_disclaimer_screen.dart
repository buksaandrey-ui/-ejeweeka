// lib/features/onboarding/presentation/o17_5_disclaimer_screen.dart
// O-17.5: Дисклеймер при первом запуске — показывается один раз.
// «Понятно, поехали!» → H-1 Дашборд.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class O175DisclaimerScreen extends ConsumerWidget {
  const O175DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Важная информация',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Disclaimer items
              _disclaimerItem(
                Icons.lock_outline_rounded,
                'Твои данные хранятся только на этом устройстве',
                'Мы не собираем и не передаём персональные данные на серверы.',
              ),
              const SizedBox(height: 16),
              _disclaimerItem(
                Icons.medical_information_outlined,
                'ejeweeka не является медицинским приложением',
                'Приложение создано как инструмент персонализации питания.',
              ),
              const SizedBox(height: 16),
              _disclaimerItem(
                Icons.info_outline_rounded,
                'Рекомендации носят информационный характер',
                'Они не заменяют консультацию врача. При наличии заболеваний проконсультируйся со специалистом.',
              ),

              const Spacer(flex: 3),

              // CTA button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Save disclaimer acceptance
                    await ref
                        .read(profileNotifierProvider.notifier)
                        .saveFields({
                      'disclaimer_accepted': true,
                      'first_launch':
                          DateTime.now().toIso8601String(),
                    });
                    // Complete onboarding
                    await ref
                        .read(profileNotifierProvider.notifier)
                        .completeOnboarding();
                    if (context.mounted) context.go(Routes.dashboard);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.ctaGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Понятно, поехали!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'ejeweeka • Zero-Knowledge Privacy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _disclaimerItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  )),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
