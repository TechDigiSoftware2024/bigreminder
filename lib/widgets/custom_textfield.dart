import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;

  // ✅ NEW
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.validator, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField( // ✅ changed
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator, // ✅ attach validator
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
        ),

        filled: true,
        fillColor: const Color(0xFFF3F4F6),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blueGrey,
            width: 1.2,
          ),
        ),

        // ✅ ERROR BORDER (important)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.2,
          ),
        ),

        prefixIcon: icon != null
            ? Icon(
          icon,
          size: 20,
          color: const Color(0xFF6B7280),
        )
            : null,

        suffixIcon: trailing,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}