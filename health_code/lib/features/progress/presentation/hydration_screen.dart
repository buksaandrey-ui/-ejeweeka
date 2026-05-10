// lib/features/progress/presentation/hydration_screen.dart
// PR-1A: Детальная статистика воды (Гидратация)
// screens-map.md spec:
//   Доступ: Все статусы
//   Блок 1 — Кольцевой индикатор (выпито / норма)
//   Блок 2 — Быстрые кнопки (+150/+250/+500/Свой)
//   Блок 3 — Столбчатый график недели
//   Блок 4 — HC-совет
//   Блок 5 — Настройка нормы (1.0–4.0 л, шаг 0.1)
//   Считывает: water_log, daily_water_goal. Записывает: water_log

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_code/core/theme/app_theme.dart';

class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen>
    with SingleTickerProviderStateMixin {
  double _dailyGoalL = 2.0; // литры
  int _consumedMl = 0;
  Map<String, int> _weekData = {}; // 'YYYY-MM-DD' → ml
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  static const _prefsGoalKey = 'hc_water_goal_l';
  static const _prefsLogKey = 'hc_water_log';

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoalL = prefs.getDouble(_prefsGoalKey) ?? 2.0;
    final raw = prefs.getString(_prefsLogKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _weekData = m.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }
    _consumedMl = _weekData[_todayKey()] ?? 0;
    if (mounted) {
      setState(() {});
      _ringCtrl.forward();
    }
  }

  Future<void> _addWater(int ml) async {
    setState(() => _consumedMl += ml);
    _weekData[_todayKey()] = _consumedMl;
    _ringCtrl.forward(from: 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLogKey, jsonEncode(_weekData));
  }

  Future<void> _setGoal(double l) async {
    setState(() => _dailyGoalL = l);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsGoalKey, l);
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final goalMl = (_dailyGoalL * 1000).toInt();
    final progress = goalMl > 0 ? (_consumedMl / goalMl).clamp(0.0, 1.5) : 0.0;
    final percent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Гидратация', style: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(children: [
          // ── Блок 1: Кольцевой индикатор ──────────────────────
          _buildRing(progress, percent, goalMl),
          const SizedBox(height: 24),

          // ── Блок 2: Быстрые кнопки ──────────────────────────
          _buildQuickButtons(),
          const SizedBox(height: 24),

          // ── Блок 3: Столбчатый график недели ────────────────
          _buildWeekChart(goalMl),
          const SizedBox(height: 20),

          // ── Блок 4: HC-совет ────────────────────────────────
          _buildTip(),
          const SizedBox(height: 20),

          // ── Блок 5: Настройка нормы ─────────────────────────
          _buildGoalSlider(),
        ]),
      ),
    );
  }

  // ── Блок 1: Ring ─────────────────────────────────────────────
  Widget _buildRing(double progress, int percent, int goalMl) {
    return AnimatedBuilder(
      animation: _ringAnim,
      builder: (_, __) => SizedBox(
        width: 200, height: 200,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 200, height: 200,
            child: CustomPaint(
              painter: _RingPainter(
                progress: (progress * _ringAnim.value).clamp(0.0, 1.5),
                bgColor: const Color(0xFFE0F2FE),
                fgColor: const Color(0xFF42A5F5),
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(_consumedMl / 1000).toStringAsFixed(1)} л',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 28,
                fontWeight: FontWeight.w800, color: Color(0xFF42A5F5))),
            Text('из ${_dailyGoalL.toStringAsFixed(1)} л',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('$percent%', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
              fontWeight: FontWeight.w700,
              color: percent >= 100 ? const Color(0xFF10B981) : const Color(0xFF42A5F5))),
          ]),
        ]),
      ),
    );
  }

  // ── Блок 2: Quick buttons ────────────────────────────────────
  // Spec: +150 мл / +250 мл / +500 мл / Свой объём
  Widget _buildQuickButtons() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Добавить воду', style: TextStyle(fontFamily: 'Inter',
        fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Row(children: [
        _waterBtn(150), const SizedBox(width: 10),
        _waterBtn(250), const SizedBox(width: 10),
        _waterBtn(500), const SizedBox(width: 10),
        _customWaterBtn(),
      ]),
    ]);
  }

  Widget _waterBtn(int ml) {
    return Expanded(child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addWater(ml),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.water_drop_outlined, size: 18, color: Color(0xFF42A5F5)),
            Text('+${ml}мл', style: const TextStyle(fontFamily: 'Inter',
              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF42A5F5))),
          ]),
        ),
      ),
    ));
  }

  Widget _customWaterBtn() {
    return Expanded(child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCustomInput,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF42A5F5)),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF42A5F5)),
            Text('Свой', style: TextStyle(fontFamily: 'Inter',
              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF42A5F5))),
          ]),
        ),
      ),
    ));
  }

  void _showCustomInput() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Свой объём', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(suffixText: 'мл', hintText: '100'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            final ml = int.tryParse(ctrl.text);
            if (ml != null && ml > 0) { _addWater(ml); Navigator.pop(ctx); }
          },
          child: const Text('Добавить'),
        ),
      ],
    ));
  }

  // ── Блок 3: Weekly chart ─────────────────────────────────────
  // Spec: 7 дней, пунктирная линия — цель
  Widget _buildWeekChart(int goalMl) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    final dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final maxVal = goalMl * 1.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Неделя', style: TextStyle(fontFamily: 'Inter', fontSize: 14,
          fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            ...days.asMap().entries.map((entry) {
              final key = entry.value;
              final ml = _weekData[key] ?? 0;
              final h = maxVal > 0 ? (ml / maxVal * 100).clamp(0.0, 100.0) : 0.0;
              final goalH = maxVal > 0 ? (goalMl / maxVal * 100).clamp(0.0, 100.0) : 0.0;
              final isToday = key == _todayKey();
              final dayIdx = DateTime.parse(key).weekday - 1;

              return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${(ml / 1000).toStringAsFixed(1)}', style: TextStyle(fontFamily: 'Inter',
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: isToday ? const Color(0xFF42A5F5) : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  width: 24,
                  height: h,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF42A5F5)
                        : (ml >= goalMl ? const Color(0xFF10B981).withValues(alpha: 0.6)
                            : const Color(0xFFE0F2FE)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(dayLabels[dayIdx], style: TextStyle(fontFamily: 'Inter',
                  fontSize: 11, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? const Color(0xFF42A5F5) : AppColors.textSecondary)),
              ]));
            }),
          ]),
        ),
      ]),
    );
  }

  // ── Блок 4: HC-совет ─────────────────────────────────────────
  Widget _buildTip() {
    final tipText = _consumedMl < 500
        ? 'Начни день со стакана воды! Это запустит метаболизм и улучшит концентрацию.'
        : _consumedMl < (_dailyGoalL * 1000 * 0.5)
            ? 'Половина нормы ещё впереди. Поставь напоминание каждый час!'
            : _consumedMl >= (_dailyGoalL * 1000)
                ? 'Отлично! Ты выполнил(а) дневную норму. Продолжай в том же духе!'
                : 'Хороший прогресс! Осталось ${((_dailyGoalL * 1000 - _consumedMl) / 1000).toStringAsFixed(1)} л до цели.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Expanded(child: Text(tipText, style: const TextStyle(fontFamily: 'Inter',
          fontSize: 13, color: Color(0xFF0369A1), height: 1.4))),
      ]),
    );
  }

  // ── Блок 5: Goal slider ──────────────────────────────────────
  // Spec: 1.0–4.0 л, шаг 0.1
  Widget _buildGoalSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Дневная норма', style: TextStyle(fontFamily: 'Inter',
          fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Text('${_dailyGoalL.toStringAsFixed(1)} л', style: const TextStyle(
            fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800,
            color: Color(0xFF42A5F5))),
          const Spacer(),
          Text('(${(_dailyGoalL * 1000).toInt()} мл)', style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
        ]),
        Slider(
          value: _dailyGoalL,
          min: 1.0, max: 4.0, divisions: 30,
          activeColor: const Color(0xFF42A5F5),
          onChanged: (v) => _setGoal((v * 10).round() / 10),
        ),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1.0 л', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
            color: AppColors.textSecondary)),
          Text('4.0 л', style: TextStyle(fontFamily: 'Inter', fontSize: 11,
            color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  _RingPainter({required this.progress, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final strokeWidth = 14.0;

    // Background arc
    canvas.drawCircle(center, radius,
      Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth);

    // Foreground arc
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, sweep,
      false,
      Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
