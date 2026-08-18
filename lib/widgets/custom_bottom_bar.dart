import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildItem(Icons.home_outlined, labels[0], 0, context),
            _buildItem(Icons.history_outlined, labels[1], 1, context),
            _buildItem(Icons.shopping_bag_outlined, labels[2], 2, context),
            _buildItem(Icons.notifications_outlined, labels[3], 3, context),
            _buildItem(Icons.person_outline, labels[4], 4, context),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
      IconData icon,
      String label,
      int index,
      BuildContext context,
      ) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: isSelected
                ? BoxDecoration(
              color:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            )
                : null,
            child: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}