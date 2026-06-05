import 'package:bigreminder/providers/business/business_provider.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/notification_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/subscription_screen.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/business_list.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/super_admin_qeury_screen.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/user_list_screen.dart';
import 'package:bigreminder/services/super_admin/subscription_service.dart';
import 'package:bigreminder/theme/app_colors.dart';
import 'package:bigreminder/widgets/custom_kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/super_admin/super_admin_provider.dart';
class SuperAdminHome extends ConsumerStatefulWidget {
  const SuperAdminHome({super.key});

  @override
  ConsumerState<SuperAdminHome> createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends ConsumerState<SuperAdminHome> {

  @override
  Widget build(BuildContext context) {
    final queryAsync = ref.watch(adminQueryProvider);
    /// 🔥 PROVIDERS (NEW)
    final usersAsync = ref.watch(userProvider);
    final businessAsync = ref.watch(businessListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryDark,
        title: const Text(
          "Super Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),

      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          await Future.wait([
            ref.refresh(userProvider.future),
            ref.refresh(businessListProvider.future),
            ref.refresh(adminQueryProvider.future)
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 📊 KPI GRID
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                children: [

                  /// 👤 USERS (FIXED)
                  CustomKPICard(
                    title: "Total Users",
                    value: usersAsync.when(
                      data: (list) => list.length.toString(),
                      loading: () => "...",
                      error: (_, __) => "0",
                    ),
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserListScreen()),
                      );
                    },
                  ),

                  /// ⚡ ACTIVE (same)
                  CustomKPICard(
                    title: "Active Today",
                    value: "320",
                    icon: Icons.flash_on,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BusinessListPage()),
                      );
                    },
                  ),

                  /// 🏪 BUSINESSES (FIXED)
                  CustomKPICard(
                    title: "Businesses",
                    value: businessAsync.when(
                      data: (list) => list.length.toString(),
                      loading: () => "...",
                      error: (_, __) => "0",
                    ),
                    icon: Icons.store,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BusinessListPage()),
                      );
                    },
                  ),

                  /// 💰 REVENUE (same)
                  CustomKPICard(
                    title: "Revenue",
                    value: "₹24K",
                    icon: Icons.currency_rupee,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BusinessListPage()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// ⚡ QUICK ACTIONS
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      icon: Icons.notifications_none,
                      title: "Send Notification",
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      icon: Icons.workspace_premium_outlined,
                      title: "Manage Plans",
                        onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionScreen()));
                        }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const SuperAdminQueryScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.question_answer_outlined,
                                color: Colors.orange,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  const Text(
                                    "Business Support Requests",
                                    style: TextStyle(
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  queryAsync.when(
                                    data: (queries) {

                                      final openCount =
                                          queries
                                              .where(
                                                (q) =>
                                            q.status
                                                .toLowerCase() ==
                                                "open",
                                          )
                                              .length;

                                      return Text(
                                        "$openCount Open Requests",
                                        style: TextStyle(
                                          color: openCount > 0
                                              ? Colors.orange
                                              : Colors.green,
                                          fontWeight:
                                          FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                    loading: () =>
                                    const Text(
                                      "Loading...",
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                    error: (_, __) =>
                                    const Text(
                                      "0 Open Requests",
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            queryAsync.when(
                              data: (queries) {

                                final openCount =
                                    queries
                                        .where(
                                          (q) =>
                                      q.status
                                          .toLowerCase() ==
                                          "open",
                                    )
                                        .length;

                                if (openCount == 0) {
                                  return const SizedBox();
                                }

                                return Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius:
                                    BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: Text(
                                    openCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              loading: () =>
                              const SizedBox(),
                              error: (_, __) =>
                              const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ACTION CARD =================
  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ALERT =================
  Widget _alertCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: Colors.red.shade400, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}