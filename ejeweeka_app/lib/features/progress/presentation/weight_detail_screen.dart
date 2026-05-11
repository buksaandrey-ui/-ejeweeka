// lib/features/progress/presentation/weight_detail_screen.dart
// PR-1W: Детальная статистика веса
// Спека: screens-map.md §PR-1W
//   Блок 1 — Крупное значение (текущий + дельта + цель)
//   Блок 2 — Линейный график (Неделя/Месяц/3мес/Год)
//   Блок 3 — Персональный прогноз
//   Блок 4 — История записей
//   FAB — «+ Записать вес»

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';

class WeightDetailScreen extends ConsumerStatefulWidget {
  const WeightDetailScreen({super.key});

  @override
  ConsumerState<WeightDetailScreen> createState() => _WeightDetailScreenState();
}

class _WeightDetailScreenState extends ConsumerState<WeightDetailScreen> {
  List<_WeightEntry> _entries = [];
  final _weightCtrl = TextEditingController();
  static const _storageKey = 'weight_history';
  int _periodIndex = 0;
  static const _periods = ['Неделя', 'Месяц', '3 мес', 'Всё'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() { _weightCtrl.dispose(); super.dispose(); }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        setState(() => _entries = list.map((e) =>
          _WeightEntry(e['date'] as String, (e['weight'] as num).toDouble())).toList());
      } catch (_) {}
    }
  }

  Future<void> _addEntry(double weight) async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final idx = _entries.indexWhere((e) => e.date == dateStr);
    if (idx >= 0) {
      _entries[idx] = _WeightEntry(dateStr, weight);
    } else {
      _entries.add(_WeightEntry(dateStr, weight));
    }
    _entries.sort((a, b) => a.date.compareTo(b.date));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey,
      jsonEncode(_entries.map((e) => {'date': e.date, 'weight': e.weight}).toList()));
    setState(() {});
  }

  List<_WeightEntry> get _filtered {
    final now = DateTime.now();
    return switch (_periodIndex) {
      0 => _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 7).toList(),
      1 => _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 30).toList(),
      2 => _entries.where((e) => now.difference(DateTime.parse(e.date)).inDays <= 90).toList(),
      _ => List.from(_entries),
    };
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final startWeight = profile.weight ?? 0.0;
    final targetWeight = profile.targetWeight;
    final currentWeight = _entries.isNotEmpty ? _entries.last.weight : startWeight;
    final totalDelta = currentWeight - startWeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('Статистика веса',
          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Блок 1: Крупное значение ──────────────────────────
          _heroCard(currentWeight, totalDelta, targetWeight),
          const SizedBox(height: 16),

          // ── Period selector ─────────────────────────────────────
          _periodSelector(),
          const SizedBox(height: 16),

          // ── Блок 2: График ───────────────────────────────────
          if (_filtered.isNotEmpty) _weightChart(),
          const SizedBox(height: 20),

          // ── Блок 3: Прогноз ──────────────────────────────────
          if (targetWeight != null && _entries.length >= 2)
            _forecastCard(currentWeight, targetWeight),
          const SizedBox(height: 20),

          // ── Блок 4: История ──────────────────────────────────
          _historySection(startWeight),
        ]),
      ),
      // FAB: «+ Записать вес»
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Записать вес',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _heroCard(double current, double delta, double? target) {
    final isDown = delta < 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${current.toStringAsFixed(1)} кг',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              if (delta != 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDown ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 12, color: isDown ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  const SizedBox(width: 2),
                  Text('${delta.abs().toStringAsFixed(1)} кг',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDown ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                ]),
              ),
              if (delta != 0) const SizedBox(width: 8),
              const Text('от старта', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                color: AppColors.textSecondary)),
            ]),
          ]),
          const Spacer(),
          if (target != null) Column(children: [
            const Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text('${target.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter',
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const Text('цель', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              color: AppColors.textSecondary)),
          ]),
        ]),
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
              color: sel ? AppColors.primary : AppColors.textSecondary)),
        ),
      ));
    })),
  );

  Widget _weightChart() {
    final data = _filtered.length > 14 ? _filtered.sublist(_filtered.length - 14) : _filtered;
    if (data.isEmpty) return const SizedBox.shrink();
    final minW = data.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxW = data.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).clamp(1.0, double.infinity);
    final profile = ref.read(profileProvider);
    final target = profile.targetWeight;

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Stack(children: [
        // Target line
        if (target != null && target >= minW && target <= maxW)
          Positioned(
            bottom: 24 + ((target - minW) / range) * 80,
            left: 0, right: 0,
            child: Container(height: 1, color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final frac = (e.weight - minW) / range;
            final isLast = i == data.length - 1;
            final isLow = e.weight == minW;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (isLast || isLow) Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('${e.weight.toStringAsFixed(1)}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w700,
                      color: isLow ? const Color(0xFF10B981) : AppColors.primary)),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300 + i * 50),
                  height: 16 + frac * 70,
                  decoration: BoxDecoration(
                    color: isLast ? AppColors.primary
                        : isLow ? const Color(0xFF10B981)
                        : AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 4),
                Text(e.date.substring(5),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 7, color: AppColors.textSecondary)),
              ]),
            ));
          }).toList(),
        ),
      ]),
    );
  }

  Widget _forecastCard(double current, double target) {
    // Calculate weekly rate from last entries
    double weeklyRate = 0;
    if (_entries.length >= 2) {
      final first = _entries.first;
      final last = _entries.last;
      final daysDiff = DateTime.parse(last.date).difference(DateTime.parse(first.date)).inDays;
      if (daysDiff > 0) {
        weeklyRate = (last.weight - first.weight) / daysDiff * 7;
      }
    }

    final remaining = current - target;
    int weeksToGoal = 0;
    if (weeklyRate.abs() > 0.05 && remaining.sign == -weeklyRate.sign) {
      weeksToGoal = (remaining / weeklyRate).abs().ceil();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFF7FEE7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.trending_down_rounded, color: Color(0xFF10B981)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Прогноз', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(weeksToGoal > 0
              ? 'При текущем темпе цель через ~$weeksToGoal нед.'
              : 'Продолжай записывать вес для прогноза',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
              color: AppColors.textSecondary, height: 1.3)),
          if (weeklyRate.abs() > 0.05) ...[
            const SizedBox(height: 4),
            Text('${weeklyRate > 0 ? '+' : ''}${weeklyRate.toStringAsFixed(2)} кг/нед.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                color: weeklyRate < 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          ],
        ])),
      ]),
    );
  }

  Widget _historySection(double startWeight) {
    if (_entries.isEmpty) {
      return const Center(child: Text('Нет записей',
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)));
    }
    final show = _filtered.reversed.take(15).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ИСТОРИЯ ЗАМЕРОВ', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
        fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: show.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final prevIdx = _entries.indexOf(e) - 1;
          final prev = prevIdx >= 0 ? _entries[prevIdx].weight : startWeight;
          final delta = e.weight - prev;
          return Column(children: [
            ListTile(
              dense: true,
              title: Text(e.date, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.w600)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (delta != 0) Text(
                  '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} кг',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                    color: delta < 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                ),
                const SizedBox(width: 8),
                Text('${e.weight.toStringAsFixed(1)} кг',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
            ),
            if (i < show.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
          ]);
        }).toList()),
      ),
    ]);
  }

  void _showAddDialog(BuildContext context) {
    _weightCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Записать вес', style: TextStyle(fontFamily: 'Inter', fontSize: 18,
            fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _weightCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d+[.,]?\d*'))],
            decoration: const InputDecoration(
              hintText: '70.5', suffixText: 'кг', isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48, child: FilledButton(
            onPressed: () {
              final val = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
              if (val != null && val > 20 && val < 400) {
                _addEntry(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Замер $val кг сохранён'),
                  backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Сохранить', style: TextStyle(fontFamily: 'Inter',
              fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }
}

class _WeightEntry {
  final String date;
  final double weight;
  const _WeightEntry(this.date, this.weight);
}
