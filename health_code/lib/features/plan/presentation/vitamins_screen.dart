// lib/features/plan/presentation/vitamins_screen.dart
// P-5: Расписание витаминов и БАДов
// screens-map.md spec:
//   Доступ: Black+ (White → замок)
//   Блок 1 — Временные карточки (Утро / День / Вечер)
//   Блок 2 — Совместимость (Black: базовые, Gold: расширенные)
//   Считывает: current_supplements_text, blood_tests, subscription_plan

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/core/widgets/status_gate.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';

class VitaminsScreen extends ConsumerWidget {
  const VitaminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Витамины и БАД', style: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StatusGate(
        requiredTier: RequiredTier.black,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // User supplements info
            if (profile.supplements != null && profile.supplements!.isNotEmpty)
              _infoCard(
                icon: Icons.medication_outlined,
                color: const Color(0xFF6366F1),
                title: 'Твои текущие БАД',
                body: profile.supplements!,
              ),
            const SizedBox(height: 16),

            // ── Блок 1: Временные карточки ────────────────────────
            _timeSlot(
              title: 'Утро',
              icon: Icons.wb_sunny_outlined,
              color: const Color(0xFFF59E0B),
              items: _morningVitamins(profile),
            ),
            const SizedBox(height: 12),
            _timeSlot(
              title: 'День',
              icon: Icons.light_mode_outlined,
              color: const Color(0xFF10B981),
              items: _afternoonVitamins(profile),
            ),
            const SizedBox(height: 12),
            _timeSlot(
              title: 'Вечер',
              icon: Icons.nights_stay_outlined,
              color: const Color(0xFF6366F1),
              items: _eveningVitamins(profile),
            ),
            const SizedBox(height: 24),

            // ── Блок 2: Совместимость ────────────────────────────
            _compatibilitySection(ref),
          ]),
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required Color color,
      required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
          color: AppColors.textSecondary, height: 1.4)),
      ]),
    );
  }

  Widget _timeSlot({required String title, required IconData icon,
      required Color color, required List<_VitaminItem> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 16,
            fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('Нет рекомендаций на это время', style: TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: const TextStyle(fontFamily: 'Inter',
                  fontSize: 14, fontWeight: FontWeight.w600)),
                Row(children: [
                  Text(item.dosage, style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 12, color: AppColors.textSecondary)),
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6)),
                      child: Text(item.note, style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95))),
                    ),
                  ],
                ]),
              ])),
            ]),
          )),
      ]),
    );
  }

  // ── Compatibility warnings ──────────────────────────────────
  Widget _compatibilitySection(WidgetRef ref) {
    final warnings = _getCompatibilityWarnings();
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF59E0B)),
        SizedBox(width: 8),
        Text('Совместимость', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
          fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      ...warnings.map((w) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(child: Text(w, style: const TextStyle(fontFamily: 'Inter',
            fontSize: 13, color: Color(0xFF92400E), height: 1.4))),
        ]),
      )),

      // Gold: extended recommendations
      StatusGate(
        requiredTier: RequiredTier.gold,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF4C1D95).withValues(alpha: 0.08),
                       const Color(0xFFE85D04).withValues(alpha: 0.04)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome_outlined, size: 16, color: Color(0xFF4C1D95)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Gold-рекомендация: Принимай железо утром натощак, через 2 часа после кальция. '
              'Витамин C усиливает усвоение железа — добавь цитрусовые к завтраку.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                color: Color(0xFFB45309), height: 1.4))),
          ]),
        ),
      ),
    ]);
  }

  // ── Data generation (based on profile supplements) ──────────
  List<_VitaminItem> _morningVitamins(dynamic profile) {
    final items = <_VitaminItem>[
      const _VitaminItem('Витамин D3', '2000 МЕ', 'после еды'),
      const _VitaminItem('Омега-3', '1000 мг', 'с жирной пищей'),
    ];
    // If user has B12 deficiency in blood tests
    final bloodTests = profile.bloodTests as String? ?? '';
    if (bloodTests.toLowerCase().contains('b12') || bloodTests.toLowerCase().contains('анемия')) {
      items.add(const _VitaminItem('Витамин B12', '1000 мкг', 'натощак'));
    } else {
      items.add(const _VitaminItem('Витамин B12', '500 мкг', 'натощак'));
    }
    return items;
  }

  List<_VitaminItem> _afternoonVitamins(dynamic profile) {
    final items = <_VitaminItem>[
      const _VitaminItem('Магний', '400 мг', 'после еды'),
    ];
    // If user supplementing with iron (from supplements text)
    final supText = (profile.supplements as String? ?? '').toLowerCase();
    if (supText.contains('железо') || supText.contains('iron')) {
      items.add(const _VitaminItem('Железо', '18 мг', 'натощак'));
      items.add(const _VitaminItem('Витамин C', '500 мг', 'вместе с железом'));
    } else {
      items.add(const _VitaminItem('Витамин C', '500 мг', ''));
    }
    return items;
  }

  List<_VitaminItem> _eveningVitamins(dynamic profile) => [
    const _VitaminItem('Кальций', '600 мг', 'после ужина'),
    const _VitaminItem('Цинк', '15 мг', 'за 1ч до сна'),
  ];

  List<String> _getCompatibilityWarnings() {
    final warnings = <String>[];
    // Core incompatibility rules (evidence-based)
    warnings.add('Кальций и Железо — принимай раздельно (интервал 2+ часа)');
    warnings.add('Витамин D и Кальций — принимай вместе для лучшего усвоения');
    warnings.add('Цинк и Медь — конкурируют за усвоение, не совмещай');
    warnings.add('Магний и Кальций — не принимай одновременно');
    return warnings;
  }
}

class _VitaminItem {
  final String name;
  final String dosage;
  final String note;
  const _VitaminItem(this.name, this.dosage, this.note);
}
