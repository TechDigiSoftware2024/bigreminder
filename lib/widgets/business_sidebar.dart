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
    Icons.inventory_2_outlined,
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
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final businessName = ref.watch(businessNameProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _collapsed ? 72 : 232,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_collapsed ? 0 : 8, 6, _collapsed ? 0 : 4, 0),
            child: Align(
              alignment: _collapsed ? Alignment.center : Alignment.centerRight,
              child: IconButton(
                tooltip: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _collapsed = !_collapsed),
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 22,
                  weight: 700,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_collapsed ? 8 : 14, 2, _collapsed ? 8 : 14, 16),
            child: _collapsed
                ? Center(child: _logo(36))
                : Row(
                    children: [
                      _logo(44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Biz Reminder',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.05,
                                color: Colors.white,
                              ),
                            ),
                            if (businessName.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.sidebarMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, color: AppColors.sidebarBorder),
          if (!_collapsed)
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
            )
          else
            const SizedBox(height: 8),
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
                  collapsed: _collapsed,
                  onTap: () => widget.onTap(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/biz_reminder_logos.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.sidebarText : AppColors.sidebarMuted;

    final item = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.radiusSM,
            hoverColor: AppColors.sidebarActive,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 10,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.sidebarActive : Colors.transparent,
                borderRadius: AppRadius.radiusSM,
              ),
              child: collapsed
                  ? Center(child: Icon(icon, size: 18, color: color))
                  : Row(
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
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: collapsed ? Tooltip(message: label, child: item) : item,
    );
  }
}
