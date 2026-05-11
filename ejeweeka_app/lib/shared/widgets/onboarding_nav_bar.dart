// lib/shared/widgets/onboarding_nav_bar.dart
// Equivalent of Capture-phase interceptor on «Далее» button from web version
// RULES from screens-map.md:
//   - Back button: always grey, left side
//   - Next button: orange when isValid, grey/disabled when not
//   - fromSummary: Back → «Отмена», Next → «Сохранить»

import 'package:flutter/material.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';

class OnboardingNavBar extends StatelessWidget {
  final bool isValid;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool fromSummary;
  final bool showBack;

  const OnboardingNavBar({
    super.key,
    required this.isValid,
    required this.onBack,
    required this.onNext,
    this.fromSummary = false,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showBack) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(fromSummary ? '← Отмена' : '← Назад'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: showBack ? 1 : 2,
              child: AnimatedOpacity(
                opacity: isValid ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isValid ? onNext : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: isValid ? AppColors.ctaGradient : null,
                        color: isValid ? null : AppColors.textDisabled,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        fromSummary ? '✓ Сохранить' : 'Далее →',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
