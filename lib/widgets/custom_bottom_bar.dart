import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<String> labels;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _item(Icons.home_outlined, labels[0], 0),
                _item(Icons.receipt_long_outlined, labels[1], 1),
                _item(Icons.point_of_sale_outlined, labels[2], 2),
                _item(Icons.notifications_none_outlined, labels[3], 3),
                _item(Icons.person_outline, labels[4], 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 2,
              width: 18,
              margin: const EdgeInsets.only(bottom: 6),
              color: selected ? AppColors.primary : Colors.transparent,
            ),
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
