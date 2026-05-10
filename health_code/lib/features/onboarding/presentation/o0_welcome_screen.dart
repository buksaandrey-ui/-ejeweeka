import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/data/profile_repository.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'dart:ui';

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
      'desc': 'Алгоритмы на базе доказательной медицины от практикующих врачей. Никаких случайных генераций.',
    },
    {
      'icon': Icons.restaurant_menu_rounded,
      'title': 'Всё в одном плане',
      'desc': 'Что есть, как готовить, что купить, как тренироваться — под твой бюджет и свободное время.',
    },
    {
      'icon': Icons.medication_liquid_rounded,
      'title': 'Витамины работают',
      'desc': 'Железо с кофе — деньги на ветер. Составим расписание добавок, которое реально усвоится.',
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'title': 'Учтём все нюансы',
      'desc': 'Аллергии, беременность, подагра или веганство — план идеально подстроится под твой организм.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Калории по фото',
      'desc': 'Ужин в ресторане? Просто сфотографируй — смарт-алгоритм сам всё посчитает и пересчитает план.',
    },
  ];

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
                const SizedBox(height: 40),
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ejeweeka',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
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
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Icon(usp['icon'], size: 80, color: AppColors.primary),
                            ),
                            const SizedBox(height: 40),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => context.go(Routes.o1Country),
                      child: const Text(
                        'Начать свой путь',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                      '🔄 DEV: Сбросить все данные',
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
