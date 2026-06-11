import 'package:bigreminder/screens/business/business_dash_screens/business_calculator_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/business_reminder_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/customer_list_screen.dart';
import 'package:flutter/material.dart';
import '../../utils/enum_classes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/business_models/business_dashboard_model.dart';
import '../../providers/business/business_provider.dart';
import 'business_dash_screens/add_expense_screen.dart';
import 'business_dash_screens/add_income_screen.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      /// ✅ KEEP AppType but cleaner title
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          businessName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
        ref.invalidate(dashboardProvider(businessId));
        ref.invalidate(customerProvider);

        await Future.wait([
          ref.read(dashboardProvider(businessId).future),
          ref.read(customerProvider.future),
        ]);
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    /// 🔵 REVENUE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Revenue",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${data.totalIncomeValue.toStringAsFixed(0)}",
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// DIVIDER
                    Container(
                      height: 45,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white.withOpacity(0.3),
                    ),

                    /// 🟠 EXPENSE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Expenses",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${data.totalExpensesValue.toStringAsFixed(0)}",
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// DIVIDER
                    Container(
                      height: 45,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white.withOpacity(0.3),
                    ),

                    /// 🟢 NET
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.netValue >= 0 ? "Net Profit" : "Net Loss",
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${data.netValue.toStringAsFixed(0)}",
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                        MaterialPageRoute(
                          builder: (_) => CustomerListScreen(type: widget.type),
                        ),
                      );
                    },
                  ),

                  _MetricCard(
                    title: "Pending Amount",
                    value: "₹6520",
                    icon: Icons.account_balance_wallet_rounded,
                  ),

                  _MetricCard(
                    title: "Current Plan",
                    value: "Free" ?? "Active Plan",
                    icon: Icons.workspace_premium_rounded,
                  ),

                  _MetricCard(
                    title: "Monthly Growth",
                    value: "+92%",
                    icon: Icons.trending_up,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ================= QUICK ACTIONS =================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 6),

              Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          bgColor: Colors.white,
                          title: actions[0],
                          icon: Icons.person_add,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerListScreen(type: widget.type),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          bgColor: Colors.white,
                          title: actions[1],
                          icon: Icons.payment,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddIncomeScreen(),
                              ),
                            );
                            if (result == true) {
                              await ref.refresh(
                                dashboardProvider(businessId).future,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          bgColor: Colors.white,
                          title: actions[2],
                          icon: Icons.receipt_long,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddExpenseScreen(),
                              ),
                            );
                            if (result == true) {
                              await ref.refresh(
                                dashboardProvider(businessId).future,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          bgColor: Colors.white,
                          title: actions[3],
                          icon: Icons.calculate_outlined,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BusinessCalculatorScreen(),
                              ),
                            );
                            if (result == true) {
                              await ref.refresh(
                                dashboardProvider(businessId).future,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          bgColor: primary.withOpacity(0.08),
                          title: "Send Reminder to Customer",
                          icon: Icons.notifications_on_outlined,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BusinessRemindersScreen(),
                              ),
                            );
                            if (result == true) {
                              await ref.refresh(
                                dashboardProvider(businessId).future,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
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

  const _ActionBtn({required this.title, required this.icon, this.onTap,required this.bgColor});

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
