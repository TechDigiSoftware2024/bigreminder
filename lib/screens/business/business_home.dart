import 'package:bigreminder/screens/business/business_dash_screens/business_calculator_screen.dart';
import 'package:bigreminder/screens/business/business_dash_screens/customer_list_screen.dart';
import 'package:flutter/material.dart';
import '../../utils/enum_classes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("businessId") ?? 0;
    final busName = prefs.getString("businessName") ?? "";
    setState(() {
      businessId = id;
      businessName = busName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final metrics = DashboardText.metrics(widget.type);
    final actions = DashboardText.actions(widget.type);

    if (businessId == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dashboardAsync = ref.watch(dashboardProvider(businessId));

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      /// ✅ KEEP AppType but cleaner title
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          businessName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
        await ref.refresh(dashboardProvider(businessId).future);
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
                childAspectRatio: 1.2,
                children: [

                  _MetricCard(
                    title: metrics[0],
                    value: customerCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => "...",
                      error: (_, __) => "0",
                    ),
                    icon: Icons.people,
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
                    title: metrics[2],
                    value: "₹${data.totalExpensesValue.toStringAsFixed(0)}",
                    icon: Icons.warning,
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

              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      title: actions[0],
                      icon: Icons.person_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerListScreen(type: widget.type),
                          ),
                        );
                      },
                    ),
                  ),

                  /// 💰 ADD INCOME
                  Expanded(
                    child: _ActionBtn(
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
                          await ref.refresh(dashboardProvider(businessId).future);
                        }
                      },
                    ),
                  ),

                  /// 💸 ADD EXPENSE
                  Expanded(
                    child: _ActionBtn(
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
                          await ref.refresh(dashboardProvider(businessId).future);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _ActionBtn(
                      title: actions[3],
                      icon: Icons.calculate_outlined,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessCalculatorScreen(),
                          ),
                        );

                        if (result == true) {
                          await ref.refresh(dashboardProvider(businessId).future);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ================= FEATURES =================
              if (data.features.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: data.features.map((f) {
                      final enabled = f.enabled;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: enabled
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              enabled ? Icons.check : Icons.lock,
                              size: 16,
                              color: enabled ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              f.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: enabled ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

/// ================= METRIC CARD =================
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap; // ✅ NEW

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector( // ✅ ADDED
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.1),
              child: Icon(icon, color: primary),
            ),
            const Spacer(),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
String _getStatusText(String status) {
  if (status.toLowerCase().contains("active")) return "Active";
  if (status.toLowerCase().contains("expired")) return "Expired";
  return "Inactive";
}

/// ================= ACTION BUTTON =================
class _ActionBtn extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.title,
    this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: primary),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}