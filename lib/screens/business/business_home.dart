import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/screens/business/business_dash_screens/business_analysis_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/business_calculator_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/business_reminder_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/customer_list_screen.dart';
import 'package:bigreminder/screens/business/business_purchase_history.dart';
import 'package:bigreminder/screens/business/business_query_screen.dart';
import 'package:bigreminder/screens/business/business_template_screen.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/enum_classes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/business_models/business_dashboard_model.dart';
import '../../providers/business/business_provider.dart';
import 'business_dash_screens/add_expense_screen.dart';
import 'business_dash_screens/add_income_screen.dart';
import 'business_dash_screens/products_screen.dart';

class BusinessHome extends ConsumerStatefulWidget {
  final AppType type;
  const BusinessHome({super.key, required this.type});

  @override
  ConsumerState<BusinessHome> createState() => _BusinessHomeState();
}

class _BusinessHomeState extends ConsumerState<BusinessHome> {
  int businessId = 0;
  late String businessName = DashboardText.title(widget.type);

  @override
  void initState() {
    super.initState();
    // Home is recreated on each tab switch — refresh dashboard so
    // totals stay current after invoice payments / other updates.
    Future.microtask(() {
      if (!mounted) return;
      try {
        final id = ref.read(businessIdProvider);
        ref.invalidate(dashboardProvider(id));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final businessId = ref.watch(businessIdProvider);
    final businessName = ref.watch(businessNameProvider);

    final metrics = DashboardText.metrics(widget.type);
    final actions = DashboardText.actions(widget.type);

    // if (businessId == 0) {
    //   return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // }

    final dashboardAsync = ref.watch(dashboardProvider(businessId));
    final queryList = ref.watch(queryListProvider);
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: _buildAppBar(
        context,
        businessName,
        queryList,
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text("Error: $e"),
        ),
        data: (data) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _buildDesktopLayout(
                  context,
                  data,
                );
              }

              return _buildMobileLayout(
                context,
                data,
              );
            },
          );
        },
      ),
    );
    // return Scaffold(
    //   backgroundColor: const Color(0xffF5F7FB),
    //
    //   /// ✅ KEEP AppType but cleaner title
    //   appBar: AppBar(
    //     backgroundColor: primary,
    //     title: Text(
    //       businessName,
    //       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    //     ),
    //
    //     actions: [
    //       queryList.when(
    //         data: (queries) {
    //           final openCount = queries.where((q) {
    //             final status = q.status.toLowerCase().trim();
    //
    //             return status != 'resolved' &&
    //                 status != 'completed' &&
    //                 status != 'closed';
    //           }).length;
    //
    //           return Stack(
    //             clipBehavior: Clip.none,
    //             children: [
    //               IconButton(
    //                 onPressed: () {
    //                   Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                       builder: (_) => const BusinessQueryScreen(),
    //                     ),
    //                   );
    //                 },
    //                 icon: const Icon(
    //                   Icons.notifications_outlined,
    //                   size: 26,
    //                 ),
    //               ),
    //
    //               if (openCount > 0)
    //                 Positioned(
    //                   right: 6,
    //                   top: 6,
    //                   child: Container(
    //                     padding: const EdgeInsets.all(5),
    //                     decoration: BoxDecoration(
    //                       color: Colors.red.shade700,
    //                       shape: BoxShape.circle,
    //                     ),
    //                     child: Text(
    //                       openCount > 9 ? '9+' : '$openCount',
    //                       style: const TextStyle(
    //                         color: Colors.white,
    //                         fontSize: 10,
    //                         fontWeight: FontWeight.bold,
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //             ],
    //           );
    //         },
    //         loading: () => const SizedBox(),
    //         error: (_, __) => const SizedBox(),
    //       ),
    //       const SizedBox(width: 10),
    //     ],
    //   ),
    //
    //   body: dashboardAsync.when(
    //     loading: () => Center(child: CircularProgressIndicator()),
    //     error: (e, _) => Center(child: Text("Error: $e")),
    //     data: (data) {
    //       return _buildContent(context, data, metrics, actions);
    //     },
    //   ),
    // );
  }
  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      String businessName,
      AsyncValue queryList,
      ) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final unreadCount = ref.watch(unreadQueryCountProvider);
    return AppBar(
      backgroundColor: primary,
      elevation: 0,
      title: Text(
        businessName,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        if(isDesktop)
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final currentBusinessId = ref.read(businessIdProvider);
              await ref.refresh(dashboardProvider(currentBusinessId).future);
              await ref.refresh(customerProvider.future);
            },
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: "Notifications",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BusinessQueryScreen(),
                  ),
                );
                if (!mounted) return;
                ref.invalidate(queryListProvider);
              },
              icon: const Icon(
                Icons.notifications_outlined,
                size: 26,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 12),
      ],
    );
  }
  Widget _buildMobileLayout(
      BuildContext context,
      BusinessDashboardModel data,
      ) {
    final primary =
        Theme.of(context).colorScheme.primary;

    final customerCountAsync =
    ref.watch(customerCountProvider);

    final type = ref.read(appTypeProvider);
    final businessId = ref.read(businessIdProvider);

    final actions = DashboardText.actions(type);

    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        final currentBusinessId =
        ref.read(businessIdProvider);

        await ref.refresh(
          dashboardProvider(currentBusinessId).future,
        );

        await ref.refresh(
          customerProvider.future,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= REVENUE =================

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BusinessAnalysisScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _metricItem(
                        context: context,
                        title: "Revenue",
                        amount: data.totalIncomeValue,
                        growth:
                        data.revenueGrowthPercentValue,
                      ),
                    ),

                    Container(
                      height: 55,
                      width: 1,
                      color: Colors.white24,
                    ),

                    Expanded(
                      child: _metricItem(
                        context: context,
                        title: "Expenses",
                        amount:
                        data.totalExpensesValue,
                        growth:
                        data.expenseGrowthPercentValue,
                      ),
                    ),

                    Container(
                      height: 55,
                      width: 1,
                      color: Colors.white24,
                    ),

                    Expanded(
                      child: _metricItem(
                        context: context,
                        title: data.netValue >= 0
                            ? "Profit"
                            : "Loss",
                        amount: data.netValue.abs(),
                        growth:
                        data.profitGrowthPercentValue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================= METRICS =================

            GridView.count(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.22,
              children: [
                _MetricCard(
                  title: DashboardText.customer(type),
                  value: customerCountAsync.when(
                    data: (count) => count.toString(),
                    loading: () => "0",
                    error: (_, __) => "0",
                  ),
                  icon: Icons.people_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerListScreen(),
                      ),
                    );
                  },
                ),

                _MetricCard(
                  title: "Pending Amount",
                  value:
                  "₹${data.grandTotalPendingAmountValue.toStringAsFixed(0)}",
                  icon:
                  Icons.account_balance_wallet_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BusinessPurchaseHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ================= QUICK ACTIONS =================

            _buildQuickActionsMobile(
              context,
              type,
              actions,
              businessId,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  Widget _buildQuickActionsMobile(
      BuildContext context,
      AppType type,
      List<String> actions,
      int businessId,
      ) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          // ================= ROW 1 =================

          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  bgColor: Colors.grey.shade50,
                  title: DashboardText.customer(type),
                  icon: Icons.person_add_alt_1_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerListScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _ActionBtn(
                  bgColor: Colors.grey.shade50,
                  title: actions[1],
                  icon: Icons.payments_outlined,
                  onTap: () async {
                    final result =
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const AddIncomeScreen(),
                      ),
                    );

                    if (result == true) {
                      ref.refresh(
                        dashboardProvider(
                          businessId,
                        ).future,
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ================= ROW 2 =================

          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  bgColor: Colors.grey.shade50,
                  title: actions[2],
                  icon: Icons.receipt_long_outlined,
                  onTap: () async {
                    final result =
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const AddExpenseScreen(),
                      ),
                    );

                    if (result == true) {
                      ref.refresh(
                        dashboardProvider(
                          businessId,
                        ).future,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _ActionBtn(
                  bgColor: Colors.grey.shade50,
                  title: actions[3],
                  icon: Icons.calculate_outlined,
                  onTap: () async {
                    final result =
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const BusinessCalculatorScreen(),
                      ),
                    );

                    if (result == true) {
                      ref.refresh(
                        dashboardProvider(
                          businessId,
                        ).future,
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ================= ROW 3 =================

          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  bgColor: Colors.grey.shade50,
                  title: "Products",
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const ProductScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _ActionBtn(
                  bgColor: Colors.grey.shade50,
                  title: "Templates",
                  icon: Icons.description_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const BusinessTemplateScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ================= SEND REMINDER =================

          Container(
            decoration: BoxDecoration(
              color: primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _ActionBtn(
              bgColor: Colors.transparent,
              title:
              "Send Reminder to ${DashboardText.customer(type)}",
              icon: Icons.notifications_active_outlined,
              onTap: () async {
                final result =
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const BusinessRemindersScreen(),
                  ),
                );

                if (result == true) {
                  ref.refresh(
                    dashboardProvider(
                      businessId,
                    ).future,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDesktopLayout(
      BuildContext context,
      BusinessDashboardModel data,
      ) {
    final type = ref.read(appTypeProvider);
    final businessId = ref.read(businessIdProvider);

    final customerCountAsync =
    ref.watch(customerCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            vertical: 12
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1150,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =====================================================
                  // LEFT SIDE
                  // =====================================================

                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Financial Overview",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Revenue / Expense / Profit
                        _buildDesktopFinancialCard(
                          context,
                          data,
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Business Metrics",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [

                            // CUSTOMER
                            Expanded(
                              child: SizedBox(
                                height: 145,
                                child: _MetricCard(
                                  title:
                                  DashboardText.customer(type),
                                  value:
                                  customerCountAsync.when(
                                    data: (count) =>
                                        count.toString(),
                                    loading: () => "0",
                                    error: (_, __) => "0",
                                  ),
                                  icon:
                                  Icons.people_outline_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CustomerListScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // PENDING
                            Expanded(
                              child: SizedBox(
                                height: 145,
                                child: _MetricCard(
                                  title: "Pending Amount",
                                  value:
                                  "₹${data.grandTotalPendingAmountValue.toStringAsFixed(0)}",
                                  icon: Icons
                                      .account_balance_wallet_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BusinessPurchaseHistoryScreen(),
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

                  // =====================================================
                  // RIGHT SIDE
                  // =====================================================

                  Expanded(
                    flex: 4,
                    child: _buildDesktopQuickActions(
                      context,
                      type,
                      DashboardText.actions(type),
                      businessId,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildDesktopFinancialCard(
      BuildContext context,
      BusinessDashboardModel data,
      ) {
    final primary =
        Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BusinessAnalysisScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(.20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [

            Expanded(
              child: _desktopMetric(
                "Revenue",
                data.totalIncomeValue,
                data.revenueGrowthPercentValue,
                Icons.trending_up_rounded,
              ),
            ),

            _desktopVerticalDivider(),

            Expanded(
              child: _desktopMetric(
                "Expenses",
                data.totalExpensesValue,
                data.expenseGrowthPercentValue,
                Icons.receipt_long_outlined,
              ),
            ),

            _desktopVerticalDivider(),

            Expanded(
              child: _desktopMetric(
                data.netValue >= 0
                    ? "Profit"
                    : "Loss",
                data.netValue.abs(),
                data.profitGrowthPercentValue,
                data.netValue >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _desktopMetric(
      String title,
      double amount,
      double growth,
      IconData icon,
      ) {
    final isPositive = growth >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.white,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "₹${amount.toStringAsFixed(0)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),

          if (growth != 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  "${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _desktopVerticalDivider() {
    return Container(
      height: 100,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildDesktopQuickActions(
      BuildContext context,
      AppType type,
      List<String> actions,
      int businessId,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            "Manage your business quickly",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          _desktopAction(
            context,
            DashboardText.customer(type),
            Icons.person_add_alt_1_outlined,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerListScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _desktopAction(
            context,
            actions[1],
            Icons.payments_outlined,
                () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AddIncomeScreen(),
                ),
              );

              if (result == true) {
                ref.refresh(
                  dashboardProvider(
                    businessId,
                  ).future,
                );
              }
            },
          ),

          const SizedBox(height: 12),

          _desktopAction(
            context,
            actions[2],
            Icons.receipt_long_outlined,
                () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AddExpenseScreen(),
                ),
              );

              if (result == true) {
                ref.refresh(
                  dashboardProvider(
                    businessId,
                  ).future,
                );
              }
            },
          ),

          const SizedBox(height: 12),

          _desktopAction(
            context,
            actions[3],
            Icons.calculate_outlined,
                () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const BusinessCalculatorScreen(),
                ),
              );

              if (result == true) {
                ref.refresh(
                  dashboardProvider(
                    businessId,
                  ).future,
                );
              }
            },
          ),

          const SizedBox(height: 12),

          _desktopAction(
            context,
            "Products",
            Icons.inventory_2_outlined,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ProductScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _desktopAction(
            context,
            "Templates",
            Icons.description_outlined,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const BusinessTemplateScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _desktopAction(
            context,
            "Send Reminder to ${DashboardText.customer(type)}",
            Icons.notifications_active_outlined,
                () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const BusinessRemindersScreen(),
                ),
              );

              if (result == true) {
                ref.refresh(
                  dashboardProvider(
                    businessId,
                  ).future,
                );
              }
            },
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _desktopAction(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap, {
        bool highlighted = false,
      }) {
    final primary =
        Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: highlighted
                ? primary.withOpacity(.08)
                : Colors.grey.shade50,
            borderRadius:
            BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? primary.withOpacity(.18)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.10),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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


// Widget _buildContent(
  //   BuildContext context,
  //   BusinessDashboardModel data,
  //   List<String> metrics,
  //   List<String> actions,
  // ) {
  //   final primary = Theme.of(context).colorScheme.primary;
  //   final customerCountAsync = ref.watch(customerCountProvider);
  //   final type = ref.read(appTypeProvider);
  //   return RefreshIndicator(
  //     color: primary,
  //     onRefresh: () async {
  //       print("REFRESH START");
  //
  //       final currentBusinessId = ref.read(businessIdProvider);
  //
  //       final dashboard = await ref.refresh(
  //         dashboardProvider(currentBusinessId).future,
  //       );
  //
  //       print(dashboard.totalIncomeValue);
  //
  //       await ref.refresh(customerProvider.future);
  //
  //       print("REFRESH END");
  //     },
  //     child: SingleChildScrollView(
  //       physics: const AlwaysScrollableScrollPhysics(),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           children: [
  //             /// ================= REVENUE CARD =================
  //             GestureDetector(
  //               onTap: (){
  //                 Navigator.push(context, MaterialPageRoute(builder: (context)=> BusinessAnalysisScreen()));
  //               },
  //               child: Container(
  //                 width: double.infinity,
  //                 padding: const EdgeInsets.all(18),
  //                 decoration: BoxDecoration(
  //                   color: primary,
  //                   borderRadius: BorderRadius.circular(24),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: primary.withOpacity(.25),
  //                       blurRadius: 20,
  //                       offset: const Offset(0, 8),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Expanded(
  //                       child: _metricItem(
  //                         context: context,
  //                         title: "Revenue",
  //                         amount: data.totalIncomeValue,
  //                         growth: data.revenueGrowthPercentValue,
  //                       ),
  //                     ),
  //
  //                     Container(
  //                       height: 55,
  //                       width: 1,
  //                       color: Colors.white.withOpacity(.25),
  //                     ),
  //
  //                     Expanded(
  //                       child: _metricItem(
  //                         context: context,
  //                         title: "Expenses",
  //                         amount: data.totalExpensesValue,
  //                         growth: data.expenseGrowthPercentValue,
  //                       ),
  //                     ),
  //
  //                     Container(
  //                       height: 55,
  //                       width: 1,
  //                       color: Colors.white.withOpacity(.25),
  //                     ),
  //
  //                     Expanded(
  //                       child: _metricItem(
  //                         context: context,
  //                         title: data.netValue >= 0 ? "Profit" : "Loss",
  //                         amount: data.netValue.abs(),
  //                         growth: data.profitGrowthPercentValue,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //
  //             const SizedBox(height: 10),
  //
  //             /// ================= METRICS =================
  //             GridView.count(
  //               shrinkWrap: true,
  //               physics: const NeverScrollableScrollPhysics(),
  //               crossAxisCount: 2,
  //               crossAxisSpacing: 14,
  //               mainAxisSpacing: 14,
  //               childAspectRatio: 1.22,
  //               children: [
  //                 _MetricCard(
  //                   title: DashboardText.customer(type),
  //                   value: customerCountAsync.when(
  //                     data: (count) => count.toString(),
  //                     loading: () => "0",
  //                     error: (_, __) => "0",
  //                   ),
  //                   icon: Icons.people_outline,
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(builder: (_) => CustomerListScreen()),
  //                     );
  //                   },
  //                 ),
  //
  //                 _MetricCard(
  //                   title: "Pending Amount",
  //                   value:
  //                       "₹${data.grandTotalPendingAmountValue.toStringAsFixed(0)}",
  //                   icon: Icons.account_balance_wallet_outlined,
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => BusinessPurchaseHistoryScreen(),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 6),
  //
  //             Container(
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(20),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.black.withOpacity(0.05),
  //                     blurRadius: 18,
  //                     offset: const Offset(0, 8),
  //                   ),
  //                 ],
  //                 border: Border.all(
  //                   color: Colors.grey.shade200,
  //                 ),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //
  //                   const Text(
  //                     "Quick Actions",
  //                     style: TextStyle(
  //                       fontSize: 17,
  //                       fontWeight: FontWeight.w700,
  //                     ),
  //                   ),
  //
  //                   const SizedBox(height: 6),
  //
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: _ActionBtn(
  //                           bgColor: Colors.grey.shade50,
  //                           title: DashboardText.customer(type),
  //                           icon: Icons.person_add_alt_1_outlined,
  //                           onTap: () {
  //                             Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (_) => CustomerListScreen(),
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                       Expanded(
  //                         child: _ActionBtn(
  //                           bgColor: Colors.grey.shade50,
  //                           title: actions[1],
  //                           icon: Icons.payments_outlined,
  //                           onTap: () async {
  //                             final result = await Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (_) => const AddIncomeScreen(),
  //                               ),
  //                             );
  //
  //                             if (result == true) {
  //                               ref.refresh(dashboardProvider(businessId).future);
  //                             }
  //                           },
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //
  //                   const SizedBox(height: 6),
  //
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: _ActionBtn(
  //                           bgColor: Colors.grey.shade50,
  //                           title: actions[2],
  //                           icon: Icons.receipt_long_outlined,
  //                           onTap: () async {
  //                             final result = await Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (_) => const AddExpenseScreen(),
  //                               ),
  //                             );
  //
  //                             if (result == true) {
  //                               ref.refresh(dashboardProvider(businessId).future);
  //                             }
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                       Expanded(
  //                         child: _ActionBtn(
  //                           bgColor: Colors.grey.shade50,
  //                           title: actions[3],
  //                           icon: Icons.calculate_outlined,
  //                           onTap: () async {
  //                             final result = await Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (_) => const BusinessCalculatorScreen(),
  //                               ),
  //                             );
  //
  //                             if (result == true) {
  //                               ref.refresh(dashboardProvider(businessId).future);
  //                             }
  //                           },
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //
  //                   const SizedBox(height: 6),
  //
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: _ActionBtn(
  //                           bgColor: Colors.grey.shade50,
  //                           title: "Products",
  //                           icon: Icons.inventory_2_outlined,
  //                           onTap: () {
  //                             Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (_) => const ProductScreen(),
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                       const Expanded(child: SizedBox()),
  //                     ],
  //                   ),
  //
  //                   const SizedBox(height: 8),
  //
  //                   Container(
  //                     decoration: BoxDecoration(
  //                       color: primary.withOpacity(.08),
  //                       borderRadius: BorderRadius.circular(14),
  //                     ),
  //                     child: _ActionBtn(
  //                       bgColor: Colors.transparent,
  //                       title: "Send Reminder to ${DashboardText.customer(type)}",
  //                       icon: Icons.notifications_active_outlined,
  //                       onTap: () async {
  //                         final result = await Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder: (_) => const BusinessRemindersScreen(),
  //                           ),
  //                         );
  //
  //                         if (result == true) {
  //                           ref.refresh(dashboardProvider(businessId).future);
  //                         }
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 30),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

Widget _metricItem({
  required String title,
  required double amount,
  required double growth,
  required BuildContext context,
}) {
  final isPositive = growth >= 0;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),
        Text(
            "₹${amount.toStringAsFixed(0)}",
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

        const SizedBox(height: 6),

        if (growth != 0)
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: isPositive ? Colors.white : Colors.white,
              ),

              const SizedBox(width: 4),

              Text(
                "${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: isPositive ? Colors.white : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

/// ================= METRIC CARD =================
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
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: primary.withOpacity(0.1),
              ),
              child: Icon(icon, color: primary,size: 20,),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ACTION BUTTON =================
class _ActionBtn extends StatelessWidget {
  final String title;
  final Color bgColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.title,
    required this.icon,
    this.onTap,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        splashColor: primary.withOpacity(0.08),
        highlightColor: primary.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: primary.withOpacity(0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(icon, color: primary, size: 16),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
