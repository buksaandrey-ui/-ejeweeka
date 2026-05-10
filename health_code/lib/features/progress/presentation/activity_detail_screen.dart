// lib/features/progress/presentation/activity_detail_screen.dart
// PR-1C: Детальная статистика активности
// Спека: screens-map.md §PR-1C
//   Блок 1 — Обзор недели (кольцо тренировок + время + ккал)
//   Блок 2 — Столбчатый график (активные минуты по дням)
//   Блок 3 — Шаги (если Health Connect)
//   Блок 4 — Список тренировок
//   FAB — «+ Добавить тренировку»

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class ActivityEntry {
  final String date;
  final String type;
  final int durationMin;
  final int caloriesBurned;

  ActivityEntry({required this.date, required this.type,
    required this.durationMin, required this.caloriesBurned});

  Map<String, dynamic> toJson() => {
    'date': date, 'type': type, 'duration_min': durationMin, 'calories_burned': caloriesBurned};

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
    date: j['date'] as String,
    type: j['type'] as String? ?? 'Другое',
    durationMin: (j['duration_min'] as num?)?.toInt() ?? 30,
    caloriesBurned: (j['calories_burned'] as num?)?.toInt() ?? 200,
  );
}

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  List<ActivityEntry> _entries = [];
  static const _storageKey = 'activity_history';
  int _periodIndex = 0;
  static const _periods = ['Неделя', 'Месяц'];
  static const _types = ['Бег', 'Ходьба', 'Силовая', 'Йога', 'Плавание', 'Велосипед', 'Другое'];

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
        setState(() => _entries = list.map((e) =>
          ActivityEntry.fromJson(e as Map<String, dynamic>)).toList());
      } catch (_) {}
    }
  }

  Future<void> _addEntry(ActivityEntry entry) async {
    _entries.add(entry);
    _entries.sort((a, b) => a.date.compareTo(b.date));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
    setState(() {});
  }

  List<ActivityEntry> get _filtered {
    final now = DateTime.now();
    return switch (_periodIndex) {
      0 => _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 7).toList(),
      _ => _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 30).toList(),
    };
  }

  int get _weekWorkouts => _filtered.length;
  int get _totalMinutes => _filtered.fold(0, (s, e) => s + e.durationMin);
  int get _totalCalories => _filtered.fold(0, (s, e) => s + e.caloriesBurned);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    // Map activity_level to weekly workout goal
    final weeklyGoal = switch (profile.activityLevel) {
      '5_per_week' || '5+' => 5,
      '3_4_per_week' || '3-4' => 4,
      '1_2_per_week' || '1-2' => 2,
      _ => 3, // default
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Активность',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Обзор недели ─────────────────────────────
          _overviewCard(weeklyGoal),
          const SizedBox(height: 16),

          // ── Period selector ─────────────────────────────────
          _periodSelector(),
          const SizedBox(height: 16),

          // ── Блок 2: Столбчатый график ───────────────────────
          _activityChart(),
          const SizedBox(height: 20),

          // ── Блок 3: Статкарточки ────────────────────────────
          Row(children: [
            _statCard(Icons.local_fire_department_outlined, '$_totalCalories', 'ккал',
              const Color(0xFFEF4444)),
            const SizedBox(width: 10),
            _statCard(Icons.timer_outlined, '$_totalMinutes', 'минут',
              const Color(0xFF6366F1)),
          ]),
          const SizedBox(height: 20),

          // ── Блок 4: Список тренировок ───────────────────────
          _workoutList(),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Тренировка',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _overviewCard(int weeklyGoal) {
    final progress = weeklyGoal > 0
        ? (_weekWorkouts / weeklyGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1).withValues(alpha: 0.08), const Color(0xFF6366F1).withValues(alpha: 0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        // Ring
        SizedBox(width: 72, height: 72, child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 72, height: 72, child: CircularProgressIndicator(
            value: progress, strokeWidth: 7,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
            strokeCap: StrokeCap.round)),
          Text('$_weekWorkouts/$weeklyGoal',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800)),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Тренировки на неделе', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$_totalMinutes мин • $_totalCalories ккал',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(progress >= 1.0 ? '🎉 Цель выполнена!' : 'Ещё ${weeklyGoal - _weekWorkouts} до цели',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
              color: progress >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF6366F1))),
        ])),
      ]),
    );
  }

  Widget _periodSelector() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
    child: Row(children: List.generate(_periods.length, (i) {
      final sel = _periodIndex == i;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _periodIndex = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6, offset: const Offset(0, 2))] : null),
          child: Text(_periods[i], textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? const Color(0xFF6366F1) : AppColors.textSecondary)),
        ),
      ));
    })),
  );

  Widget _activityChart() {
    final days = _periodIndex == 0 ? 7 : 30;
    final now = DateTime.now();
    final barData = <String, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      barData[key] = 0;
    }
    for (final e in _filtered) {
      final key = e.date.substring(5); // MM-DD
      if (barData.containsKey(key)) {
        barData[key] = barData[key]! + e.durationMin;
      }
    }

    final maxVal = barData.values.fold(1, (a, b) => max(a, b));
    final showCount = min(days, 14);
    final displayEntries = barData.entries.toList();
    final visible = displayEntries.length > showCount
        ? displayEntries.sublist(displayEntries.length - showCount) : displayEntries;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: visible.map((entry) {
          final frac = maxVal > 0 ? entry.value / maxVal : 0.0;
          final hasData = entry.value > 0;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (hasData) Text('${entry.value}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 8,
                  fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8 + frac * 56,
                decoration: BoxDecoration(
                  color: hasData ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 4),
              Text(entry.key.substring(3),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 7, color: AppColors.textSecondary)),
            ]),
          ));
        }).toList(),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ),
  );

  Widget _workoutList() {
    if (_filtered.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Нет записей о тренировках',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary))));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ТРЕНИРОВКИ', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
        fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      ...(_filtered.reversed.take(10).map((e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(_typeIcon(e.type), size: 20, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.type, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
              fontWeight: FontWeight.w700)),
            Text('${e.date} • ${e.durationMin} мин',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ])),
          Text('${e.caloriesBurned} ккал',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444))),
        ]),
      ))),
    ]);
  }

  IconData _typeIcon(String type) => switch (type) {
    'Бег' => Icons.directions_run_rounded,
    'Ходьба' => Icons.directions_walk_rounded,
    'Силовая' => Icons.fitness_center_rounded,
    'Йога' => Icons.self_improvement_rounded,
    'Плавание' => Icons.pool_rounded,
    'Велосипед' => Icons.directions_bike_rounded,
    _ => Icons.sports_rounded,
  };

  void _showAddDialog(BuildContext context) {
    String selectedType = _types[0];
    final durCtrl = TextEditingController(text: '30');
    final calCtrl = TextEditingController(text: '200');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Добавить тренировку', style: TextStyle(fontFamily: 'Inter', fontSize: 18,
            fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Type selector
          SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children:
            _types.map((t) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: selectedType == t,
                selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                onSelected: (_) => setModalState(() => selectedType = t)),
            )).toList())),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(
              controller: durCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Минуты', isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Калории', isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
            )),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48, child: FilledButton(
            onPressed: () {
              final dur = int.tryParse(durCtrl.text) ?? 30;
              final cal = int.tryParse(calCtrl.text) ?? 200;
              final today = DateTime.now();
              final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              _addEntry(ActivityEntry(date: dateStr, type: selectedType,
                durationMin: dur, caloriesBurned: cal));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🏃 $selectedType — $dur мин добавлено'),
                backgroundColor: const Color(0xFF6366F1), duration: const Duration(seconds: 2)));
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Сохранить', style: TextStyle(fontFamily: 'Inter',
              fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      )),
    );
  }
}
