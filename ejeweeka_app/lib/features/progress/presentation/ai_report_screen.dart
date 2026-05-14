// lib/features/progress/presentation/ai_report_screen.dart
// PR-2: Умный отчёт (AI Report) — еженедельная сводка от HC
// Спека: screens-map.md — referenced in access table
//   Блок 1 — Общая оценка недели
//   Блок 2 — Разделы: Питание, Активность, Гидратация, Сон
//   Блок 3 — HC-рекомендации
//   Доступ: Black+ (White → замок)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';

class AiReportScreen extends ConsumerWidget {
  const AiReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasStatusAccess(ref, RequiredTier.black)) {
      return _lockedView(context);
    }

    // Placeholder report data — in production from backend /api/v1/report/weekly
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekLabel = '${weekStart.day}.${weekStart.month} — ${now.day}.${now.month}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Умный отчёт',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Общая оценка ───────────────────────────────
          _weekHeader(weekLabel),
          const SizedBox(height: 20),

          // ── Блок 2: Разделы ────────────────────────────────────
          _sectionCard('Питание', Icons.restaurant_outlined, const Color(0xFF10B981),
            score: 78, detail: 'Калории: 12 400 / 12 600 ккал (98%)\nБелок: 92% от нормы\n3 дня без отклонений'),
          const SizedBox(height: 10),
          _sectionCard('Активность', Icons.directions_run_outlined, const Color(0xFF6366F1),
            score: 65, detail: '3 из 4 тренировок\n145 мин активности\n~1 200 ккал сожжено'),
          const SizedBox(height: 10),
          _sectionCard('Гидратация', Icons.water_drop_outlined, const Color(0xFF06B6D4),
            score: 82, detail: 'Средний объём: 2.1 / 2.5 л (84%)\n5 из 7 дней цель достигнута'),
          const SizedBox(height: 10),
          _sectionCard('Сон', Icons.bedtime_outlined, const Color(0xFF8B5CF6),
            score: 70, detail: 'Среднее: 7ч 10мин\n2 дня < 7 часов\nРегулярность: 75%'),
          const SizedBox(height: 20),

          // ── Блок 3: HC-рекомендации ────────────────────────────
          _recommendationsBlock(),
        ]),
      ),
    );
  }

  Widget _weekHeader(String weekLabel) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
    ),
    child: Column(children: [
      const Row(children: [
        Icon(Icons.auto_awesome_rounded, size: 24, color: AppColors.primary),
        SizedBox(width: 10),
        Text('Еженедельный отчёт', style: TextStyle(fontFamily: 'Inter',
          fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(weekLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
          color: AppColors.textSecondary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
          child: const Text('74/100', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
        ),
      ]),
    ]),
  );

  Widget _sectionCard(String title, IconData icon, Color color,
      {required int score, required String detail}) {
    final barColor = score >= 80 ? const Color(0xFF10B981)
        : score >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
            fontWeight: FontWeight.w700))),
          Text('$score', style: TextStyle(fontFamily: 'Inter', fontSize: 18,
            fontWeight: FontWeight.w800, color: barColor)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score / 100, minHeight: 4,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(barColor)),
        ),
        const SizedBox(height: 10),
        Text(detail, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
          color: AppColors.textSecondary, height: 1.5)),
      ]),
    );
  }

  Widget _recommendationsBlock() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('РЕКОМЕНДАЦИИ HC', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
      fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    const SizedBox(height: 10),
    _recCard(Icons.restaurant_outlined, 'Добавь больше белка в ужин — сейчас дефицит ~15г',
      const Color(0xFF10B981)),
    const SizedBox(height: 8),
    _recCard(Icons.directions_run_outlined, 'Добавь 1 тренировку в четверг для достижения цели',
      const Color(0xFF6366F1)),
    const SizedBox(height: 8),
    _recCard(Icons.water_drop_outlined, 'Пей стакан воды перед каждым приёмом пищи',
      const Color(0xFF06B6D4)),
  ]);

  Widget _recCard(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.15))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 13,
        color: color, height: 1.4, fontWeight: FontWeight.w500))),
    ]),
  );

  Scaffold _lockedView(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(backgroundColor: AppColors.background, elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
      title: const Text('Умный отчёт',
        style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
      centerTitle: true),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textSecondary),
      const SizedBox(height: 16),
      const Text('Умные отчёты', style: TextStyle(fontFamily: 'Inter',
        fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Еженедельная аналитика доступна\nсо статусом Black и выше',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: const Text('Назад', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
    ])),
  );
}
