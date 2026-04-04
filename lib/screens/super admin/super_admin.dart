import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/widgets/custom_app_bar.dart';
import 'package:bigreminder/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/enum_classes.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_container.dart';

class SuperAdminHome extends ConsumerWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final theme = Theme.of(context);
    final type = ref.watch(appTypeProvider);

    return Scaffold(
      appBar: CustomAppBar(title: _getTitle(type),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 Heading
            Text(
              "Welcome to Biz Reminder",
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),

            Text(
              _getSubtitle(type),
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            /// 🔹 Summary Cards
            Row(
              children: [
                Expanded(child: _infoCard(context, "Total", _getMainStat(type))),
                const SizedBox(width: 12),
                Expanded(child: _infoCard(context, "Pending", _getSecondaryStat(type))),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 Role-specific Section
            _buildRoleSection(context,type),

            // const SizedBox(height: 8),
            // CustomContainer(icon: Icons.currency_rupee_outlined, title: "Rupees", subtitle: "Indian currency"),
            const SizedBox(height: 20),
            /// 🔹 Actions
            Text("Quick Actions", style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: _getPrimaryAction(type), isLoading: false, onTap: () {  },

                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomButton(label: 'View All',variant: ButtonVariant.outline,onTap: (){},)
                )
              ],
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(appTypeProvider.notifier).update((state) {
                  switch (state) {
                    case AppType.gym:
                      return AppType.shop;

                    case AppType.shop:
                      return AppType.institute;

                    case AppType.institute:
                      return AppType.gym;
                  }
                });
              },
              child: Text("Switch"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================== 🔥 COMMON CARD ==================
  Widget _infoCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 112,
      child: CustomCard(
        showBorder: true,
        padding: const EdgeInsets.all(16), // 👈 optional (you already have default)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 6),

            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ================== 🧠 ROLE LOGIC ==================

  String _getTitle( AppType type) {
    switch (type) {
      case AppType.gym:
        return "Gym Dashboard";
      case AppType.shop:
        return "Shop Dashboard";
      case AppType.institute:
        return "Institute Dashboard";
    }
  }

  String _getSubtitle(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Track members & fees";
      case AppType.shop:
        return "Manage customers & udhaar";
      case AppType.institute:
        return "Monitor students & courses";
    }
  }

  String _getMainStat(AppType type) {
    switch (type) {
      case AppType.gym:
        return "120 Members";
      case AppType.shop:
        return "₹45,000 Sales";
      case AppType.institute:
        return "80 Students";
    }
  }

  String _getSecondaryStat(AppType type) {
    switch (type) {
      case AppType.gym:
        return "₹8,000 Due";
      case AppType.shop:
        return "₹12,000 Udhaar";
      case AppType.institute:
        return "12 Fees Pending";
    }
  }

  String _getPrimaryAction(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Add Member";
      case AppType.shop:
        return "Add Customer";
      case AppType.institute:
        return "Add Student";
    }
  }

  // ================== 🎯 ROLE UI ==================

  Widget _buildRoleSection(BuildContext context,AppType type) {
    switch (type) {
      case AppType.gym:
        return CustomContainer(
          icon: Icons.fitness_center,
          title: "Today's Attendance",
          subtitle: "85 Members Checked In",
        );

      case AppType.shop:
        return CustomContainer(
          icon: Icons.store,
          title: "Inventory Status",
          subtitle: "12 Items Low Stock",
        );

      case AppType.institute:
        return CustomContainer(
          icon: Icons.school,
          title: "Today's Classes",
          subtitle: "5 Classes Scheduled",
        );
    }
  }

// ================== 🧱 COMMON SECTION UI ==================

// Widget _sectionContainer(
//     BuildContext context, {
//       required IconData icon,
//       required String title,
//       required String subtitle,
//     }) {
//   final theme = Theme.of(context);
//
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: theme.colorScheme.primary.withOpacity(0.08),
//       borderRadius: BorderRadius.circular(16),
//     ),
//     child: Row(
//       children: [
//         Icon(icon, color: theme.colorScheme.primary),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: theme.textTheme.titleMedium),
//               const SizedBox(height: 4),
//               Text(subtitle, style: theme.textTheme.bodySmall),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }
}