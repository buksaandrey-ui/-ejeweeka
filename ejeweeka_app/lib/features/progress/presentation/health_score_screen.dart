// lib/features/progress/presentation/health_score_screen.dart
// PR-1H: Индекс здоровья (Health Score)
// Спека: screens-map.md §PR-1H
//   Блок 1 — Общий балл (круговой индикатор 0-100 + вердикт)
//   Блок 2 — 6 компонентов (ИМТ, талия/рост, питание, гидратация, активность, сон)
//   Блок 3 — HC-рекомендация
//   Блок 4 — Динамика (мини-график за 4 недели)
//   White: базовый (ИМТ + питание), Black+: полный

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class HealthScoreScreen extends ConsumerWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isBlack = hasStatusAccess(ref, RequiredTier.black);

    // Calculate individual component scores (0-100)
    final bmiScore = _bmiScore(profile.bmi);
    const nutritionScore = 72; // placeholder — would come from calorie_log compliance
    const hydrationScore = 65; // placeholder — would come from water_log avg
    const activityScore = 58; // placeholder — would come from activity_log frequency
    const sleepScore = 70; // placeholder — would come from sleep data
    const waistScore = 60; // placeholder — would come from waist_to_height

    // White sees only BMI + nutrition, Black+ sees all 6
    final components = <_Component>[
      _Component('ИМТ', bmiScore, Icons.monitor_weight_outlined, const Color(0xFF42A5F5), true),
      const _Component('Питание', nutritionScore, Icons.restaurant_outlined, Color(0xFF10B981), true),
      _Component('Гидратация', hydrationScore, Icons.water_drop_outlined, const Color(0xFF06B6D4), isBlack),
      _Component('Активность', activityScore, Icons.directions_run_outlined, const Color(0xFF6366F1), isBlack),
      _Component('Сон', sleepScore, Icons.bedtime_outlined, const Color(0xFF8B5CF6), isBlack),
      _Component('Талия/Рост', waistScore, Icons.straighten_outlined, const Color(0xFFF59E0B), isBlack),
    ];

    final activeComponents = components.where((c) => c.unlocked).toList();
    final totalScore = activeComponents.isEmpty ? 0
        : activeComponents.map((c) => c.score).reduce((a, b) => a + b) ~/ activeComponents.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Индекс здоровья',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(children: [
          // ── Блок 1: Общий балл ────────────────────────────────
          _scoreRing(totalScore),
          const SizedBox(height: 24),

          // ── Блок 2: Компоненты ────────────────────────────────
          ...components.map((c) => _componentBar(c)),
          const SizedBox(height: 20),

          // ── Блок 3: HC-рекомендация ───────────────────────────
          _recommendationCard(components, totalScore),
          const SizedBox(height: 20),

          // ── Блок 4: Динамика (мини-график) ────────────────────
          if (isBlack) _dynamicsChart(totalScore),
        ]),
      ),
    );
  }

  Widget _scoreRing(int score) {
    final color = score >= 80 ? const Color(0xFF10B981)
        : score >= 60 ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final verdict = score >= 80 ? 'Отлично!'
        : score >= 60 ? 'Хорошо'
        : score >= 40 ? 'Есть над чем работать'
        : 'Нужно улучшить';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.06), color.withValues(alpha: 0.02)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        SizedBox(width: 120, height: 120, child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 120, height: 120, child: CircularProgressIndicator(
            value: score / 100, strokeWidth: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$score', style: TextStyle(fontFamily: 'Inter', fontSize: 36,
              fontWeight: FontWeight.w800, color: color)),
            const Text('/100', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
              color: AppColors.textSecondary)),
          ]),
        ])),
        const SizedBox(height: 12),
        Text(verdict, style: TextStyle(fontFamily: 'Inter', fontSize: 16,
          fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _componentBar(_Component c) {
    if (!c.unlocked) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(c.icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(c.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Black+', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      );
    }

    final barColor = c.score >= 80 ? const Color(0xFF10B981)
        : c.score >= 60 ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Row(children: [
          Icon(c.icon, size: 20, color: c.color),
          const SizedBox(width: 12),
          Expanded(child: Text(c.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w600))),
          Text('${c.score}', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
            fontWeight: FontWeight.w800, color: barColor)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: c.score / 100, minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(barColor)),
        ),
      ]),
    );
  }

  Widget _recommendationCard(List<_Component> components, int totalScore) {
    final active = components.where((c) => c.unlocked).toList();
    active.sort((a, b) => a.score.compareTo(b.score));
    final weakest = active.isNotEmpty ? active.first : null;

    String advice = 'Продолжай в том же духе!';
    if (weakest != null && weakest.score < 70) {
      advice = switch (weakest.name) {
        'ИМТ' => 'Обрати внимание на вес — следи за калорийностью',
        'Питание' => 'Старайся точнее следовать плану питания',
        'Гидратация' => 'Пей больше воды — стремись к дневной норме',
        'Активность' => 'Добавь больше активности в расписание',
        'Сон' => 'Улучши качество сна — ложись вовремя',
        'Талия/Рост' => 'Сосредоточься на кардио для уменьшения талии',
        _ => 'Продолжай отслеживать свои показатели',
      };
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.tips_and_updates_outlined, size: 20, color: Color(0xFF0284C7)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Рекомендация', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w700, color: Color(0xFF0369A1))),
          const SizedBox(height: 4),
          Text(advice, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
            color: Color(0xFF0369A1), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _dynamicsChart(int currentScore) {
    // Simulate 4 weeks of scores (in production, stored in SharedPreferences)
    final rng = Random(42);
    final scores = List.generate(4, (i) =>
      (currentScore - (3 - i) * rng.nextInt(5)).clamp(0, 100));
    scores.last = currentScore;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ДИНАМИКА', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
        fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: scores.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isLast = i == scores.length - 1;
            final color = s >= 80 ? const Color(0xFF10B981)
                : s >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
            return Column(children: [
              Text('$s', style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                fontWeight: FontWeight.w800, color: isLast ? color : AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isLast ? color : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 4),
              Text('Нед ${i + 1}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                color: AppColors.textSecondary)),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }

  int _bmiScore(double? bmi) {
    if (bmi == null) return 50;
    if (bmi >= 18.5 && bmi < 25) return 95;
    if (bmi >= 25 && bmi < 27) return 75;
    if (bmi >= 27 && bmi < 30) return 55;
    if (bmi < 18.5) return 60;
    return 35; // obesity
  }
}

class _Component {
  final String name;
  final int score;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const _Component(this.name, this.score, this.icon, this.color, this.unlocked);
}
