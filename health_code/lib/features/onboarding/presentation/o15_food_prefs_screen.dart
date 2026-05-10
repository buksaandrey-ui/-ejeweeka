// lib/features/onboarding/presentation/o15_food_prefs_screen.dart
// O-15: Продуктовые предпочтения
// screens-map.md:
//   Блок A: Нежелательные категории (множественный выбор чипов)
//   Блок B: Любимые продукты — ТЕКСТОВОЕ ПОЛЕ
//   Блок C: Нелюбимые продукты — ТЕКСТОВОЕ ПОЛЕ

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/data/profile_repository.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/shared/utils/input_formatter.dart';
import 'package:health_code/shared/widgets/motivating_tip_card.dart';
import 'package:health_code/shared/widgets/onboarding_scaffold.dart';
import 'package:health_code/shared/widgets/hc_dropdown_field.dart';

class O15FoodPrefsScreen extends ConsumerStatefulWidget {
  const O15FoodPrefsScreen({super.key});

  @override
  ConsumerState<O15FoodPrefsScreen> createState() => _O15FoodPrefsScreenState();
}

class _O15FoodPrefsScreenState extends ConsumerState<O15FoodPrefsScreen> {
  final Set<String> _excluded = {};
  final _likedCtrl = TextEditingController();
  final _dislikedCtrl = TextEditingController();

  static const _mealTypes = <(String, String)>[
    ('soups', 'Супы'),
    ('porridges', 'Каши'),
    ('salads', 'Салаты'),
    ('smoothies', 'Смузи или коктейли'),
    ('offal', 'Блюда из субпродуктов'),
    ('eat_all', 'Нет, ем всё из перечисленного'),
  ];

  @override
  void initState() {
    super.initState();
    final raw = ProfileRepository.getRawJson();
    if (raw.containsKey('liked_foods') && raw['liked_foods'] is String) {
      _likedCtrl.text = raw['liked_foods'] as String;
    }
    if (raw.containsKey('disliked_foods') && raw['disliked_foods'] is String) {
      _dislikedCtrl.text = raw['disliked_foods'] as String;
    }
    if (raw.containsKey('excluded_meal_types') && raw['excluded_meal_types'] is List) {
      _excluded.addAll((raw['excluded_meal_types'] as List).cast<String>());
    }
  }

  bool get _isValid => true; // Optional — always valid

  void _toggleExcluded(String key) {
    setState(() {
      if (key == 'eat_all') {
        _excluded.clear();
        _excluded.add('eat_all');
      } else {
        _excluded.remove('eat_all');
        if (_excluded.contains(key)) {
          _excluded.remove(key);
        } else {
          _excluded.add(key);
        }
      }
    });
    _saveData();
  }

  void _saveData() {
    ref.read(profileNotifierProvider.notifier).saveFields({
      'excluded_meal_types': _excluded.toList(),
      'liked_foods': InputFormatter.formatHealthData(_likedCtrl.text),
      'disliked_foods': InputFormatter.formatHealthData(_dislikedCtrl.text),
    });
  }

  Future<void> _proceed() async {
    _saveData();
    if (mounted) context.go(Routes.o25AiPersonality);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    _likedCtrl.dispose();
    _dislikedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Вкусовые предпочтения',
      subtitle: 'Необязательно — но с этим план станет вкуснее',
      step: isWeightLoss ? 14 : 13,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o14Motivation),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Блок A: Нежелательные категории
          _label('Категории блюд, которые НЕ хочешь видеть'),
          const SizedBox(height: 8),
          HcDropdownField(
            label: _excludedLabel(),
            isSelected: _excluded.isNotEmpty,
            onTap: () async {
              // Filter out 'eat_all' for multi-select items
              const items = <(String, String, String?)>[
                ('soups', 'Супы', null),
                ('porridges', 'Каши', null),
                ('salads', 'Салаты', null),
                ('smoothies', 'Смузи или коктейли', null),
                ('offal', 'Блюда из субпродуктов', null),
              ];
              final current = Set<String>.from(_excluded)..remove('eat_all');
              final res = await showHcMultiSelectSheet<String>(
                context: context,
                title: 'Исключить категории',
                items: items,
                initialSelected: current,
              );
              if (res != null) {
                setState(() {
                  _excluded.clear();
                  if (res.isEmpty) {
                    _excluded.add('eat_all');
                  } else {
                    _excluded.addAll(res);
                  }
                });
                _saveData();
              }
            },
          ),

          const SizedBox(height: 24),

          // Блок B: Любимые продукты — текстовое поле
          _label('Любимые продукты'),
          const SizedBox(height: 8),
          TextField(
            controller: _likedCtrl,
            decoration: const InputDecoration(
              hintText: 'Например: курица, рыба, авокадо, творог, гречка, ягоды',
            ),
            maxLines: 2,
            onChanged: (_) => _saveData(),
          ),

          const SizedBox(height: 20),

          // Блок C: Нелюбимые продукты — текстовое поле
          _label('Нелюбимые продукты'),
          const SizedBox(height: 8),
          TextField(
            controller: _dislikedCtrl,
            decoration: const InputDecoration(
              hintText: 'Например: печень, баклажаны, кинза, манная каша',
            ),
            maxLines: 2,
            onChanged: (_) => _saveData(),
          ),
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Лучшая диета — та, которой ты реально следуешь. Никаких правильных или неправильных ответов — только твои реальные вкусы. Удовольствие от еды улучшает усвоение на 20–30%.',
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));

  String _excludedLabel() {
    if (_excluded.isEmpty || _excluded.contains('eat_all')) {
      return 'Ем всё из перечисленного';
    }
    const labels = {'soups': 'Супы', 'porridges': 'Каши', 'salads': 'Салаты',
      'smoothies': 'Смузи', 'offal': 'Субпродукты'};
    final names = _excluded.map((k) => labels[k] ?? k).toList();
    if (names.length <= 2) return names.join(', ');
    return 'Исключено: ${names.length}';
  }
}
