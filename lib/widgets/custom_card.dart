import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isElevated;
  final bool showBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.isElevated = true,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // ✅ dynamic

        borderRadius: BorderRadius.circular(16),

        boxShadow: isElevated
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : [],

        border: showBorder
            ? Border.all(
          color: theme.colorScheme.primary, // ✅ dynamic
          width: 0.3,
        )
            : Border.all(
          color: Colors.blueGrey.shade200,
          width: 0.3,
        ),
      ),
      child: child,
    );
  }
}