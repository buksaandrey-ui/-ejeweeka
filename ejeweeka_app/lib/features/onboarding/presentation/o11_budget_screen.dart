// lib/features/onboarding/presentation/o11_budget_screen.dart
// O-11: Бюджет и готовка
// screens-map.md:
//   Блок «Бюджет»: Экономный / Средний / Премиум
//   Блок «Как готовишь»: 3 карточки с иконками
//   Подвопрос «Время»: только если «Готовлю каждый день» или «Готовлю заранее» (Progressive Disclosure)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ejeweeka_app/core/router/route_names.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/shared/widgets/hc_dropdown_field.dart';
import 'package:ejeweeka_app/shared/widgets/motivating_tip_card.dart';
import 'package:ejeweeka_app/shared/widgets/onboarding_scaffold.dart';

class O11BudgetScreen extends ConsumerStatefulWidget {
  const O11BudgetScreen({super.key});

  @override
  ConsumerState<O11BudgetScreen> createState() => _O11BudgetScreenState();
}

class _O11BudgetScreenState extends ConsumerState<O11BudgetScreen> {
  String? _budget;        // 'economy' | 'medium' | 'premium'
  String? _shoppingFrequency; // 'daily' | 'few_days' | 'weekly'
  String? _cookingStyle;  // 'daily' | 'batch_2_3_days' | 'batch_weekly' | 'none'
  String? _cookingTime;   // 'up_to_15' | '20_40' | 'over_60'

  @override
  void initState() {
    super.initState();
    final p = ProfileRepository.getOrCreate();
    if (p.budgetLevel != null) _budget = p.budgetLevel;
    if (p.shoppingFrequency != null) _shoppingFrequency = p.shoppingFrequency;
    if (p.cookingTime != null) _cookingTime = p.cookingTime;
    final raw = ProfileRepository.getRawJson();
    if (raw.containsKey('cooking_style')) _cookingStyle = raw['cooking_style'] as String?;
  }

  // Обязательно: бюджет + частота покупок + стиль готовки + время (если готовит)
  bool get _isValid =>
    _budget != null &&
    _shoppingFrequency != null &&
    _cookingStyle != null &&
    (_cookingStyle == 'none' || _cookingTime != null);

  void _saveData() {
    ref.read(profileNotifierProvider.notifier).saveFields({
      'budget_level': _budget,
      'shopping_frequency': _shoppingFrequency,
      'cooking_style': _cookingStyle,
      'cooking_time': _cookingTime,
    });
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    _saveData();
    if (GoRouterState.of(context).uri.queryParameters["fromSummary"] == "true") return;
    if (mounted) context.go(Routes.o12BloodTests);
  }

  @override
  void dispose() {
    try { _saveData(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isWeightLoss = profile.goal == 'weight_loss';

    return OnboardingScaffold(
      title: 'Бюджет и готовка',
      subtitle: 'Подберём рецепты под твои реальные условия',
      step: isWeightLoss ? 10 : 9,
      totalSteps: isWeightLoss ? 14 : 13,
      isValid: _isValid,
      onBack: () => context.go(Routes.o10Activity),
      onNext: _proceed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Бюджет ──────────────────────────────────────────
          _label('Бюджет на питание'),
          const SizedBox(height: 10),
          _budgetDropdown(),

          const SizedBox(height: 24),

          // ── Частота покупок ──────────────────────────────────────────
          _label('Как часто ты покупаешь продукты?'),
          const SizedBox(height: 10),
          _shoppingDropdown(),

          const SizedBox(height: 24),

          // ── Стиль готовки — 3 карточки ─────────────────────
          _label('Как ты обычно готовишь?'),
          const SizedBox(height: 10),
          _cookingCard('daily', 'Готовлю каждый день',
            'Свежие блюда под каждый приём пищи'),
          const SizedBox(height: 8),
          _cookingCard('batch_2_3_days', 'Готовлю заранее на 2-3 дня',
            'Батч-готовка, контейнеры, разогрев'),
          const SizedBox(height: 8),
          _cookingCard('batch_weekly', 'Раз в неделю (заготовки)',
            'Замораживаю рагу, запеканки, бульоны'),
          const SizedBox(height: 8),
          _cookingCard('none', 'Почти не готовлю',
            'Покупаю готовое, доставка, столовая'),

          // ── Время готовки (Progressive Disclosure) ─────────
          if (_cookingStyle != null && _cookingStyle != 'none') ...[
            const SizedBox(height: 20),
            _label('Сколько времени за одну готовку?'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _timeChip('up_to_15', 'До 15 мин')),
              const SizedBox(width: 8),
              Expanded(child: _timeChip('20_40', '20–40 мин')),
              const SizedBox(width: 8),
              Expanded(child: _timeChip('over_60', 'Больше часа')),
            ]),
          ],
        ],
      ),
      tip: const MotivatingTipCard(
        text: 'Здоровое питание — не значит дорогое. Гречка, яйца, сезонные овощи, куриное бедро, творог — основа рациона за разумные деньги. «Нет времени готовить» — самая частая причина срывов. Мы адаптируем план.',
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.8));

  Widget _budgetDropdown() {
    const opts = [
      ('economy', 'Экономный', null),
      ('medium', 'Средний', null),
      ('premium', 'Выбираю качественные или премиальные продукты', null),
    ];
    final label = _budget == null
        ? 'Выбери уровень бюджета'
        : opts.firstWhere((o) => o.$1 == _budget, orElse: () => opts.first).$2;

    return HcDropdownField(
      label: label,
      isSelected: _budget != null,
      onTap: () async {
        final res = await showHcDropdownSheet<String>(
          context: context, title: 'Бюджет', items: opts, selectedValue: _budget,
        );
        if (res != null) { setState(() => _budget = res); _saveData(); }
      },
    );
  }

  Widget _shoppingDropdown() {
    const opts = [
      ('daily', 'Каждый день', null),
      ('few_days', 'Каждые 2-3 дня', null),
      ('weekly', 'Раз в неделю', null),
    ];
    final label = _shoppingFrequency == null
        ? 'Выбери частоту покупок'
        : opts.firstWhere((o) => o.$1 == _shoppingFrequency, orElse: () => opts.first).$2;

    return HcDropdownField(
      label: label,
      isSelected: _shoppingFrequency != null,
      onTap: () async {
        final res = await showHcDropdownSheet<String>(
          context: context, title: 'Покупки', items: opts, selectedValue: _shoppingFrequency,
        );
        if (res != null) { setState(() => _shoppingFrequency = res); _saveData(); }
      },
    );
  }

  Widget _cookingCard(String key, String title, String subtitle) {
    final sel = _cookingStyle == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _cookingStyle = key;
          if (key == 'none') {
            _cookingTime = null;
          } else if (key == 'batch_weekly') {
            _cookingTime = 'over_60'; // Force to over 60 mins if weekly
          }
        });
        _saveData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
              color: sel ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
              color: AppColors.textSecondary)),
          ])),
          if (sel)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
        ]),
      ),
    );
  }

  Widget _timeChip(String key, String label) {
    final sel = _cookingTime == key;
    final disabled = _cookingStyle == 'batch_weekly' && key != 'over_60';

    return GestureDetector(
      onTap: disabled ? null : () { setState(() => _cookingTime = key); _saveData(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF3F4F6) : sel ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: disabled ? const Color(0xFFE5E7EB) : sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel && !disabled ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
          color: disabled ? const Color(0xFF9CA3AF) : sel ? AppColors.primary : AppColors.textPrimary))),
      ),
    );
  }
}
