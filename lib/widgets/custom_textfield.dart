import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool digitsOnly;
  final int? maxLength;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.inputFormatters,
    this.icon,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.validator,
    this.digitsOnly = false,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: scheme.primary,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.inputBg,
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.inputErrorBorder),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.inputErrorBorder, width: 1.4),
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: AppColors.textSecondary),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
