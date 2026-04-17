import 'package:bigreminder/widgets/custom_kpi_card.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.appBarBg,
        title: const Text(
          "Subscriptions",
          style: TextStyle(fontWeight: FontWeight.w600,color: AppColors.appBarText),
        ),
      ),
// my name is noor s
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 KPI GRID (MATCH DASHBOARD)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: [
                CustomKPICard(title: "Total Users",value:  "1,240",icon: Icons.people,onTap: (){},),
                CustomKPICard(title:"Active Plans",value:  "320",icon: Icons.verified,onTap: (){},),
                CustomKPICard(title:"Monthly Revenue",value:  "₹24,000",icon: Icons.currency_rupee,onTap: (){},),
                CustomKPICard(title:"Expiring Soon",value:  "18",icon: Icons.warning_amber,onTap: (){},),
              ],
            ),

            const SizedBox(height: 24),

            /// 🔹 SECTION TITLE
            const Text(
              "Plans",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            /// 🔹 PLAN CARDS (PREMIUM)
            _planCard(
              title: "Basic Plan",
              price: "₹49/month",
              users: "120 users",
            ),

            const SizedBox(height: 12),

            _planCard(
              title: "Pro Plan",
              price: "₹99/month",
              users: "200 users",
              isHighlighted: true,
            ),

            const SizedBox(height: 12),

            _premiumPlanCard(
              title: "Premium Plan",
              price: "₹199/month",
              users: "350 users",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// ================= PLAN CARD =================
Widget _planCard({
  required String title,
  required String price,
  required String users,
  bool isHighlighted = false,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isHighlighted
            ? AppColors.primaryLight
            : Colors.grey.shade200,
        width: isHighlighted ? 1.5 : 1,
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
        /// LEFT
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const Spacer(),

        /// RIGHT
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              users,
              style: TextStyle(color: Colors.grey.shade600,fontWeight: FontWeight.w600),
            ),
            if (isHighlighted)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Most Popular",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

Widget _premiumPlanCard({
  required String title,
  required String price,
  required String users,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ],
    ),
    child: Row(
      children: [
        /// LEFT
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  "Premium Plan",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.workspace_premium,
                    size: 16, color: Colors.white),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const Spacer(),

        /// RIGHT
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              users,
              style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Best Value",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}