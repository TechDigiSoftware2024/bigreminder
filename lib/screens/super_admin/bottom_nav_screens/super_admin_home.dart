import 'package:bigreminder/screens/super_admin/supAd_home_screens/business_list.dart';
import 'package:bigreminder/screens/super_admin/supAd_home_screens/user_list_screen.dart';
import 'package:bigreminder/theme/app_colors.dart';
import 'package:bigreminder/widgets/custom_kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuperAdminHome extends ConsumerWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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

      body: SingleChildScrollView(
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
                CustomKPICard(title: "Total Users", value: "1,240",icon: Icons.people, onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserListScreen()));
                }),
                CustomKPICard(title : "Active Today",value: "320",icon: Icons.flash_on, onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessListPage()));
                }),
                CustomKPICard(title: "Businesses",value: "85",icon: Icons.store, onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessListPage()));
                }),
                CustomKPICard(title: "Revenue",value: "₹24K",icon: Icons.currency_rupee, onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessListPage()));
                }),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    icon: Icons.workspace_premium_outlined,
                    title: "Manage Plans",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// 🚨 ALERT
            const Text(
              "System Alerts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            _alertCard(
              title: "High Pending Payments",
              subtitle: "18 users pending renewal",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= KPI CARD =================


  // ================= ACTION CARD =================
  Widget _actionCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
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
            child:  Icon(icon, color: AppColors.primaryDark),
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