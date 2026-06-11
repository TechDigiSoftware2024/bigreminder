import 'package:flutter/material.dart';

class CustomDropdownTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdownTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),

          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cs.primary,
            size: 26,
          ),

          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: cs.primary,
                size: 20,
              ),
            ),

            filled: true,
            fillColor: cs.surfaceContainerHighest.withOpacity(.35),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: cs.outline.withOpacity(.15),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: cs.primary,
                width: 1.5,
              ),
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),

          dropdownColor: cs.surface,

          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }
}