// lib/features/onboarding/presentation/o17_statuswall_screen.dart
// O-17: Экран статусов — Accordion с 3D Gold Card, 4 секции, динамические фичи
// Референс: o17-statuswall-ref.html + screens-map.md

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class O17StatuswallScreen extends ConsumerStatefulWidget {
  const O17StatuswallScreen({super.key});

  @override
  ConsumerState<O17StatuswallScreen> createState() =>
      _O17StatuswallScreenState();
}

class _O17StatuswallScreenState extends ConsumerState<O17StatuswallScreen>
    with TickerProviderStateMixin {
  // Accordion state: 0=White, 1=Black, 2=Gold (default), 3=Family
  int _activeIndex = 2;

  // 3D card float animation
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    // ── Dynamic feature filtering ────────────────────────────
    final hasMeds = profile.takesMedications == 'yes';
    final hasSupps = profile.currentlyTakesSupplements ||
        (profile.supplements != null && profile.supplements!.isNotEmpty);
    final hasTraining = profile.activityLevel != null &&
        profile.activityLevel != 'none';

    // Build dynamic Black plan string
    final planParts = <String>['План питания', 'сна'];
    if (hasSupps) planParts.add('приёма витаминов');
    if (hasMeds) planParts.add('лекарств');
    if (hasTraining) planParts.add('тренировок');
    String dynamicPlanStr;
    if (planParts.length > 2) {
      final last = planParts.removeLast();
      dynamicPlanStr = '${planParts.join(', ')} и $last на неделю';
    } else {
      dynamicPlanStr = '${planParts.join(' и ')} на неделю';
    }

    // Medication feature label
    final medsFeatureLabel = hasMeds
        ? 'Совместимость лекарств и Health Connect'
        : 'Интеграция с Health Connect и трекерами активности';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── 3D Gold Card ──────────────────────────────────
              const SizedBox(height: 20),
              _buildGoldCard(),
              const SizedBox(height: 30),

              // ── Title ─────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Всё готово для старта',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Пора знакомиться с ejeweeka ближе!\nИспользуй абсолютно все функции статуса Gold первые 3 дня.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // ── Accordion ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 0: White
                    _AccordionItem(
                      index: 0,
                      activeIndex: _activeIndex,
                      onTap: () => _toggle(0),
                      config: _AccTheme.white,
                      features: const [
                        _Feat(Icons.calendar_today_rounded, 'План питания на 3 дня'),
                        _Feat(Icons.restaurant_rounded, '1 вариант блюда (без пошаговых инструкций)'),
                        _Feat(Icons.show_chart_rounded, 'Базовый прогресс'),
                        _Feat(Icons.shield_rounded, 'Аллергии, заболевания и ограничения учитываются всегда'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1: Black
                    _AccordionItem(
                      index: 1,
                      activeIndex: _activeIndex,
                      onTap: () => _toggle(1),
                      config: _AccTheme.black,
                      plusLabel: 'Все функции Статуса White',
                      features: [
                        _Feat(Icons.event_available_rounded, dynamicPlanStr),
                        const _Feat(Icons.edit_rounded, 'Учет напитков и ручная коррекция плана (ввод блюд)'),
                        const _Feat(Icons.restaurant_rounded, '2 варианта блюд на выбор с пошаговыми инструкциями'),
                        const _Feat(Icons.description_rounded, 'Смарт-отчёты'),
                        _Feat(Icons.monitor_heart_rounded, medsFeatureLabel),
                        const _Feat(Icons.palette_rounded, '4 темы: Светлая, Океан, Закат, Лес'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2: Gold (default active)
                    _AccordionItem(
                      index: 2,
                      activeIndex: _activeIndex,
                      onTap: () => _toggle(2),
                      config: _AccTheme.gold,
                      plusLabel: 'Все функции Статуса Black',
                      features: [
                        const _Feat(Icons.restaurant_rounded, '3 варианта блюд на выбор с пошаговыми инструкциями'),
                        const _Feat(Icons.camera_alt_rounded, 'Фото-анализ (5 раз в день) с коррекцией плана'),
                        if (hasTraining) const _Feat(Icons.fitness_center_rounded, 'Персональные тренировки с видео'),
                        const _Feat(Icons.palette_rounded, '6 тем (добавляются премиальные: Gold и 4 Сезона)'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3: Gold Family
                    _AccordionItem(
                      index: 3,
                      activeIndex: _activeIndex,
                      onTap: () => _toggle(3),
                      config: _AccTheme.family,
                      plusLabel: 'Всё из Статуса Gold',
                      features: const [
                        _Feat(Icons.group_rounded, 'Объединённый план для всей семьи'),
                        _Feat(Icons.shopping_cart_rounded, 'Общий список покупок'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CTA Button ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await ref
                          .read(profileNotifierProvider.notifier)
                          .saveFields({
                        'chosen_status': 'trial',
                        'subscription_status': 'white',
                        'first_launch': DateTime.now().toIso8601String(),
                        'trial_start': DateTime.now().toIso8601String(),
                      });
                      if (context.mounted) {
                        context.go(Routes.o175Disclaimer);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4C1D95), Color(0xFFE85D04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4C1D95).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Вперед!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Activation Code Link removed — forbidden in iOS (App Store Guideline 3.1.1)
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(int index) {
    setState(() {
      _activeIndex = _activeIndex == index ? -1 : index;
    });
  }

  // ── 3D Gold Card with float animation ──────────────────────
  Widget _buildGoldCard() {
    return SizedBox(
      height: 200,
      child: Center(
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(-15 * math.pi / 180)
                ..rotateX(10 * math.pi / 180)
                ..translate(0.0, _floatAnim.value, 0.0),
              child: Container(
                width: 280,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFF4C1D95),
                      Color(0xFFE85D04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C1D95).withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Text(
                      'ejeweeka',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Chip
                    Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Tier label
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'СТАТУС GOLD',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Feature item data ────────────────────────────────────────
class _Feat {
  final IconData icon;
  final String text;
  const _Feat(this.icon, this.text);
}

// ── Accordion theme config ───────────────────────────────────
class _AccTheme {
  final String title;
  final Color bg;
  final Color borderDefault;
  final Color borderActive;
  final Color headerColor;
  final Color caretColor;
  final Color iconColor;
  final Color textColor;
  final BoxShadow? activeShadow;

  const _AccTheme({
    required this.title,
    required this.bg,
    required this.borderDefault,
    required this.borderActive,
    required this.headerColor,
    required this.caretColor,
    required this.iconColor,
    required this.textColor,
    this.activeShadow,
  });

  static const white = _AccTheme(
    title: 'Статус White',
    bg: Colors.white,
    borderDefault: Color(0xFFE5E7EB),
    borderActive: Color(0xFF9CA3AF),
    headerColor: Color(0xFF111827),
    caretColor: Color(0xFF6B7280),
    iconColor: Color(0xFF9CA3AF),
    textColor: Color(0xFF6B7280),
  );

  static const black = _AccTheme(
    title: 'Статус Black',
    bg: Color(0xFF111827),
    borderDefault: Color(0xFF1F2937),
    borderActive: Color(0xFF4B5563),
    headerColor: Colors.white,
    caretColor: Color(0xFF9CA3AF),
    iconColor: Colors.white,
    textColor: Color(0xFFD1D5DB),
  );

  static const gold = _AccTheme(
    title: 'Статус Gold',
    bg: Color(0xFFFFFBEB),
    borderDefault: Color(0xFFFDE68A),
    borderActive: Color(0xFF4C1D95),
    headerColor: Color(0xFFB45309),
    caretColor: Color(0xFF4C1D95),
    iconColor: Color(0xFF4C1D95),
    textColor: Color(0xFF92400E),
    activeShadow: BoxShadow(
      color: Color(0x194C1D95), // rgba(245,146,43, 0.1)
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
  );

  static const family = _AccTheme(
    title: 'Статус Gold Family',
    bg: Color(0xFFFEF2F2),
    borderDefault: Color(0xFFFECACA),
    borderActive: Color(0xFFEF4444),
    headerColor: Color(0xFF991B1B),
    caretColor: Color(0xFFEF4444),
    iconColor: Color(0xFFEF4444),
    textColor: Color(0xFF7F1D1D),
  );
}

// ── Accordion Item Widget ────────────────────────────────────
class _AccordionItem extends StatelessWidget {
  final int index;
  final int activeIndex;
  final VoidCallback onTap;
  final _AccTheme config;
  final String? plusLabel;
  final List<_Feat> features;

  const _AccordionItem({
    required this.index,
    required this.activeIndex,
    required this.onTap,
    required this.config,
    required this.features,
    this.plusLabel,
  });

  bool get _isActive => index == activeIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isActive ? config.borderActive : config.borderDefault,
          width: 1.5,
        ),
        boxShadow: _isActive && config.activeShadow != null
            ? [config.activeShadow!]
            : null,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      config.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: config.headerColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isActive ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: config.caretColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body (animated expand/collapse)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOut,
            crossFadeState:
                _isActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plusLabel != null) ...[
                    Text(
                      plusLabel!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: config.textColor.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(f.icon, size: 18, color: config.iconColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.text,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  height: 1.4,
                                  color: config.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
