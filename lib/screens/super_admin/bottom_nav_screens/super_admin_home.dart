import 'package:bigreminder/models/super_admin_models/platform_dashboard_model.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/notification_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/subscription_screen.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/business_list.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/super_admin_qeury_screen.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/user_list_screen.dart';
import 'package:bigreminder/theme/super_admin_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/super_admin/super_admin_provider.dart';

class SuperAdminHome extends ConsumerStatefulWidget {
  const SuperAdminHome({super.key});

  @override
  ConsumerState<SuperAdminHome> createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends ConsumerState<SuperAdminHome> {
  String _money(double value) {
    if (value.abs() >= 10000000) {
      return NumberFormat.compactCurrency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 1,
      ).format(value);
    }
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  int _openSupportCount(List queries) {
    return queries.where((q) {
      final status = q.status.toString().toLowerCase().trim();
      return status == 'open' ||
          status == 'pending' ||
          status == 'in_progress';
    }).length;
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.refresh(platformDashboardProvider.future),
      ref.refresh(userProvider.future),
      ref.refresh(businessListProvider.future),
      ref.refresh(adminQueryProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final platformAsync = ref.watch(platformDashboardProvider);
    final usersAsync = ref.watch(userProvider);
    final businessAsync = ref.watch(businessListProvider);
    final queryAsync = ref.watch(adminQueryProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SuperAdminColors.primaryDark,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: platformAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _refreshAll,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (platform) {
          final userCount = usersAsync.asData?.value.length ?? 0;
          final businessCount = businessAsync.asData?.value.length ?? 0;
          final openSupport = queryAsync.asData != null
              ? _openSupportCount(queryAsync.asData!.value)
              : 0;

          if (isDesktop) {
            return _buildDesktop(
              platform: platform,
              userCount: userCount,
              businessCount: businessCount,
              openSupport: openSupport,
            );
          }

          return RefreshIndicator(
            color: SuperAdminColors.primaryDark,
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _buildMobileContent(
                platform: platform,
                userCount: userCount,
                businessCount: businessCount,
                openSupport: openSupport,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktop({
    required PlatformDashboardModel platform,
    required int userCount,
    required int businessCount,
    required int openSupport,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Overview',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'See how the whole platform is performing',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OverviewCard(
                      income: _money(platform.totalIncomeValue),
                      expenses: _money(platform.totalExpensesValue),
                      pending: _money(platform.pendingValue),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Key Numbers',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 145,
                            child: _MetricCard(
                              title: 'Users',
                              value: '$userCount',
                              icon: Icons.people_outline_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 145,
                            child: _MetricCard(
                              title: 'Businesses',
                              value: '$businessCount',
                              icon: Icons.storefront_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BusinessListPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 145,
                            child: _MetricCard(
                              title: 'Customers',
                              value: '${platform.totalCustomers}',
                              icon: Icons.groups_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 145,
                            child: _MetricCard(
                              title: 'Open Support',
                              value: '$openSupport',
                              icon: Icons.support_agent_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SuperAdminQueryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 4,
                child: _QuickActionsPanel(
                  openSupport: openSupport,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileContent({
    required PlatformDashboardModel platform,
    required int userCount,
    required int businessCount,
    required int openSupport,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'See how the whole platform is performing',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _OverviewCard(
          income: _money(platform.totalIncomeValue),
          expenses: _money(platform.totalExpensesValue),
          pending: _money(platform.pendingValue),
          compact: true,
        ),
        const SizedBox(height: 20),
        const Text(
          'Key Numbers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 130,
                child: _MetricCard(
                  title: 'Users',
                  value: '$userCount',
                  icon: Icons.people_outline_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 130,
                child: _MetricCard(
                  title: 'Businesses',
                  value: '$businessCount',
                  icon: Icons.storefront_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessListPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 130,
                child: _MetricCard(
                  title: 'Customers',
                  value: '${platform.totalCustomers}',
                  icon: Icons.groups_outlined,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 130,
                child: _MetricCard(
                  title: 'Open Support',
                  value: '$openSupport',
                  icon: Icons.support_agent_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuperAdminQueryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _QuickActionsPanel(openSupport: openSupport),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ============================================================================
// OVERVIEW CARD
// ============================================================================

class _OverviewCard extends StatelessWidget {
  final String income;
  final String expenses;
  final String pending;
  final bool compact;

  const _OverviewCard({
    required this.income,
    required this.expenses,
    required this.pending,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = SuperAdminColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              title: 'Income',
              value: income,
              icon: Icons.trending_up_rounded,
              compact: compact,
            ),
          ),
          Container(height: compact ? 48 : 55, width: 1, color: Colors.white24),
          Expanded(
            child: _OverviewMetric(
              title: 'Expenses',
              value: expenses,
              icon: Icons.trending_down_rounded,
              compact: compact,
            ),
          ),
          Container(height: compact ? 48 : 55, width: 1, color: Colors.white24),
          Expanded(
            child: _OverviewMetric(
              title: 'Pending',
              value: pending,
              icon: Icons.schedule_rounded,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool compact;

  const _OverviewMetric({
    required this.title,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 14 : 16, color: Colors.white70),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// METRIC CARD
// ============================================================================

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = SuperAdminColors.primaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: primary.withValues(alpha: 0.1),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS
// ============================================================================

class _QuickActionsPanel extends StatelessWidget {
  final int openSupport;

  const _QuickActionsPanel({required this.openSupport});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Jump to common admin tasks',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          _ActionTile(
            title: 'Users',
            subtitle: 'View all platform users',
            icon: Icons.people_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Businesses',
            subtitle: 'Manage registered businesses',
            icon: Icons.storefront_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessListPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Send Notification',
            subtitle: 'Broadcast updates to users',
            icon: Icons.notifications_none_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Manage Plans',
            subtitle: 'Subscriptions & pricing',
            icon: Icons.workspace_premium_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Support Inbox',
            subtitle: openSupport > 0
                ? '$openSupport open requests'
                : 'No open requests',
            icon: Icons.support_agent_rounded,
            badge: openSupport > 0 ? '$openSupport' : null,
            highlighted: openSupport > 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SuperAdminQueryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool highlighted;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = SuperAdminColors.primaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.orange.withValues(alpha: 0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? Colors.orange.withValues(alpha: 0.25)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: (highlighted ? Colors.orange : primary)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlighted ? Colors.orange : primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
