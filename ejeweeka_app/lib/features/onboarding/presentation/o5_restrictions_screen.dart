// lib/features/onboarding/presentation/o5_restrictions_screen.dart
// O-5: Ограничения в еде и аллергии
// screens-map.md spec:
//   Блок «Ограничения»: множественный выбор, «Нет ограничений» взаимоисключает
//   + Поле «Другое» с тегами (Enter → чип)
//   Блок «Аллергии»: Да/Нет → выпадающий список + поле «Другое» с тегами

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/utils/input_formatter.dart';
import 'package:ejeweeka_app/shared/widgets/hc_expandable_section.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';

const _dietOptions = <(String, String)>[
  ('none', 'Нет ограничений'),
  ('vegetarian', 'Вегетарианство'),
  ('vegan', 'Веганство'),
  ('no_red_meat', 'Не ем красное мясо'),
  ('pescatarian', 'Не ем мясо, но ем рыбу'),
  ('no_dairy', 'Не ем молочные продукты'),
  ('gluten_free', 'Не ем глютен'),
  ('no_sugar', 'Не ем сахар или стараюсь избегать'),
  ('halal', 'Халяль'),
  ('kosher', 'Кошерное питание'),
];

const _allergyOptions = <(String, String)>[
  ('nuts', 'Орехи'),
  ('peanuts', 'Арахис'),
  ('dairy', 'Молоко и молочные'),
  ('eggs', 'Яйца'),
  ('fish', 'Рыба'),
  ('shellfish', 'Морепродукты'),
  ('soy', 'Соя'),
  ('citrus', 'Цитрусовые'),
  ('honey', 'Мёд'),
];

final _standardDietKeys = _dietOptions.map((o) => o.$1).toSet();
final _standardAllergyKeys = _allergyOptions.map((o) => o.$1).toSet();

class O5RestrictionsScreen extends ConsumerStatefulWidget {
  const O5RestrictionsScreen({super.key});

  @override
  ConsumerState<O5RestrictionsScreen> createState() => _O5RestrictionsScreenState();
}

class _O5RestrictionsScreenState extends ConsumerState<O5RestrictionsScreen> {
  final Set<String> _diets = {};
  bool? _hasAllergies;
  final Set<String> _allergies = {};

