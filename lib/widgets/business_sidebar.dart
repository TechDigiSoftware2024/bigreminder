import 'package:bigreminder/providers/business/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class BusinessSidebar extends ConsumerStatefulWidget {
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
    Icons.receipt_long_outlined,
    Icons.point_of_sale_outlined,
    Icons.notifications_none_outlined,
    Icons.person_outline,
    Icons.account_balance_wallet_outlined,
    Icons.calculate_outlined,
  ];

  @override
  ConsumerState<BusinessSidebar> createState() => _BusinessSidebarState();
}

class _BusinessSidebarState extends ConsumerState<BusinessSidebar> {
  @override
  Widget build(BuildContext context) {
    final businessName = ref.watch(businessNameProvider);

    return Container(
      width: 232,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sidebarActive,
                    borderRadius: AppRadius.radiusSM,
                    border: Border.all(color: AppColors.sidebarBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/biz_reminder_logos.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biz Reminder',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sidebarText,
                        ),
                      ),
                      Text(
                        'Workspace',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.sidebarMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (businessName.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.sidebarText,
                ),
              ),
            ),
          const Divider(height: 1, color: AppColors.sidebarBorder),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'MODULES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.sidebarMuted,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.labels.length,
              itemBuilder: (context, index) {
                return _SidebarItem(
                  label: widget.labels[index],
                  icon: index < BusinessSidebar._icons.length
                      ? BusinessSidebar._icons[index]
                      : Icons.circle_outlined,
                  selected: widget.currentIndex == index,
                  onTap: () => widget.onTap(index),
                );
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
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.sidebarText : AppColors.sidebarMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusSM,
          hoverColor: AppColors.sidebarActive,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.sidebarActive : Colors.transparent,
              borderRadius: AppRadius.radiusSM,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.sidebarAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
