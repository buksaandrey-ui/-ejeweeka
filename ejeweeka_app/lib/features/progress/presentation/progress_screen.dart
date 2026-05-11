// lib/features/progress/presentation/progress_screen.dart
// PR-1: Прогресс — переключатель периода, графики, streak
// Спека: screens-map.md §PR-1

import 'package:flutter/material.dart';
import 'package:ejeweeka_app/shared/widgets/hc_gradient_button.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/features/progress/presentation/weight_detail_screen.dart';
import 'package:ejeweeka_app/features/progress/presentation/activity_detail_screen.dart';
import 'package:ejeweeka_app/features/progress/presentation/health_score_screen.dart';
import 'package:ejeweeka_app/features/progress/presentation/ai_report_screen.dart';
import 'package:ejeweeka_app/features/progress/presentation/report_history_screen.dart';

class WeightEntry {
  final String date; // 'yyyy-MM-dd'
  final double weight;
  WeightEntry({required this.date, required this.weight});

  factory WeightEntry.fromJson(Map<String, dynamic> j) =>
      WeightEntry(date: j['date'] as String, weight: (j['weight'] as num).toDouble());
  Map<String, dynamic> toJson() => {'date': date, 'weight': weight};
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  List<WeightEntry> _entries = [];
  final _weightCtrl = TextEditingController();
  static const _storageKey = 'weight_history';
  int _periodIndex = 0; // 0=Неделя, 1=Месяц, 2=3мес, 3=Всё
  static const _periods = ['Неделя', 'Месяц', '3 мес', 'Всё'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        setState(() => _entries = list.map((e) => WeightEntry.fromJson(e as Map<String, dynamic>)).toList());
      } catch (_) {}
    }
  }

  Future<void> _addEntry(double weight) async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

    final idx = _entries.indexWhere((e) => e.date == dateStr);
    if (idx >= 0) {
      _entries[idx] = WeightEntry(date: dateStr, weight: weight);
    } else {
      _entries.add(WeightEntry(date: dateStr, weight: weight));
    }
    _entries.sort((a, b) => a.date.compareTo(b.date));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
    setState(() {});
  }

  @override
  void dispose() { _weightCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final startWeight = profile.weight ?? 0;
    final targetWeight = profile.targetWeight;
    final currentWeight = _entries.isNotEmpty ? _entries.last.weight : startWeight;
    final totalLoss = startWeight - currentWeight;
    final remainingLoss = targetWeight != null ? currentWeight - targetWeight : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              const Text('Прогресс',
                style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_entries.isNotEmpty
                  ? 'Последний замер: ${_entries.last.date}'
                  : 'Добавь первый замер веса',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),

              // ── Period selector ────────────────────────────────────
              _buildPeriodSelector(),
              const SizedBox(height: 16),

              // ── Current stats cards (tappable → drill-downs) ─────────
              Row(children: [
                _tappableStatCard(Icons.monitor_weight_outlined, 'Текущий вес', '${currentWeight.toStringAsFixed(1)} кг',
                  totalLoss > 0 ? '-${totalLoss.toStringAsFixed(1)} кг' : null, const Color(0xFF4CAF50),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightDetailScreen()))),
                const SizedBox(width: 10),
                _tappableStatCard(Icons.flag_outlined, 'До цели',
                  targetWeight != null ? '${remainingLoss.toStringAsFixed(1)} кг' : '—',
                  targetWeight != null ? '${targetWeight.toStringAsFixed(1)} кг цель' : null,
                  const Color(0xFFF09030),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightDetailScreen()))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _tappableStatCard(Icons.analytics_outlined, 'ИМТ',
                  profile.bmi != null ? profile.bmi!.toStringAsFixed(1) : '—',
                  profile.bmi != null ? _bmiLabel(profile.bmi!) : null,
                  const Color(0xFF42A5F5),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScoreScreen()))),
                const SizedBox(width: 10),
                _tappableStatCard(Icons.directions_run_rounded, 'Активность', '→',
                  'Тренировки',
                  const Color(0xFF6366F1),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityDetailScreen()))),
              ]),
              const SizedBox(height: 20),

              // ── Streak section ─────────────────────────────────────
              _buildStreak(),
              const SizedBox(height: 16),

              // ── Quick links: AI Report + History ────────────────────
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiReportScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: const Row(children: [
                      Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF4C1D95)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Умный отчёт', style: TextStyle(fontFamily: 'Inter',
                        fontSize: 13, fontWeight: FontWeight.w700))),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                    ]),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportHistoryScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: const Row(children: [
                      Icon(Icons.history_rounded, size: 18, color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Архив', style: TextStyle(fontFamily: 'Inter',
                        fontSize: 13, fontWeight: FontWeight.w700))),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                    ]),
                  ),
                )),
              ]),
              const SizedBox(height: 20),

              // ── Add weight entry ─────────────────────────────────────
              _buildWeightInput(),
              const SizedBox(height: 20),

              // ── Weight chart ──────────────────────────────────────
              if (_entries.isNotEmpty) ...[
                const Text('ГРАФИК ВЕСА',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                _weightChart(),
                const SizedBox(height: 20),

                // ── Weight history list ──────────────────────────────────
                const Text('ЗАМЕРЫ',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                _buildHistoryList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_periods.length, (i) {
          final isSelected = _periodIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2),
                  )] : null,
                ),
                child: Text(_periods[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStreak() {
    // Calculate streak from entries (consecutive days)
    int streak = 0;
    if (_entries.isNotEmpty) {
      streak = 1; // at least 1 if we have entries
      // Simple streak: count consecutive last entries
      for (int i = _entries.length - 1; i > 0; i--) {
        final cur = DateTime.parse(_entries[i].date);
        final prev = DateTime.parse(_entries[i - 1].date);
        if (cur.difference(prev).inDays <= 2) {
          streak++;
        } else {
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: Text('🔥', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$streak ${_dayWord(streak)} подряд!',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16,
              fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(streak > 5 ? 'Отличная серия, продолжай!' : 'Записывай вес каждый день',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
        ])),
      ]),
    );
  }

  String _dayWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'дня';
    return 'дней';
  }

  Widget _buildWeightInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ДОБАВИТЬ ЗАМЕР',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\d+[.,]?\d*')),
            ],
            decoration: const InputDecoration(
              hintText: '70.5', suffixText: 'кг',
              isDense: true,
            ),
          )),
          const SizedBox(width: 12),
          HcGradientButton(
            onPressed: () {
              final val = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
              if (val != null && val > 20 && val < 400) {
                _addEntry(val);
                _weightCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Замер $val кг сохранён'),
                    backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)));
              }
            },
            text: 'Сохранить',
          ),
        ]),
      ]),
    );
  }

  Widget _buildHistoryList() {
    final profile = ref.watch(profileProvider);
    final startWeight = profile.weight ?? 0;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        children: _entries.reversed.take(10).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final prevIdx = _entries.length - 1 - i - 1;
          final prev = prevIdx >= 0 ? _entries[prevIdx].weight : startWeight;
          final delta = e.weight - prev;
          return Column(children: [
            ListTile(
              dense: true,
              title: Text(e.date,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (delta != 0) Text(
                  '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} кг',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                    color: delta < 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                ),
                const SizedBox(width: 8),
                Text('${e.weight.toStringAsFixed(1)} кг',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
            ),
            if (i < _entries.reversed.take(10).length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          ]);
        }).toList(),
      ),
    );
  }


  Widget _tappableStatCard(IconData iconData, String label, String value,
      String? sub, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(iconData, size: 22, color: color),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withValues(alpha: 0.5)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    ),
  );

  Widget _weightChart() {
    // Filter entries based on period
    final now = DateTime.now();
    List<WeightEntry> filtered;
    switch (_periodIndex) {
      case 0: filtered = _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 7).toList(); break;
      case 1: filtered = _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 30).toList(); break;
      case 2: filtered = _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 90).toList(); break;
      default: filtered = _entries; break;
    }
    if (filtered.isEmpty) filtered = _entries.length > 7 ? _entries.sublist(_entries.length - 7) : _entries;
    if (filtered.isEmpty) return const SizedBox.shrink();

    final recent = filtered.length > 14 ? filtered.sublist(filtered.length - 14) : filtered;
    final minW = recent.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxW = recent.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).clamp(1.0, double.infinity);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: recent.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final heightFraction = ((e.weight - minW) / range);
          final isLast = i == recent.length - 1;
          final isLow = e.weight == minW;

          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (isLast || isLow) Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('${e.weight.toStringAsFixed(1)}',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w700,
                    color: isLow ? const Color(0xFF4CAF50) : AppColors.primary)),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + i * 50),
                height: 16 + heightFraction * 64,
                decoration: BoxDecoration(
                  color: isLast ? AppColors.primary
                      : isLow ? const Color(0xFF4CAF50)
                      : AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(e.date.substring(5),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 8, color: AppColors.textSecondary)),
            ]),
          ));
        }).toList(),
      ),
    );
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Дефицит';
    if (bmi < 25) return 'Норма';
    if (bmi < 30) return 'Избыток';
    return 'Ожирение';
  }
}
