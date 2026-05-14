import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/hc_gradient_button.dart';
import 'dart:ui';
import 'package:ejeweeka_app/core/debug/debug_presets.dart';

class O0WelcomeScreen extends ConsumerStatefulWidget {
  const O0WelcomeScreen({super.key});

  @override
  ConsumerState<O0WelcomeScreen> createState() => _O0WelcomeScreenState();
}

class _O0WelcomeScreenState extends ConsumerState<O0WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _usps = [
    {
      'icon': Icons.medical_information_outlined,
      'title': 'Смарт-наставник',
      'desc': 'Смарт-алгоритмы на базе 16 000+ материалов от профильных экспертов в сфере фитнеса и wellness. Никаких случайных генераций и общих диет.',
    },
    {
      'icon': Icons.restaurant_menu_rounded,
      'title': 'Всё в одном плане',
      'desc': 'Что есть, как готовить, что купить, как тренироваться под твой регион проживания, бюджет и свободное время?',
    },
    {
      'icon': Icons.medication_liquid_rounded,
      'title': 'Витамины работают',
      'desc': 'Железо с кофе — деньги на ветер. Без жиров витамин D3 не усваивается. Составим расписание добавок, которое реально усвоится.',
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'title': 'Учтём все нюансы',
      'desc': 'Аллергии, непереносимости или специфические типы питания (например, веганство) - план идеально подстроится под твои цели и образ жизни.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Калории по фото',
      'desc': 'Ужин в ресторане? Просто сфотографируй — смарт-алгоритм всё сам посчитает и скорректирует план.',
    },
    {
      'icon': Icons.local_drink_outlined,
      'title': 'Напитки и алкоголь',
      'desc': 'Добавляй напитки, которые пьешь в течение дня — воду, кофе, сок, коктейли или алкоголь. Мы учтём их калории, состав и влияние алкоголя, и мягко скорректируем твой план на день.',
    },
    {
      'icon': Icons.fitness_center_outlined,
      'title': 'Полезная активность',
      'desc': 'Добавь активность на неделю — мы подберём тренировки под твоё время, цели и уровень нагрузки, а силовые грамотно распределим по группам мышц.',
    },
  ];

  void _showPresetPicker(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('DEV: Выбери тестовый профиль', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: debugPresets.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (_, i) {
                  final p = debugPresets[i];
                  return ListTile(
                    leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(p.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(
                      '${p.data["goal"]} · ${p.data["gender"]} · ${p.data["age"]}лет · ${p.data["subscription_status"]}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final notifier = ref.read(profileNotifierProvider.notifier);
                      await ProfileRepository.deleteAll();
                      await notifier.saveFields(p.data);
                      ref.invalidate(profileProvider);
                      ref.invalidate(isOnboardedProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p.emoji} ${p.label} загружен')),
                        );
                        context.go(Routes.dashboard);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark premium background
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background graphic/glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withValues(alpha: 0.2), // Accent blue
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 90), // Increased from 60 to move down 30px
                // Logo
                Image.asset('assets/logo/ejeweeka-inline-wordmark@2x.png', height: 80),
                const SizedBox(height: 40),

                // Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    itemCount: _usps.length,
                    itemBuilder: (context, index) {
                      final usp = _usps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text(
                              usp['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              usp['desc'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _usps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: HcGradientButton(
                      onPressed: () => context.go(Routes.o1Country),
                      text: 'Начать свой путь',
                    ),
                  ),
                ),
                // Invite Code / Reviewer Mode
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Есть код доступа клуба? (Опционально)',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    onChanged: (value) async {
                      if (value.trim().toUpperCase() == 'APPLE-REVIEW-2026') {
                        await ref.read(profileNotifierProvider.notifier).saveFields({'subscription_status': 'gold'});
                        ref.invalidate(profileProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Reviewer Mode Unlocked (Gold)')),
                          );
                        }
                      }
                    },
                  ),
                ),
                
                // DEV: Skip onboarding with test data (debug only)
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: () => _showPresetPicker(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'DEBUG: 30 пресетов → выбери и на дашборд',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.amber),
                        ),
                      ),
                    ),
                  ),
                ],
                // DEV: Reset button (remove before production)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () async {
                      await ProfileRepository.deleteAll();
                      ref.invalidate(profileProvider);
                      ref.invalidate(profileNotifierProvider);
                      ref.invalidate(isOnboardedProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Все данные онбординга сброшены'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        // Force re-navigate to Welcome to reset router state
                        context.go(Routes.o0Welcome);
                      }
                    },
                    child: Text(
                      'DEV: Сбросить все данные',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.35),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
