// lib/features/onboarding/presentation/o7_womens_health_screen.dart
// O-7: Лекарства и женское здоровье (conditional — только женщины)
// Выпадающая секция для женских особенностей

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/hc_expandable_section.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';

class O7WomensHealthScreen extends ConsumerStatefulWidget {
  const O7WomensHealthScreen({super.key});

  @override
  ConsumerState<O7WomensHealthScreen> createState() => _O7WomensHealthScreenState();
}

class _O7WomensHealthScreenState extends ConsumerState<O7WomensHealthScreen> {
  bool? _takesMedications;
  final _medicationsCtrl = TextEditingController();
  final Set<String> _womensHealth = {};

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.takesMedications != null) {
      _takesMedications = p.takesMedications == 'yes';
      if (p.medications != null) _medicationsCtrl.text = p.medications!;
    }
    if (p.womensHealth.isNotEmpty) _womensHealth.addAll(p.womensHealth);
    _medicationsCtrl.addListener(() => setState(() {}));
  }

  bool get _isValid {
    if (_takesMedications == true && _medicationsCtrl.text.trim().isEmpty) return false;
    return true;
  }

  void _toggleWH(String key) {
    setState(() {
      if (key == 'none') { _womensHealth.clear(); _womensHealth.add('none'); }
      else { _womensHealth.remove('none'); if (_womensHealth.contains(key)) {
        _womensHealth.remove(key);
      } else {
        _womensHealth.add(key);
      } }
    });
  }

  void _saveData() {
    ref.read(profileNotifierProvider.notifier).saveFields({
      'takes_medications': _takesMedications == true ? 'yes' : (_takesMedications == false ? 'no' : null),
      if (_takesMedications == true) 'medications': _medicationsCtrl.text.trim(),
      'womens_health': _womensHealth.toList(),
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (GoRouterState.of(context).uri.queryParameters["fromSummary"] == "true") return;
    if (mounted) context.go(Routes.o8MealPattern);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _medicationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final hidePregnancy = profile.goal == 'weight_loss';
    final step = profile.goal == 'weight_loss' ? 6 : 5;
    final total = profile.goal == 'weight_loss' ? 14 : 13;

    final whOptions = <(String, String)>[
      if (!hidePregnancy) ('pregnancy', 'Беременность'),
      if (!hidePregnancy) ('breastfeeding', 'Кормление грудью'),
      ('menopause', 'Менопауза или перименопауза'),
      ('irregular_cycle', 'Нерегулярный цикл'),
      ('pcos', 'СПКЯ'),
      ('none', 'Нет особенностей'),
    ];

    return OnboardingScaffold(
      title: 'Женское здоровье',
      subtitle: 'Учтём особенности твоего организма',
      step: step,
      totalSteps: total,
      isValid: _isValid,
      onBack: () => context.go(Routes.o6Health),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Лекарства — чекбокс
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _takesMedications = !(_takesMedications ?? false);
              if (_takesMedications == false) _medicationsCtrl.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (_takesMedications == true) ? const Color(0xFFFFF7ED) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_takesMedications == true) ? AppColors.primary : const Color(0xFFE5E7EB),
                  width: (_takesMedications == true) ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: (_takesMedications == true) ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (_takesMedications == true) ? AppColors.primary : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: (_takesMedications == true)
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Принимаю лекарства постоянно',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
          if (_takesMedications == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _medicationsCtrl,
              decoration: const InputDecoration(
                hintText: 'Название препарата...',
                helperText: 'Некоторые продукты влияют на действие лекарств',
              ),
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 20),

          // Женское здоровье (выпадающий список)
          HcExpandableSection(
            title: 'Особенности, которые важно учесть',
            options: whOptions,
            selected: _womensHealth,
            onToggle: _toggleWH,
            exclusiveKey: 'none',
          ),
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'При менопаузе критичен кальций и витамин D. При СПКЯ — контроль инсулина. При лактации — калорийность и омега-3. Мы подстроим план под твой этап жизни.',
      ),
    );
  }
}
