import 'package:flutter/material.dart';

class BusinessSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  const BusinessSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
  });

  static const List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.inventory_2_outlined,
    Icons.notifications_none_outlined,
    Icons.analytics_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.calculate_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          // ─────────────────────────────
          // LOGO / APP NAME
          // ─────────────────────────────
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    "assets/biz_reminder_logos.png",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 12),

                const Text(
                  'Biz Reminder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 20),

          // ─────────────────────────────
          // NAVIGATION
          // ─────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: labels.length,
              itemBuilder: (context, index) {
                final isSelected = currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SidebarItem(
                    label: labels[index],
                    icon: index < _icons.length
                        ? _icons[index]
                        : Icons.circle_outlined,
                    selected: isSelected,
                    primary: primary,
                    onTap: () => onTap(index),
                  ),
                );
              },
            ),
          ),

          // ─────────────────────────────
          // BOTTOM AREA
          // ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selected: false,
              primary: primary,
              onTap: () {
                // Settings navigation later
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? primary.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? primary
                    : Colors.grey.shade600,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: selected
                        ? primary
                        : Colors.grey.shade700,
                  ),
                ),
              ),

              if (selected)
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}