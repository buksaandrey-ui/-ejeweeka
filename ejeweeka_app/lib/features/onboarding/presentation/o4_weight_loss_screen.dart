// lib/features/onboarding/presentation/o4_weight_loss_screen.dart
// O-4: Ветка похудения (conditional)
// screens-map.md spec:
//   Шаг 3/14. Целевой вес + срок + классификация темпа.
//   Плашка-предупреждение по темпу (safe/accelerated/aggressive/impossible)
//   Передаётся: target_weight, target_timeline_weeks, pace_classification

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/core/utils/bmr_calculator.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';
import 'package:ejeweeka_app/shared/widgets/hc_number_picker_field.dart';

class O4WeightLossScreen extends ConsumerStatefulWidget {
  const O4WeightLossScreen({super.key});

  @override
  ConsumerState<O4WeightLossScreen> createState() => _O4WeightLossScreenState();
}

class _O4WeightLossScreenState extends ConsumerState<O4WeightLossScreen> {
  final _targetWeightCtrl = TextEditingController();
  final _weeksCtrl = TextEditingController();

  String? _paceClass;
  double? _weeklyLoss;
  double? _weeklyPercent;
  bool _riskAccepted = false;

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.targetWeight != null) _targetWeightCtrl.text = p.targetWeight!.toStringAsFixed(1);
    if (p.targetTimelineWeeks != null) _weeksCtrl.text = p.targetTimelineWeeks.toString();
    _paceClass = p.paceClassification;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPace());
  }

  bool get _isValid {
    final tw = double.tryParse(_targetWeightCtrl.text);
    final wk = int.tryParse(_weeksCtrl.text);
    if (tw == null || wk == null || wk <= 0) return false;
    if (_paceClass == 'impossible') return false;
    if (_paceClass == 'aggressive' || _paceClass == 'accelerated') return _riskAccepted;
    return true; // safe
  }

  void _recalcPace() {
    final profile = ref.read(profileProvider);
    final current = profile.weight ?? 0;
    final target = double.tryParse(_targetWeightCtrl.text);
    final weeks = int.tryParse(_weeksCtrl.text);
    if (target != null && weeks != null && weeks > 0 && current > 0) {
      final pace = BmrCalculator.classifyWeightLossPace(
        currentWeight: current, targetWeight: target, timelineWeeks: weeks,
      );
      final wl = (current - target) / weeks;
      final wp = current > 0 ? (wl / current) * 100 : 0.0;
      setState(() {
        _paceClass = pace;
        _weeklyLoss = wl;
        _weeklyPercent = wp;
        _riskAccepted = false; // Сброс при пересчёте
      });
    } else {
      setState(() { _paceClass = null; _weeklyLoss = null; _weeklyPercent = null; _riskAccepted = false; });
    }
  }

  /// Пересчёт срока под целевой % потери веса
  void _recalcToPercent(double targetPercent) {
    final profile = ref.read(profileProvider);
    final current = profile.weight ?? 0;
    final target = double.tryParse(_targetWeightCtrl.text) ?? current;
    if (current <= target) return;
    final totalKg = current - target;
    final weeklyKg = current * targetPercent / 100;
    final newWeeks = (totalKg / weeklyKg).ceil();
    setState(() { _weeksCtrl.text = newWeeks.toString(); });
    _recalcPace();
    _saveData();
  }

  String _targetDateStr() {
    final wk = int.tryParse(_weeksCtrl.text);
    if (wk == null || wk <= 0) return '';
    final d = DateTime.now().add(Duration(days: wk * 7));
    const months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _saveData() {
    ref.read(profileNotifierProvider.notifier).saveFields({
      'target_weight': _targetWeightCtrl.text.trim().isEmpty ? null : _targetWeightCtrl.text.trim(),
      'target_timeline_weeks': _weeksCtrl.text.trim().isEmpty ? null : _weeksCtrl.text.trim(),
      'pace_classification': _paceClass,
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (mounted) context.go(Routes.o5Restrictions);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _targetWeightCtrl.dispose();
    _weeksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final currentWeight = profile.weight;

    return OnboardingScaffold(
      title: 'Твоя цель по весу',
      subtitle: 'Рассчитаем безопасный темп для твоего тела',
      step: 3,
      totalSteps: 14,
      isValid: _isValid,
      onBack: () => context.go(Routes.o3Profile),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentWeight != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text('Текущий вес: ${currentWeight.toStringAsFixed(1)} кг',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          HcNumberPickerField(
            controller: _targetWeightCtrl, labelText: 'Желаемый вес', hintText: '65',
            suffixText: 'кг', min: 40, max: 250, step: 0.5, isDecimal: true,
            onChanged: (_) { setState(() {}); _recalcPace(); _saveData(); },
          ),
          const SizedBox(height: 12),
          HcNumberPickerField(
            controller: _weeksCtrl, labelText: 'За какой срок?', hintText: '12',
            suffixText: 'недель', helperText: 'Примерно 3 месяца = 13 недель',
            min: 1, max: 100, step: 1, isDecimal: false,
            onChanged: (_) { setState(() {}); _recalcPace(); _saveData(); },
          ),
          const SizedBox(height: 16),
          if (_paceClass != null) _paceBadge(),
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Нет «правильной» скорости — есть твоя. Мы рассчитаем безопасный коридор под твою цель и покажем, что реалистично, а что — риск для здоровья.',
      ),
    );
  }

  Widget _paceBadge() {
    final profile = ref.read(profileProvider);
    final current = profile.weight ?? 0;
    final target = double.tryParse(_targetWeightCtrl.text) ?? 0;
    final weeks = int.tryParse(_weeksCtrl.text) ?? 0;
    final totalKg = current - target;
    final pctStr = _weeklyPercent != null ? '~${_weeklyPercent!.toStringAsFixed(1)}%/нед' : '';

    if (_paceClass == 'impossible') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF9A9A)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🟠 СТОП! НЕВОЗМОЖНЫЙ ТЕМП', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFD32F2F))),
            const Spacer(),
            Text(pctStr, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F))),
          ]),
          const SizedBox(height: 8),
          Text('Цель: минус ${totalKg.toStringAsFixed(1)} кг за $weeks нед. Достигнешь цели к ${_targetDateStr()}.',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 8),
          const Text('Безопасное похудение не может превышать 1.7% массы тела в неделю. Потеря большего веса возможна только за счёт воды и мышц при истощении организма. Необходимо увеличить срок!',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFD32F2F), height: 1.4)),
          const SizedBox(height: 12),
          const Text('Тебе необходимо увеличить срок для продолжения!',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _recalcButton('Сделать приемлемым (~1.5%/нед)', const Color(0xFFFFF3E0), const Color(0xFFF09030), () => _recalcToPercent(1.5)),
          const SizedBox(height: 8),
          _recalcButton('⚠ Сделать безопасным (~1.0%/нед)', const Color(0xFFE8F5E9), const Color(0xFF52B044), () => _recalcToPercent(1.0)),
        ]),
      );
    }

    if (_paceClass == 'aggressive') {
      return _riskBadge(
        title: '⚠ АГРЕССИВНЫЙ ТЕМП',
        pct: pctStr,
        color: const Color(0xFFF44336),
        bg: const Color(0xFFFFEBEE),
        desc: '1.4–1.7% в неделю — высокий риск потери мышечной массы. Рекомендуем увеличить срок.',
        totalKg: totalKg,
        weeks: weeks,
      );
    }

    if (_paceClass == 'accelerated') {
      return _riskBadge(
        title: '⚡ УСКОРЕННЫЙ ТЕМП',
        pct: pctStr,
        color: const Color(0xFFF09030),
        bg: const Color(0xFFFFF3E0),
        desc: '1.1–1.3% в неделю — допустимо при хорошем самочувствии и контроле.',
        totalKg: totalKg,
        weeks: weeks,
      );
    }

    // Safe
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF52B044), size: 20),
          const SizedBox(width: 8),
          const Text('Безопасный темп', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF52B044))),
          const Spacer(),
          Text(pctStr, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF52B044))),
        ]),
        const SizedBox(height: 4),
        const Text('До 1% от веса в неделю — идеально', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
        if (_weeklyLoss != null && _weeklyLoss! > 0) ...[
          const SizedBox(height: 4),
          Text('Темп: ~${_weeklyLoss!.toStringAsFixed(2)} кг/нед. Цель к ${_targetDateStr()}.',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
        ],
      ]),
    );
  }

  Widget _riskBadge({required String title, required String pct, required Color color, required Color bg,
    required String desc, required double totalKg, required int weeks}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: color))),
          Text(pct, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        Text('Цель: минус ${totalKg.toStringAsFixed(1)} кг за $weeks нед. К ${_targetDateStr()}.',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: 6),
        Text(desc, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: color, height: 1.4)),
        const SizedBox(height: 10),
        _recalcButton('Сделать безопасным (~0.8%/нед)', const Color(0xFFE8F5E9), const Color(0xFF52B044), () => _recalcToPercent(0.8)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _riskAccepted = !_riskAccepted),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _riskAccepted ? color : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _riskAccepted ? color : const Color(0xFFCCCCCC), width: 1.5),
              ),
              child: _riskAccepted ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Понимаю риски, хочу продолжить с текущим темпом',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                color: _riskAccepted ? color : AppColors.textSecondary))),
          ]),
        ),
      ]),
    );
  }

  Widget _recalcButton(String label, Color bg, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.4))),
        child: Center(child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: textColor))),
      ),
    );
  }
}
