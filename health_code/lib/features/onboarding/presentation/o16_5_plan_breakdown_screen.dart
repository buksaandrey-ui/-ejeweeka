import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/features/plan/providers/plan_provider.dart';

class O165PlanBreakdownScreen extends ConsumerStatefulWidget {
  const O165PlanBreakdownScreen({super.key});

  @override
  ConsumerState<O165PlanBreakdownScreen> createState() => _O165PlanBreakdownScreenState();
}

class _O165PlanBreakdownScreenState extends ConsumerState<O165PlanBreakdownScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _step = 0;
  bool _done = false;
  String? _errorMsg;

  static const _steps = [
    'Анализируем цель и параметры тела…',
    'Рассчитываем калорийность и обмен веществ…',
    'Подбираем блюда под ограничения…',
    'Проверяем баланс витаминов и минералов…',
    'Формируем недельный план…',
    'План готов!',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _runSteps();
  }

  void _runSteps() async {
    // Show animated steps
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: i < 3 ? 800 : 600));
      if (!mounted) return;
      setState(() => _step = i);
    }

    // Animation complete — proceed
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go(Routes.o17Statuswall);
  }

  // Helper to fire and forget a future
  static void unawaited(Future<void> future) {
    future.catchError((e) => null);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Text('ejeweeka',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
              const SizedBox(height: 48),

              // ── Error state ──────────────────────────────────────
              if (_errorMsg != null) ...[
                const Icon(Icons.error_outline_rounded, color: Color(0xFFF44336), size: 52),
                const SizedBox(height: 16),
                const Text('Ошибка генерации плана',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(_errorMsg!, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () { setState(() { _step = 0; _errorMsg = null; }); _runSteps(); },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.ctaGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.refresh_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Попробовать снова', style: TextStyle(
                            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(Routes.o17Statuswall),
                  child: const Text('Пропустить и перейти дальше',
                    style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],

              // ── Normal state ─────────────────────────────────────
              if (_errorMsg == null) ...[
              // Animated circle
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2 + _ctrl.value * 0.3),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: _done
                        ? const Icon(Icons.check_rounded, size: 52, color: AppColors.primary)
                        : const SizedBox(width: 48, height: 48,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              Text(_done ? '✅ Твой план готов!' : 'Формируем план…',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                textAlign: TextAlign.center),
              const SizedBox(height: 16),

              // Current step
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(_steps[_step.clamp(0, _steps.length - 1)],
                  key: ValueKey(_step),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center),
              ),
              const SizedBox(height: 32),

              // Steps indicator
              ...List.generate(_steps.length, (i) {
                final done = i < _step;
                final current = i == _step;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.primary : current ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
                      ),
                      child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_steps[i],
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                        color: done ? AppColors.primary : current ? AppColors.textPrimary : AppColors.textSecondary))),
                  ]),
                );
              }),

              const SizedBox(height: 32),

              // Name personalisation
              if (profile.name != null)
                Text('${profile.name}, твой план будет уникальным',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              ], // end if (_errorMsg == null)
            ],
          ),
        ),
      ),
    );
  }
}
