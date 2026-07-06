import 'package:bigreminder/screens/business/business_dash_screens/business_calculator_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/business_reminder_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/customer_list_screen.dart';
import 'package:bigreminder/screens/business/business_purchase_history.dart';
import 'package:bigreminder/screens/business/business_query_screen.dart';
import 'package:flutter/material.dart';
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

      /// ✅ KEEP AppType but cleaner title
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          businessName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        actions: [
          queryList.when(
            data: (queries) {
              final openCount = queries.where((q) {
                final status = q.status.toLowerCase().trim();

                return status != 'resolved' &&
                    status != 'completed' &&
                    status != 'closed';
              }).length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusinessQueryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 26,
                    ),
                  ),

                  if (openCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          openCount > 9 ? '9+' : '$openCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: dashboardAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (data) {
          return _buildContent(context, data, metrics, actions);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BusinessDashboardModel data,
    List<String> metrics,
    List<String> actions,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final customerCountAsync = ref.watch(customerCountProvider);

    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        print("REFRESH START");

        final currentBusinessId = ref.read(businessIdProvider);

        final dashboard = await ref.refresh(
          dashboardProvider(currentBusinessId).future,
        );

        print(dashboard.totalIncomeValue);

        await ref.refresh(customerProvider.future);

        print("REFRESH END");
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// ================= REVENUE CARD =================
              Container(
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
                        title: "Revenue",
                        amount: data.totalIncomeValue,
                        growth: data.revenueGrowthPercentValue,
                      ),
                    ),

                    Container(
                      height: 55,
                      width: 1,
                      color: Colors.white.withOpacity(.25),
                    ),

                    Expanded(
                      child: _metricItem(
                        title: "Expenses",
                        amount: data.totalExpensesValue,
                        growth: data.expenseGrowthPercentValue,
                      ),
                    ),

                    Container(
                      height: 55,
                      width: 1,
                      color: Colors.white.withOpacity(.25),
                    ),

                    Expanded(
                      child: _metricItem(
                        title: data.netValue >= 0 ? "Profit" : "Loss",
                        amount: data.netValue.abs(),
                        growth: data.profitGrowthPercentValue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// ================= METRICS =================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.22,
                children: [
                  _MetricCard(
                    title: metrics[0],
                    value: customerCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => "0",
                      error: (_, __) => "0",
                    ),
                    icon: Icons.people_alt_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CustomerListScreen()),
                      );
                    },
                  ),

                  _MetricCard(
                    title: "Pending Amount",
                    value:
                        "₹${data.grandTotalPendingAmountValue.toStringAsFixed(0)}",
                    icon: Icons.account_balance_wallet_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessPurchaseHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Container(
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            bgColor: Colors.grey.shade50,
                            title: actions[0],
                            icon: Icons.person_add_alt_1_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerListScreen(),
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
                            icon: Icons.payments_rounded,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddIncomeScreen(),
                                ),
                              );

                              if (result == true) {
                                ref.refresh(dashboardProvider(businessId).future);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            bgColor: Colors.grey.shade50,
                            title: actions[2],
                            icon: Icons.receipt_long_rounded,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddExpenseScreen(),
                                ),
                              );

                              if (result == true) {
                                ref.refresh(dashboardProvider(businessId).future);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionBtn(
                            bgColor: Colors.grey.shade50,
                            title: actions[3],
                            icon: Icons.calculate_rounded,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BusinessCalculatorScreen(),
                                ),
                              );

                              if (result == true) {
                                ref.refresh(dashboardProvider(businessId).future);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            bgColor: Colors.grey.shade50,
                            title: "Products",
                            icon: Icons.inventory_2_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _ActionBtn(
                        bgColor: Colors.transparent,
                        title: "Send Reminder to Customer",
                        icon: Icons.notifications_active_outlined,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessRemindersScreen(),
                            ),
                          );

                          if (result == true) {
                            ref.refresh(dashboardProvider(businessId).future);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _metricItem({
  required String title,
  required double amount,
  required double growth,
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

        const SizedBox(height: 8),

        Text(
          "₹${amount.toStringAsFixed(0)}",
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: primary.withOpacity(0.1),
              ),
              child: Icon(icon, color: primary),
            ),
            const Spacer(),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        splashColor: primary.withOpacity(0.08),
        highlightColor: primary.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
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
                    fontSize: 14,
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
