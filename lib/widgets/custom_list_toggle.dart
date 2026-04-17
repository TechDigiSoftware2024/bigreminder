import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomListToggle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? onColor;
  final Color? offColor;
  final Color? outlineColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomListToggle({
    super.key,
    required this.title,
    this.subtitle,
    this.onColor,
    this.offColor,
    this.outlineColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,

      contentPadding: EdgeInsets.zero,

      // Thumb colors
      activeThumbColor: onColor ?? Colors.white,
      inactiveThumbColor: offColor ?? Colors.white,

      // Track colors (important for modern UI)
      activeTrackColor: (onColor ?? Colors.green).withOpacity(0.6),

      // Border control (your main issue)
      trackOutlineColor: MaterialStateProperty.all(
        outlineColor ?? AppColors.primaryDark.withOpacity(0.3), // 🔥 clean default
      ),

      // Text
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle!,
        style: TextStyle(color: Colors.grey.shade600),
      )
          : null,
    );
  }
}