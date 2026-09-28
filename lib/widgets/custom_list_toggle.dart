import 'package:flutter/material.dart';

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
    final primary = Theme.of(context).colorScheme.primary;
    final isSelected = value;
    final active = onColor ?? primary;
    final inactive = offColor ?? primary;
    final outline = outlineColor ?? active.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? active.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? active : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        activeThumbColor: Colors.white,
        inactiveThumbColor: inactive,
        activeTrackColor: active.withValues(alpha: 0.6),
        trackOutlineColor: WidgetStateProperty.all(outline),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey.shade600),
              )
            : null,
      ),
    );
  }
}
