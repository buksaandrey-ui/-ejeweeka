// lib/features/onboarding/presentation/o6_health_screen.dart
// O-6: Здоровье — симптомы и хронические состояния
// Выпадающие секции для снижения визуальной перегруженности

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/data/profile_repository.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/shared/utils/input_formatter.dart';
import 'package:health_code/shared/widgets/hc_expandable_section.dart';
import 'package:health_code/shared/widgets/motivating_tip_card.dart';
import 'package:health_code/shared/widgets/onboarding_scaffold.dart';

class O6HealthScreen extends ConsumerStatefulWidget {
  const O6HealthScreen({super.key});

  @override
  ConsumerState<O6HealthScreen> createState() => _O6HealthScreenState();
}

class _O6HealthScreenState extends ConsumerState<O6HealthScreen> {
  final Set<String> _symptoms = {};
  final Set<String> _diseases = {};
  final _medicationsCtrl = TextEditingController();
  bool? _takesMedications;

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.symptoms.isNotEmpty) _symptoms.addAll(p.symptoms);
    if (p.diseases.isNotEmpty) _diseases.addAll(p.diseases);
    if (p.takesMedications != null) {
      _takesMedications = p.takesMedications == 'yes';
      if (p.medications != null) _medicationsCtrl.text = p.medications!;
    }
    _medicationsCtrl.addListener(() => setState(() {}));
  }

  bool get _isValid {
    if (ref.read(profileProvider).gender == 'male' && _takesMedications == true && _medicationsCtrl.text.trim().isEmpty) return false;
    return true;
  }

  void _toggleSymptom(String key) {
    setState(() {
      if (key == 'no_symptoms') { _symptoms.clear(); _symptoms.add('no_symptoms'); }
      else { _symptoms.remove('no_symptoms'); if (_symptoms.contains(key)) _symptoms.remove(key); else _symptoms.add(key); }
    });
  }

  void _toggleDisease(String key) {
    setState(() {
      if (key == 'no_disease') { _diseases.clear(); _diseases.add('no_disease'); }
      else { _diseases.remove('no_disease'); if (_diseases.contains(key)) _diseases.remove(key); else _diseases.add(key); }
    });
  }

  void _saveData() {
    final profile = ref.read(profileProvider);
    ref.read(profileNotifierProvider.notifier).saveFields({
      'symptoms': _symptoms.toList(),
      'diseases': _diseases.toList(),
      'o6_visited': 'true',
      if (profile.gender == 'male' && _takesMedications != null)
        'takes_medications': _takesMedications! ? 'yes' : 'no',
      if (profile.gender == 'male' && _takesMedications == true)
        'medications': InputFormatter.formatHealthData(_medicationsCtrl.text),
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    final profile = ref.read(profileProvider);
    if (!mounted) return;
    if (profile.gender == 'female') {
      context.go(Routes.o7WomensHealth);
    } else {
      context.go(Routes.o8MealPattern);
    }
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _medicationsCtrl.dispose();
    super.dispose();
  }

  static const _symptomItems = <(String, String)>[
    ('bloating', 'Газообразование / вздутие живота'),
    ('heartburn', 'Изжога / повышенная кислотность'),
    ('heaviness', 'Тяжесть после еды'),
    ('constipation', 'Запоры'),
    ('unstable_stool', 'Нестабильный стул'),
    ('abdominal_pain', 'Боли или спазмы'),
    ('sugar_cravings', 'Тяга к сладкому'),
    ('overeating', 'Сильный голод / переедание'),
    ('edema', 'Отёки'),
    ('chronic_fatigue', 'Хроническая усталость'),
    ('no_symptoms', 'Нет выраженных жалоб'),
  ];

  static const _diseaseItems = <(String, String)>[
    ('diabetes_2', 'Особенности углеводного обмена (2 тип)'),
    ('diabetes_1', 'Особенности углеводного обмена (1 тип)'),
    ('prediabetes', 'Преддиабет'),
    ('insulin_resistance', 'Инсулинорезистентность'),
    ('high_cholesterol', 'Повышенный холестерин'),
    ('hypertension', 'Гипертония'),
    ('thyroid', 'Особенности щитовидной железы'),
    ('gi_disease', 'Особенности ЖКТ'),
    ('kidney_disease', 'Особенности работы почек'),
    ('gout', 'Подагра'),
    ('no_disease', 'Нет или не знаю'),
    ('other_disease', 'Другое'),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isMale = profile.gender == 'male';
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Состояние здоровья',
      subtitle: 'Для безопасных и точных рекомендаций',
      step: isWeightLoss ? 5 : 4,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o5Restrictions),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Симптомы (выпадающий список) ────────────────────────
          HcExpandableSection(
            title: 'Симптомы',
            options: _symptomItems,
            selected: _symptoms,
            onToggle: _toggleSymptom,
            exclusiveKey: 'no_symptoms',
          ),

          const SizedBox(height: 14),

          // ── Хронические состояния (выпадающий список) ───────────
          HcExpandableSection(
            title: 'Хронические состояния',
            options: _diseaseItems,
            selected: _diseases,
            onToggle: _toggleDisease,
            exclusiveKey: 'no_disease',
          ),

          // ── Лекарства (только для мужчин) ──────────────────────
          if (isMale) ...[
            const SizedBox(height: 20),
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
                decoration: const InputDecoration(hintText: 'Название препарата...'),
                maxLines: 2,
              ),
            ],
          ],
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Вздутие, усталость, тяга к сладкому — часто это не характер, а сигналы организма. Чем точнее ты опишешь симптомы — тем точнее план.',
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));
}

