import 'package:flutter/material.dart';
import 'package:health_code/core/theme/app_theme.dart';

class HcDropdownField extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const HcDropdownField({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Expanded(child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 15,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          )),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
        ]),
      ),
    );
  }
}

Future<T?> showHcDropdownSheet<T>({
  required BuildContext context,
  required String title,
  required List<(T value, String label, String? subtitle)> items,
  required T? selectedValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((t) {
                    final sel = selectedValue == t.$1;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.$2, style: TextStyle(
                                fontFamily: 'Inter', fontSize: 15,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? AppColors.primary : AppColors.textPrimary,
                              )),
                              if (t.$3 != null) ...[
                                const SizedBox(height: 2),
                                Text(t.$3!, style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 13,
                                  color: sel ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                                )),
                              ],
                            ],
                          )),
                          if (sel) const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text(widget.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((t) {
                    final sel = _selected.contains(t.$1);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (sel) _selected.remove(t.$1); else _selected.add(t.$1);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.$2, style: TextStyle(
                                fontFamily: 'Inter', fontSize: 15,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? AppColors.primary : AppColors.textPrimary,
                              )),
                              if (t.$3 != null) ...[
                                const SizedBox(height: 2),
                                Text(t.$3!, style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 13,
                                  color: sel ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                                )),
                              ],
                            ],
                          )),
                          Icon(
                            sel ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: sel ? AppColors.primary : const Color(0xFF9CA3AF),
                            size: 24,
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Сохранить', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  final String title;
  final List<(T value, String label, String? subtitle)> items;
  final Set<T> initialSelected;

  const _MultiSelectSheet({
    required this.title,
    required this.items,
    required this.initialSelected,
  });

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

Future<Set<T>?> showHcMultiSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<(T value, String label, String? subtitle)> items,
  required Set<T> initialSelected,
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    isScrollControlled: true,
    builder: (_) => _MultiSelectSheet<T>(
      title: title,
      items: items,
      initialSelected: initialSelected,
    ),
  );
}
