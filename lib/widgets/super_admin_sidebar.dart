import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class SuperAdminSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateBusiness;

  const SuperAdminSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreateBusiness,
  });

  static const _items = <(IconData, String)>[
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.category_outlined, 'Categories'),
    (Icons.workspace_premium_outlined, 'Plans'),
    (Icons.notifications_none_outlined, 'Notifications'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                _Mark(),
                SizedBox(width: 10),
                Expanded(
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
                        'Platform admin',
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
          const Divider(height: 1, color: AppColors.sidebarBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: SizedBox(
              height: 36,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreateBusiness,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New business'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sidebarText,
                  side: const BorderSide(color: AppColors.sidebarBorder),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final selected = currentIndex == index;
                final color =
                    selected ? AppColors.sidebarText : AppColors.sidebarMuted;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(index),
                      borderRadius: AppRadius.radiusSM,
                      hoverColor: AppColors.sidebarActive,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.sidebarActive
                              : Colors.transparent,
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.sidebarAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(item.$1, size: 18, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
