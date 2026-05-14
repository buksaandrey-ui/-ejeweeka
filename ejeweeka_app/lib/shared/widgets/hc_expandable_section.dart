import 'package:flutter/material.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';

/// Сворачиваемая секция с чекбоксами внутри.
/// Показывает заголовок + счётчик выбранных + стрелку.
/// При тапе раскрывается со списком чекбоксов.
class HcExpandableSection extends StatefulWidget {
  final String title;
  final List<(String key, String label)> options;
  final Set<String> selected;
  final void Function(String key) onToggle;
  final String? exclusiveKey; // Ключ, который сбрасывает все остальные (напр. 'none')
  final bool initiallyExpanded;
  final Set<String>? disabledKeys;

  const HcExpandableSection({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.exclusiveKey,
    this.initiallyExpanded = false,
    this.disabledKeys,
  });

  @override
  State<HcExpandableSection> createState() => _HcExpandableSectionState();
}

class _HcExpandableSectionState extends State<HcExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animController;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    if (_expanded) _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.selected.where((s) => s != widget.exclusiveKey).length;
    final hasExclusive = widget.exclusiveKey != null &&
        widget.selected.contains(widget.exclusiveKey);
    final summaryText = hasExclusive
        ? widget.options
            .firstWhere((o) => o.$1 == widget.exclusiveKey,
                orElse: () => ('', 'Нет'))
            .$2
        : count > 0
            ? '$count выбрано'
            : 'Выбери...';
    final summaryColor = (count > 0 || hasExclusive)
        ? AppColors.primary
        : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (count > 0 || hasExclusive)
              ? AppColors.primary.withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header (always visible) ────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summaryText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: summaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: (count > 0 || hasExclusive)
                          ? AppColors.primary
                          : const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable body ────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ...widget.options.map((opt) {
                  final isSelected = widget.selected.contains(opt.$1);
                  final isDisabled = widget.disabledKeys?.contains(opt.$1) ?? false;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isDisabled ? null : () => widget.onToggle(opt.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF7ED)
                            : Colors.white,
                        border: const Border(
                          bottom:
                              BorderSide(color: Color(0xFFF5F5F5), width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDisabled ? const Color(0xFFF3F4F6) : Colors.white),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDisabled ? const Color(0xFFE5E7EB) : const Color(0xFFD1D5DB)),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.$2,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDisabled ? const Color(0xFF9CA3AF) : AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
