// lib/features/shopping/presentation/shopping_list_screen.dart
// S-1: Список покупок — группировка по категориям, checkboxes, PDF export
// Данные строятся из MealPlan через ShoppingListBuilder

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/plan/data/meal_plan_model.dart';
import 'package:ejeweeka_app/features/plan/providers/plan_provider.dart';
import 'package:ejeweeka_app/features/shopping/data/shopping_list_builder.dart';
import 'package:ejeweeka_app/features/shopping/presentation/product_detail_screen.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  Map<String, List<ShoppingItem>> _grouped = {};
  bool _showChecked = true;
  int? _estimatedCost;
  int? _daysGenerated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlan();
    });
  }

  void _loadPlan() {
    final planState = ref.read(planNotifierProvider);
    MealPlan? plan;
    if (planState is PlanLoaded) plan = planState.plan;
    if (planState is PlanOffline) plan = (planState).plan;
    if (plan != null) {
      setState(() {
        _grouped = ShoppingListBuilder.build(plan!);
        _estimatedCost = plan.estimatedCost;
        _daysGenerated = plan.daysGenerated;
      });
    }
  }

  int get _totalItems => _grouped.values.fold(0, (s, l) => s + l.length);
  int get _checkedItems => _grouped.values.fold(0, (s, l) => s + l.where((i) => i.checked).length);

  @override
  Widget build(BuildContext context) {
    ref.listen(planNotifierProvider, (_, next) {
      if (next is PlanLoaded || next is PlanOffline) _loadPlan();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Список покупок',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800)),
                  _buildReceiptHeader(),
                ])),
                // Toggle show/hide checked
                IconButton(
                  onPressed: () => setState(() => _showChecked = !_showChecked),
                  icon: Icon(_showChecked ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.textSecondary),
                  tooltip: _showChecked ? 'Скрыть купленное' : 'Показать купленное',
                ),
                // Uncheck all
                IconButton(
                  onPressed: _totalItems > 0 ? _uncheckAll : null,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Сбросить',
                  color: AppColors.textSecondary,
                ),
              ]),
            ),
            const SizedBox(height: 8),

            // ── Progress bar ───────────────────────────────────────
            if (_totalItems > 0) _progressBar(),

            // ── Content ────────────────────────────────────────────
            Expanded(
              child: _grouped.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: _grouped.length,
                      itemBuilder: (_, i) {
                        final cat = _grouped.keys.elementAt(i);
                        final items = _grouped[cat]!
                            .where((item) => _showChecked || !item.checked)
                            .toList();
                        if (items.isEmpty) return const SizedBox.shrink();
                        return _categorySection(cat, items);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark premium background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Корзина на ${_daysGenerated ?? 7} дней',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                    const Spacer(),
                    if (_totalItems > 0)
                      Text('$_checkedItems/$_totalItems',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _estimatedCost != null && _estimatedCost! > 0 ? '~ $_estimatedCost ₽' : 'Считаем...',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final progress = _totalItems > 0 ? _checkedItems / _totalItems : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.primary)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ]),
    );
  }

  Widget _categorySection(String cat, List<ShoppingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(cat,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(children: [
                _itemRow(item),
                if (i < items.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _itemRow(ShoppingItem item) {
    final allItems = _grouped.values.expand((l) => l).toList();
    return InkWell(
      onTap: () => setState(() => item.checked = !item.checked),
      onLongPress: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productName: item.name,
          category: item.category.replaceAll(RegExp(r'^[^\s]+\s'), ''),
          amount: '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity.toStringAsFixed(1)} ${item.unit}',
        ))),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: item.checked ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: item.checked ? AppColors.primary : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: item.checked
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500,
              color: item.checked ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textPrimary,
              decoration: item.checked ? TextDecoration.lineThrough : null,
            ),
            child: Text(item.name),
          )),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
              color: item.checked ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary,
              decoration: item.checked ? TextDecoration.lineThrough : null,
            ),
            child: Text('${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity.toStringAsFixed(1)} ${item.unit}'),
          ),
        ]),
      ),
    );
  }

  void _uncheckAll() {
    setState(() {
      for (final items in _grouped.values) {
        for (final item in items) {
          item.checked = false;
        }
      }
    });
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🛒', style: TextStyle(fontSize: 56)),
    const SizedBox(height: 16),
    const Text('Список пуст', style: TextStyle(fontFamily: 'Inter', fontSize: 18,
      fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Сначала создайте план питания\n— список покупок сформируется автоматически',
      textAlign: TextAlign.center,
      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
  ]));
}
