// lib/features/onboarding/presentation/o3_profile_screen.dart
// O-3: Базовый профиль
// screens-map.md spec:
//   Шаг 2/14. Имя, пол, возраст, рост, вес, телосложение, обхват талии.
//   Авторасчёт: ИМТ, BMR, waist_to_height, bmi_class
//   Условный вопрос-развилка (кроме weight_loss/muscle_gain):
//     «Хотел(а) бы также снизить вес?» → Да → O-4, Нет → O-5

import 'package:flutter/material.dart';
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

class O3ProfileScreen extends ConsumerStatefulWidget {
  const O3ProfileScreen({super.key});

  @override
  ConsumerState<O3ProfileScreen> createState() => _O3ProfileScreenState();
}

class _O3ProfileScreenState extends ConsumerState<O3ProfileScreen> {
  final _nameCtrl = TextEditingController();
  String? _gender; // 'male' | 'female'
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();

  // Для развилки (если цель не weight_loss / muscle_gain)
  bool? _wantsToLoseWeight;

  // Computed
  double? _bmi;
  String? _bmiClass;
  double? _bmr;

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.name != null)   _nameCtrl.text   = p.name!;
    if (p.gender != null) _gender          = p.gender;
    if (p.age != null)    _ageCtrl.text    = p.age.toString();
    if (p.height != null) _heightCtrl.text = p.height!.toStringAsFixed(0);
    if (p.weight != null) _weightCtrl.text = p.weight!.toStringAsFixed(1);
    if (p.waist != null) {
      _waistCtrl.text = p.waist!.toStringAsFixed(0);
    }
    // Гидрация выбора «Хотел(а) бы снизить вес?»
    // Проверяем, был ли хоть какой-то выбор сохранён ранее
    final raw = ProfileRepository.getRawJson();
    if (raw.containsKey('wants_to_lose_weight')) {
      _wantsToLoseWeight = p.wantsToLoseWeight;
    }
    // Пересчитываем метрики
    _recalculate();
  }

  bool get _isValid {
    final hasBasics = _nameCtrl.text.trim().isNotEmpty &&
        _gender != null &&
        _ageCtrl.text.isNotEmpty &&
        _heightCtrl.text.isNotEmpty &&
        _weightCtrl.text.isNotEmpty;

    if (!hasBasics) return false;
    
    final profile = ref.read(profileProvider);
    final a = int.tryParse(_ageCtrl.text) ?? 0;
    if (profile.goal == 'age_adaptation' && a > 0 && a < 40) return false;

    return true;
  }

  void _recalculate() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    final a = int.tryParse(_ageCtrl.text);
    if (h != null && w != null && a != null && _gender != null) {
      setState(() {
        _bmi = BmrCalculator.calculateBmi(weight: w, height: h);
        _bmiClass = BmrCalculator.classifyBmi(_bmi!);
        _bmr = BmrCalculator.calculate(weight: w, height: h, age: a, gender: _gender!);
      });
    }
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    
    final profile = ref.read(profileProvider);

    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final needsBranch = !['weight_loss', 'muscle_gain', 'maintenance'].contains(profile.goal);

    if (needsBranch) {
      await ref.read(profileNotifierProvider.notifier).saveField(
        'wants_to_lose_weight', _wantsToLoseWeight ?? false);
    }

    final heightCm = double.tryParse(_heightCtrl.text) ?? 0;
    final waistCm = double.tryParse(_waistCtrl.text);
    await ref.read(profileNotifierProvider.notifier).saveFields({
      'name': _nameCtrl.text.trim(),
      'gender': _gender,
      'age': _ageCtrl.text,
      'height': _heightCtrl.text,
      'weight': _weightCtrl.text,
      'waist': _waistCtrl.text,
      'bmi': _bmi?.toStringAsFixed(1),
      'bmi_class': _bmiClass,
      'bmr': _bmr?.toStringAsFixed(0),
      'bmr_kcal': _bmr,
      if (waistCm != null && heightCm > 0) 'waist_to_height_ratio': waistCm / heightCm,
    });

    if (!mounted) return;
    if (GoRouterState.of(context).uri.queryParameters['fromSummary'] == 'true') return;
    // GoRouter redirect will handle O-4 skip if goal != weight_loss
    context.go(Routes.o4WeightLoss);
  }

  void _saveData() {
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final a = int.tryParse(_ageCtrl.text) ?? 0;
    ref.read(profileNotifierProvider.notifier).saveFields({
      'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      'gender': _gender,
      'age': a > 0 ? a : null,
      'height': h > 0 ? h : null,
      'weight': w > 0 ? w : null,
      'waist': double.tryParse(_waistCtrl.text),
      'bmi': _bmi,
      'bmi_class': _bmiClass,
      'bmr': _bmr,
      'bmr_kcal': _bmr,
      if (_wantsToLoseWeight != null) 'wants_to_lose_weight': _wantsToLoseWeight,
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final needsBranch = !['weight_loss', 'muscle_gain', 'maintenance'].contains(profile.goal);

    return OnboardingScaffold(
      title: 'Расскажи о себе',
      subtitle: 'Базовые данные для расчёта калорийности и метрик',
      step: 2,
      totalSteps: 14,
      isValid: _isValid,
      onBack: () => context.go(Routes.o2Goal),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Блок «О тебе» ──────────────────────────────────────
          _sectionLabel('О тебе'),
          const SizedBox(height: 10),

          // Имя
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Например: Алекс, Мария',
              labelText: 'Как к тебе обращаться?',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Пол
          _sectionLabel('Пол'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _genderBtn('Женщина', 'female', '♀')),
            const SizedBox(width: 10),
            Expanded(child: _genderBtn('Мужчина', 'male', '♂')),
          ]),
          const SizedBox(height: 12),

          // Возраст
          HcNumberPickerField(
            controller: _ageCtrl,
            labelText: 'Возраст',
            hintText: '30',
            suffixText: 'лет',
            min: 16,
            max: 100,
            step: 1,
            isDecimal: false,
            onChanged: (_) { setState(() {}); _recalculate(); _saveData(); },
          ),
          
          if (profile.goal == 'age_adaptation' && (int.tryParse(_ageCtrl.text) ?? 0) > 0 && (int.tryParse(_ageCtrl.text) ?? 0) < 40) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Выберите другую цель на предыдущем шаге или введите возраст старше 40 лет.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFB91C1C), height: 1.4),
                )),
              ]),
            ),
          ],
          
          const SizedBox(height: 20),

          // ── Блок «Параметры тела» ─────────────────────────────
          _sectionLabel('Параметры тела'),
          const SizedBox(height: 10),

          // Рост + Вес
          Row(children: [
            Expanded(child: HcNumberPickerField(
              controller: _heightCtrl,
              labelText: 'Рост',
              hintText: '170',
              suffixText: 'см',
              min: 140,
              max: 230,
              step: 1,
              isDecimal: false,
              onChanged: (_) { setState(() {}); _recalculate(); _saveData(); },
            )),
            const SizedBox(width: 10),
            Expanded(child: HcNumberPickerField(
              controller: _weightCtrl,
              labelText: 'Вес',
              hintText: '75',
              suffixText: 'кг',
              min: 40,
              max: 250,
              step: 0.5,
              isDecimal: true,
              onChanged: (_) { setState(() {}); _recalculate(); _saveData(); },
            )),
          ]),
          const SizedBox(height: 12),

          // BMI badge (shows after height + weight filled)
          if (_bmi != null) _bmiBadge(),
          if (_bmi != null) const SizedBox(height: 12),

          // Обхват талии
          Row(children: [
            Expanded(child: HcNumberPickerField(
              controller: _waistCtrl,
              labelText: 'Обхват талии (необязательно)',
              hintText: '80',
              suffixText: 'см',
              helperText: 'На уровне пупка, на выдохе',
              min: 40,
              max: 200,
              step: 1,
              isDecimal: true,
              onChanged: (_) { setState(() {}); _saveData(); },
            )),
          ]),

          // ── Развилка (для целей кроме weight_loss/muscle_gain) ──
          if (needsBranch) ...[
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _wantsToLoseWeight = !(_wantsToLoseWeight ?? false));
                _saveData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: (_wantsToLoseWeight == true) ? const Color(0xFFFFF7ED) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_wantsToLoseWeight == true) ? AppColors.primary : const Color(0xFFE5E7EB),
                    width: (_wantsToLoseWeight == true) ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: (_wantsToLoseWeight == true) ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (_wantsToLoseWeight == true) ? AppColors.primary : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                      child: (_wantsToLoseWeight == true)
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Есть цель также снизить вес',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Из роста, веса и возраста мы рассчитаем твой базовый обмен веществ. Обхват талии точнее говорит о висцеральном жире — том, что реально влияет на здоровье.',
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8,
    ),
  );

  Widget _genderBtn(String label, String value, String symbol) {
    final sel = _gender == value;
    return GestureDetector(
      onTap: () { setState(() => _gender = value); _recalculate(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
            width: sel ? 1.5 : 1,
          ),
          boxShadow: [
            if (!sel) ...AppTheme.cardShadow
            else BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: sel ? AppColors.primary : AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
            color: sel ? AppColors.primary : AppColors.textPrimary,
          )),
        ]),
      ),
    );
  }


  Widget _bmiBadge() {
    final bmiText = _bmi!.toStringAsFixed(1);
    final bmiClass = _bmiClass ?? '';
    final (label, color, bg) = switch (bmiClass) {
      'underweight' => ('Недостаточный вес', const Color(0xFF42A5F5), const Color(0xFFE3F2FD)),
      'normal'      => ('Нормальный вес', const Color(0xFF52B044), const Color(0xFFE8F5E9)),
      'overweight'  => ('Избыточный вес', const Color(0xFFF09030), const Color(0xFFFFF3E0)),
      _             => ('Ожирение', const Color(0xFFF44336), const Color(0xFFFFEBEE)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.monitor_weight_outlined, color: color, size: 20),
        const SizedBox(width: 8),
        Text('ИМТ $bmiText — $label',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
