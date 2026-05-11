import re

# 1. Fix OnboardingProgressBar padding
path_pb = 'health_code/lib/shared/widgets/onboarding_progress_bar.dart'
with open(path_pb, 'r') as f: content = f.read()
content = content.replace("padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),", "padding: const EdgeInsets.only(top: 4, bottom: 4),")
with open(path_pb, 'w') as f: f.write(content)


# 2. Fix OnboardingScaffold
path_scaffold = 'health_code/lib/shared/widgets/onboarding_scaffold.dart'
with open(path_scaffold, 'r') as f: content = f.read()

old_scaffold_header = """              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (isFromSummary)
                      GestureDetector(
                        onTap: () => context.go(Routes.o16Summary),
                        child: const Text('← К сводке',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    const Spacer(),
                    Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 36),
                  ],
                ),
              ),

              // ── Progress bar ───────────────────────────────────
              if (step != null && totalSteps != null && !isFromSummary)
                OnboardingProgressBar(
                  currentStep: step!,
                  totalSteps: totalSteps!,
                ),

              const SizedBox(height: 8),"""

new_scaffold_header = """              // ── Header & Progress bar ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isFromSummary)
                      GestureDetector(
                        onTap: () => context.go(Routes.o16Summary),
                        child: const Text('← К сводке',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      )
                    else if (step != null && totalSteps != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: OnboardingProgressBar(
                            currentStep: step!,
                            totalSteps: totalSteps!,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    
                    Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 54),
                  ],
                ),
              ),"""

content = content.replace(old_scaffold_header, new_scaffold_header)
with open(path_scaffold, 'w') as f: f.write(content)


# 3. Update logo size in other screens to 54
def update_logo_height(path):
    with open(path, 'r') as f: c = f.read()
    c = c.replace("height: 36", "height: 54")
    with open(path, 'w') as f: f.write(c)

update_logo_height('health_code/lib/features/onboarding/presentation/o1_country_screen.dart')
update_logo_height('health_code/lib/features/onboarding/presentation/o16_summary_screen.dart')
update_logo_height('health_code/lib/features/onboarding/presentation/o16_5_plan_breakdown_screen.dart')
update_logo_height('health_code/lib/features/profile/presentation/u16_about_screen.dart')

print("Layout updated")
