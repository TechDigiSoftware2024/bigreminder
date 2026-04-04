import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CustomContainer({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all( color: theme.colorScheme.primary.withOpacity(0.1),)
          ),
      child: Row(
        children: [
          /// Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          /// Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}