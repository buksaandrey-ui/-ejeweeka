// lib/features/onboarding/presentation/o13_supplements_screen.dart
// O-13: Витамины и БАДы
// screens-map.md:
//   Блок 1: «Принимаешь ли сейчас витамины или БАДы?» — Нет/Да → текстовое поле
//   Блок 2: «Готов(а) рассматривать витамины или БАДы?» — 4 варианта
//   Передаётся: currently_takes_supplements, current_supplements_text, supplement_openness

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/utils/input_formatter.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';

class O13SupplementsScreen extends ConsumerStatefulWidget {
  const O13SupplementsScreen({super.key});

  @override
  ConsumerState<O13SupplementsScreen> createState() => _O13SupplementsScreenState();
}

class _O13SupplementsScreenState extends ConsumerState<O13SupplementsScreen> {
  bool? _takes;
  final List<String> _supplementsList = [];
  final _supplementsCtrl = TextEditingController();
  final _supplementsFocus = FocusNode();
  String? _openness;

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.supplementOpenness != null) _openness = p.supplementOpenness;
    if (p.currentlyTakesSupplements) {
      _takes = true;
      if (p.supplements != null && p.supplements!.isNotEmpty) {
        final parts = p.supplements!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        _supplementsList.addAll(parts);
      }
    } else if (p.supplementOpenness != null) {
      _takes = false;
    }
  }

  bool get _isValid => _takes != null && _openness != null;

  void _addSupplement(String text) {
    final formatted = InputFormatter.formatHealthData(text);
    if (formatted.isEmpty || _supplementsList.contains(formatted)) return;
    setState(() {
      _supplementsList.add(formatted);
      _supplementsCtrl.clear();
    });
    _save();
  }

  void _removeSupplement(String text) {
    setState(() {
      _supplementsList.remove(text);
    });
    _save();
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    await _save();
    if (mounted) context.go(Routes.o14Motivation);
  }

  Future<void> _save() async {
    await ref.read(profileNotifierProvider.notifier).saveFields({
      'currently_takes_supplements': _takes == true,
      'supplements': (_takes == true && _supplementsList.isNotEmpty)
          ? _supplementsList.join(', ')
          : null,
      'supplement_openness': _openness,
    });
  }

  @override
  void dispose() {
    try { _save(); } catch (_) {}
    _supplementsCtrl.dispose();
    _supplementsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Витамины и БАДы',
      subtitle: 'Текущие добавки и готовность к рекомендациям',
      step: isWeightLoss ? 12 : 11,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o12BloodTests),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Block 1: Текущий приём ──────────────────────────
          _sectionLabel('Текущий приём'),
          const SizedBox(height: 6),
          const Text('Принимаешь ли сейчас витамины или БАДы?',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _yesNoBtn('Нет', false)),
            const SizedBox(width: 10),
            Expanded(child: _yesNoBtn('Да', true)),
          ]),
          if (_takes == true) ...[
            if (_supplementsList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _supplementsList.map((s) => _customChip(s, () => _removeSupplement(s))).toList(),
              ),
            ],
            const SizedBox(height: 12),
            _customInputField(
              controller: _supplementsCtrl,
              focusNode: _supplementsFocus,
              hint: 'Витамин D, омега-3, магний...',
              onSubmit: _addSupplement,
            ),
          ],

          // ── Block 2: Готовность ─────────────────────────────
          const SizedBox(height: 24),
          _sectionLabel('Готовность'),
          const SizedBox(height: 6),
          const Text(
              'Готов(а) рассматривать витамины или БАДы для закрытия дефицитов?',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ..._opennessOptions.map((o) {
            final sel = _openness == o.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _openness = o.$1);
                  _save();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFFF7ED) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
                        width: sel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Text(o.$2,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textPrimary))),
                    if (sel)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Время приёма витаминов важно так же, как их выбор. '
            'Магний расслабляет мышцы — лучше вечером. '
            'Железо блокируется кальцием и кофе — принимать отдельно. '
            'Витамин D усваивается только с жиром — в обед или ужин, не натощак. '
            'Мы составим расписание приёма так, чтобы каждая добавка работала по-настоящему.',
      ),
    );
  }

  static const _opennessOptions = [
    ('yes_select', 'Да, подберите что нужно'),
    ('yes_understand', 'Скорее да, но хочу понимать зачем'),
    ('only_necessary', 'Только если действительно необходимо'),
    ('no', 'Нет, предпочитаю без добавок'),
  ];

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
      style: const TextStyle(
          fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.8));

  Widget _yesNoBtn(String label, bool value) {
    final sel = _takes == value;
    return GestureDetector(
      onTap: () {
        setState(() => _takes = value);
        _save();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
              width: sel ? 1.5 : 1),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
                    color: sel ? AppColors.primary : AppColors.textPrimary))),
      ),
    );
  }

  Widget _customInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required void Function(String) onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (val) { onSubmit(val); focusNode.requestFocus(); },
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.primary),
            onPressed: () { onSubmit(controller.text); focusNode.requestFocus(); },
          ),
        ],
      ),
    );
  }

  Widget _customChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        const SizedBox(width: 6),
        GestureDetector(onTap: onRemove, child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.6))),
      ]),
    );
  }
}
