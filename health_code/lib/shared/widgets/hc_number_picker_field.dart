import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_code/core/theme/app_theme.dart';

class HcNumberPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? suffixText;
  final String? helperText;
  final double min;
  final double max;
  final double step;
  final bool isDecimal;
  final Function(String) onChanged;

  const HcNumberPickerField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    this.suffixText,
    this.helperText,
    required this.min,
    required this.max,
    this.step = 1.0,
    this.isDecimal = false,
    required this.onChanged,
  });

  @override
  State<HcNumberPickerField> createState() => _HcNumberPickerFieldState();
}

class _HcNumberPickerFieldState extends State<HcNumberPickerField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        if (widget.isDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (val) {
        widget.onChanged(val);
      },
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        suffixText: widget.suffixText,
        helperText: widget.helperText,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 14),
      ),
    );
  }
}
