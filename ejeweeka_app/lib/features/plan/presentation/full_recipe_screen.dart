// lib/features/plan/presentation/full_recipe_screen.dart
// P-4: Полный рецепт — пошаговое приготовление с таймерами
// Спека: screens-map.md §P-4
//   Блок 1 — Ингредиенты с чекбоксами
//   Блок 2 — Нумерованные шаги с таймерами
//   Доступ: Black+ (White → редирект на P-2 с баннером)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';

class FullRecipeScreen extends ConsumerStatefulWidget {
  final MealItem meal;
  const FullRecipeScreen({super.key, required this.meal});

  @override
  ConsumerState<FullRecipeScreen> createState() => _FullRecipeScreenState();
}

class _FullRecipeScreenState extends ConsumerState<FullRecipeScreen> {
  late List<bool> _ingredientChecked;
  late List<bool> _stepDone;
  int _activeTimerStep = -1;
  int _timerSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ingredientChecked = List.filled(widget.meal.ingredients.length, false);
    _stepDone = List.filled(widget.meal.steps.length, false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int stepIndex, int minutes) {
    _timer?.cancel();
    setState(() {
      _activeTimerStep = stepIndex;
      _timerSeconds = minutes * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 0) {
        t.cancel();
        setState(() => _activeTimerStep = -1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('⏰ Шаг ${stepIndex + 1} — время вышло!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ));
        }
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _checkedIngredients => _ingredientChecked.where((c) => c).length;
  int get _completedSteps => _stepDone.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    // Access: Black+ only
    if (!hasStatusAccess(ref, RequiredTier.black)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background, elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
          title: const Text('Рецепт',
            style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Полные рецепты', style: TextStyle(fontFamily: 'Inter',
            fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Доступны со статусом Black и выше',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Назад', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ])),
      );
    }

    final allDone = _completedSteps == widget.meal.steps.length &&
        _checkedIngredients == widget.meal.ingredients.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: Text(widget.meal.name,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Progress indicator ──────────────────────────────────
          _progressHeader(),
          const SizedBox(height: 20),

          // ── Блок 1: Ингредиенты с чекбоксами ───────────────────
          _buildIngredients(),
          const SizedBox(height: 24),

          // ── Блок 2: Пошаговые инструкции с таймерами ────────────
          _buildSteps(),
          const SizedBox(height: 24),

          // ── Кнопка «Готово» ─────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ ${widget.meal.name} приготовлено!'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2)));
              },
              icon: Icon(allDone ? Icons.check_circle_rounded : Icons.arrow_back_rounded, size: 18),
              label: Text(allDone ? 'Готово!' : 'Вернуться',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: allDone ? const Color(0xFF10B981) : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _progressHeader() {
    final total = widget.meal.ingredients.length + widget.meal.steps.length;
    final done = _checkedIngredients + _completedSteps;
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Row(children: [
          Text('${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800,
              color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.meal.prepTimeMin} мин',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
            Text('$done из $total шагов',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ])),
          if (_activeTimerStep >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Text(_formatTimer(_timerSeconds),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16,
                  fontWeight: FontWeight.w800, color: Colors.white)),
            ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ]),
    );
  }

  Widget _buildIngredients() {
    if (widget.meal.ingredients.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.shopping_basket_outlined, size: 18, color: Color(0xFF6B7280)),
        const SizedBox(width: 8),
        const Text('Ингредиенты', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('$_checkedIngredients/${widget.meal.ingredients.length}',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
            color: _checkedIngredients == widget.meal.ingredients.length
                ? const Color(0xFF10B981) : AppColors.textSecondary)),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: widget.meal.ingredients.asMap().entries.map((entry) {
            final i = entry.key;
            final ing = entry.value;
            final name = ing['name'] ?? ing['ingredient'] ?? '';
            final amount = ing['amount'] ?? ing['quantity'] ?? '';
            final checked = _ingredientChecked[i];
            return InkWell(
              onTap: () => setState(() => _ingredientChecked[i] = !_ingredientChecked[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: checked ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: checked ? const Color(0xFF10B981) : const Color(0xFFD1D5DB), width: 2),
                    ),
                    child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name.toString(),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: checked ? AppColors.textSecondary : AppColors.textPrimary))),
                  Text(amount.toString(), style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildSteps() {
    if (widget.meal.steps.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF6B7280)),
        const SizedBox(width: 8),
        const Text('Приготовление', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('$_completedSteps/${widget.meal.steps.length}',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
            color: _completedSteps == widget.meal.steps.length
                ? const Color(0xFF10B981) : AppColors.textSecondary)),
      ]),
      const SizedBox(height: 12),
      ...widget.meal.steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final desc = step['description'] ?? step['step'] ?? '';
        final duration = step['duration'];
        final done = _stepDone[i];
        final isTimerActive = _activeTimerStep == i;

        // Parse duration minutes for timer
        int? durationMin;
        if (duration != null && duration.toString().isNotEmpty) {
          durationMin = int.tryParse(duration.toString().replaceAll(RegExp(r'[^\d]'), ''));
        }

        return GestureDetector(
          onTap: () => setState(() => _stepDone[i] = !_stepDone[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: done ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: done ? const Color(0xFF86EFAC)
                    : isTimerActive ? AppColors.primary
                    : const Color(0xFFE5E7EB),
                width: isTimerActive ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Step number
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: done
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFFE85D04)]),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : Text('${i + 1}', style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(desc.toString(), style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5,
                  color: done ? AppColors.textSecondary : AppColors.textPrimary)),
                if (duration != null && duration.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    // Duration badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF4C1D95)),
                        const SizedBox(width: 4),
                        Text(duration.toString(), style: const TextStyle(fontFamily: 'Inter',
                          fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95))),
                      ]),
                    ),
                    // Timer button
                    if (durationMin != null && durationMin > 0) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _startTimer(i, durationMin!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isTimerActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(isTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 14, color: isTimerActive ? Colors.white : AppColors.primary),
                            const SizedBox(width: 4),
                            Text(isTimerActive ? _formatTimer(_timerSeconds) : 'Таймер',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                                color: isTimerActive ? Colors.white : AppColors.primary)),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ],
              ])),
            ]),
          ),
        );
      }),
    ]);
  }
}
