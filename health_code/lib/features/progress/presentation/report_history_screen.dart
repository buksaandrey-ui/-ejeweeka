// lib/features/progress/presentation/report_history_screen.dart
// PR-3: История отчётов — архив еженедельных отчётов
// Спека: screens-map.md §PR-3
//   Блок 1 — Список карточек по неделям: дата, общий балл, тренд
//   Нажатие → PR-2 с данными выбранной недели
//   Доступ: Black/Gold/Group Gold

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/widgets/status_gate.dart';
import 'package:health_code/features/progress/presentation/ai_report_screen.dart';

class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasStatusAccess(ref, RequiredTier.black)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0,
          leading: IconButton(onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
          title: const Text('История отчётов',
            style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
          centerTitle: true),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('История отчётов', style: TextStyle(fontFamily: 'Inter',
            fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Доступно со статусом Black и выше',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
        ])),
      );
    }

    // Generate placeholder report history
    final reports = _generateReports();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('История отчётов',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: reports.isEmpty
          ? const Center(child: Text('Нет отчётов',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = reports[i];
                return _reportCard(context, r, i == 0);
              },
            ),
    );
  }

  Widget _reportCard(BuildContext context, _WeekReport report, bool isCurrent) {
    final scoreColor = report.score >= 80 ? const Color(0xFF10B981)
        : report.score >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final trendIcon = report.trend > 0 ? Icons.trending_up_rounded
        : report.trend < 0 ? Icons.trending_down_rounded : Icons.trending_flat_rounded;
    final trendColor = report.trend > 0 ? const Color(0xFF10B981)
        : report.trend < 0 ? const Color(0xFFEF4444) : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AiReportScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCurrent ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB)),
          boxShadow: isCurrent ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))] : null),
        child: Row(children: [
          // Score circle
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              shape: BoxShape.circle),
            child: Center(child: Text('${report.score}',
              style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                fontWeight: FontWeight.w800, color: scoreColor))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report.weekLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Row(children: [
              if (isCurrent) Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: const Text('Текущая', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                  fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(report.trend > 0 ? '+${report.trend}' : '${report.trend}',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w600, color: trendColor)),
            ]),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  List<_WeekReport> _generateReports() {
    final now = DateTime.now();
    return List.generate(8, (i) {
      final start = now.subtract(Duration(days: 7 * i + now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      final label = '${start.day}.${start.month.toString().padLeft(2, '0')} — '
          '${end.day}.${end.month.toString().padLeft(2, '0')}';
      final baseScore = 74 - i * 2;
      return _WeekReport(label, baseScore.clamp(50, 95), i == 0 ? 0 : (i % 3 == 0 ? -2 : 3));
    });
  }
}

class _WeekReport {
  final String weekLabel;
  final int score;
  final int trend; // positive = improvement

  const _WeekReport(this.weekLabel, this.score, this.trend);
}
