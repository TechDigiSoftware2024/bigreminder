import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.radiusSM,
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
