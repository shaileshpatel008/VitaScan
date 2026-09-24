import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.suffix,
    this.hint,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  /// Digits only, for numeric vitals and body measurements.
  static final digits = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)];
  static final decimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?'))];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          readOnly: readOnly,
          onTap: onTap,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTextStyles.body(16, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: AppTextStyles.body(15, color: AppColors.subtle),
            suffixText: suffix,
            suffixStyle: AppTextStyles.body(14, color: AppColors.muted),
            errorStyle: AppTextStyles.body(12, color: AppColors.coral, height: 1.1),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