  final List<String> _customDiets = [];
  final List<String> _customAllergies = [];
  final _customDietCtrl = TextEditingController();
  final _customAllergyCtrl = TextEditingController();
  final _customDietFocus = FocusNode();
  final _customAllergyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.diets.isNotEmpty) {
      for (final d in p.diets) {
        if (_standardDietKeys.contains(d)) {
          _diets.add(d);
        } else {
          _customDiets.add(d);
          _diets.add(d);
        }
      }
    }
    if (p.allergies.isNotEmpty) {
      _hasAllergies = true;
      for (final a in p.allergies) {
        if (_standardAllergyKeys.contains(a)) {
          _allergies.add(a);
        } else {
          _customAllergies.add(a);
          _allergies.add(a);
        }
      }
    } else if (p.diets.isNotEmpty) {
      _hasAllergies = false;
    }
  }

  bool get _isValid => _diets.isNotEmpty && _hasAllergies != null;

  void _toggleDiet(String key) {
    setState(() {
      if (key == 'none') {
        _diets.clear();
        _customDiets.clear();
        _diets.add('none');
      } else {
        _diets.remove('none');
        if (_diets.contains(key)) {
          _diets.remove(key);
        } else {
          _diets.add(key);
          // Mutual exclusivity logic
          if (key == 'vegan') {
            _diets.remove('vegetarian');
            _diets.remove('no_red_meat');
            _diets.remove('pescatarian');
            _diets.remove('no_dairy');
          } else if (key == 'vegetarian') {
            _diets.remove('vegan');
            _diets.remove('no_red_meat');
            _diets.remove('pescatarian');
          } else if (key == 'pescatarian') {
            _diets.remove('vegan');
            _diets.remove('vegetarian');
            _diets.remove('no_red_meat');
          } else if (key == 'no_red_meat') {
            _diets.remove('vegan');
            _diets.remove('vegetarian');
            _diets.remove('pescatarian');
          } else if (key == 'no_dairy') {
            _diets.remove('vegan');
          }
        }
      }
    });
  }

  void _toggleAllergy(String key) {
    setState(() {
      if (_allergies.contains(key)) {
        _allergies.remove(key);
      } else {
        _allergies.add(key);
      }
    });
  }

  void _addCustomDiet(String text) {
    final formatted = InputFormatter.formatHealthData(text);
    if (formatted.isEmpty || _customDiets.contains(formatted)) return;
    setState(() {
      _diets.remove('none');
      _customDiets.add(formatted);
      _diets.add(formatted);
      _customDietCtrl.clear();
    });
  }

  void _removeCustomDiet(String text) {
    setState(() { _customDiets.remove(text); _diets.remove(text); });
  }

  void _addCustomAllergy(String text) {
    final formatted = InputFormatter.formatHealthData(text);
    if (formatted.isEmpty || _customAllergies.contains(formatted)) return;
    setState(() {
      _customAllergies.add(formatted);
      _allergies.add(formatted);
      _customAllergyCtrl.clear();
    });
  }

  void _removeCustomAllergy(String text) {
    setState(() { _customAllergies.remove(text); _allergies.remove(text); });
  }

  void _saveData() {
    ref.read(profileNotifierProvider.notifier).saveFields({
      'diets': _diets.toList(),
      'allergies': _hasAllergies == true ? _allergies.toList() : <String>[],
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (GoRouterState.of(context).uri.queryParameters["fromSummary"] == "true") return;
    if (mounted) context.go(Routes.o6Health);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _customDietCtrl.dispose();
    _customAllergyCtrl.dispose();
    _customDietFocus.dispose();
    _customAllergyFocus.dispose();
    super.dispose();
  }

  Set<String> get _disabledDiets {
    final disabled = <String>{};
    if (_diets.contains('vegan')) {
      disabled.addAll(['vegetarian', 'no_red_meat', 'pescatarian', 'no_dairy']);
    } else if (_diets.contains('vegetarian')) {
      disabled.addAll(['vegan', 'no_red_meat', 'pescatarian']);
    } else if (_diets.contains('pescatarian')) {
      disabled.addAll(['vegan', 'vegetarian', 'no_red_meat']);
    } else if (_diets.contains('no_red_meat')) {
      disabled.addAll(['vegan', 'vegetarian', 'pescatarian']);
    }
    if (_diets.contains('no_dairy')) {
      disabled.add('vegan');
    }
    return disabled;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final step = profile.goal == 'weight_loss' ? 4 : 3;

    return OnboardingScaffold(
      title: 'Ограничения в питании',
      subtitle: 'Полностью исключим всё, что тебе не подходит',
      step: step,
      totalSteps: profile.goal == 'weight_loss' ? 14 : 13,
      isValid: _isValid,
      onBack: () {
        final isWL = profile.goal == 'weight_loss' || profile.wantsToLoseWeight;
        context.go(isWL ? Routes.o4WeightLoss : Routes.o3Profile);
      },
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ограничения (выпадающий список) ────────────────────
          HcExpandableSection(
            title: 'Ограничения в еде',
            options: _dietOptions,
            selected: _diets,
            onToggle: _toggleDiet,
            exclusiveKey: 'none',
            disabledKeys: _disabledDiets,
          ),

          // ── Кастомные ограничения (чипы) ──────────────────────
          if (_customDiets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customDiets.map((d) => _customChip(d, () => _removeCustomDiet(d))).toList(),
            ),
          ],

          // ── Поле ввода «Другое» ───────────────────────────────
          const SizedBox(height: 10),
          _customInputField(
            controller: _customDietCtrl,
            focusNode: _customDietFocus,
            hint: 'Другое ограничение...',
            onSubmit: _addCustomDiet,
          ),

          const SizedBox(height: 20),

          // ── Аллергии ──────────────────────────────────────────
          _sectionLabel('Есть ли аллергия на продукты?'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _yesNoBtn('Да', true)),
            const SizedBox(width: 10),
            Expanded(child: _yesNoBtn('Нет', false)),
          ]),

          if (_hasAllergies == true) ...[
            const SizedBox(height: 14),
            HcExpandableSection(
              title: 'На что аллергия?',
              options: _allergyOptions,
              selected: _allergies,
              onToggle: _toggleAllergy,
            ),

            if (_customAllergies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customAllergies.map((a) => _customChip(a, () => _removeCustomAllergy(a))).toList(),
              ),
            ],

            const SizedBox(height: 10),
            _customInputField(
              controller: _customAllergyCtrl,
              focusNode: _customAllergyFocus,
              hint: 'Другая аллергия...',
              onSubmit: _addCustomAllergy,
            ),
          ],
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Это вопрос твоей безопасности. Даже самый полезный продукт может навредить при аллергии. Мы найдём полноценные замены — без потери баланса БЖУ.',
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

  Widget _sectionLabel(String text) => Text(text.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));

  Widget _yesNoBtn(String label, bool value) {
    final sel = _hasAllergies == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _hasAllergies = value;
        if (value == false) {
          _allergies.clear();
          _customAllergies.clear();
          _customAllergyCtrl.clear();
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
          color: sel ? AppColors.primary : AppColors.textPrimary))),
      ),
    );
  }
}
