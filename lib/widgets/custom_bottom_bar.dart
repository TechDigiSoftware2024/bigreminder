import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.home_rounded, "Home", 0,context,),
          _buildItem(Icons.account_balance_wallet_rounded, "Entries", 1,context,),
          _buildItem(Icons.add_circle_rounded, "Add", 2, isCenter: true,context,),
          _buildItem(Icons.bar_chart_rounded, "Reports", 3,context,),
          _buildItem(Icons.person_rounded, "Profile", 4,context,),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index,
      BuildContext context,
      {bool isCenter = false}) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          vertical: isCenter ? 0 : 8,
          horizontal: isCenter ? 0 : 12,
        ),
        decoration: isSelected && !isCenter
            ? BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              Container(
                padding:  EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
            else
              Icon(
                icon,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                size: 24,
              ),

            if (!isCenter)
              const SizedBox(height: 4),

            if (!isCenter)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}