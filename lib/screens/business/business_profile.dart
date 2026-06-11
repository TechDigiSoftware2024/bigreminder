import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/screens/business/business_query_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/auth_state.dart';
import '../../providers/business/business_provider.dart';
import '../../services/auth/auth_controller.dart';
import '../../widgets/custom_dialog.dart';

class BusinessProfile extends ConsumerWidget {
  const BusinessProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final businessName = ref.watch(businessNameProvider,);
    final business = ref.watch((currentBusinessProvider));
      print("BusinessName:${businessName.toString()}");

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final isLogout =
          prev?.user != null && next.user == null && next.isLoading == false;

      if (isLogout) {
        Navigator.pushAndRemoveUntil(
          context,

          MaterialPageRoute(builder: (_) => const LoginScreen()),

          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),

        slivers: [
          /// 🔥 APP BAR
          SliverAppBar(
            pinned: true,

            expandedHeight: 150,

            elevation: 0,

            backgroundColor: theme.primaryColor,

            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),

                          borderRadius: BorderRadius.circular(100),
                        ),

                        child: const Text(
                          "Business Profile",

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        businessName.toString(),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Manage your business smarter",

                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),

                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 🔥 BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// 🔥 BUSINESS DETAILS
                  Text(
                    "Business Details",

                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _infoTile(
                    context,
                    icon: Icons.business,
                    title: "Business Type",
                    subtitle:business?.category ?? "N/A",
                  ),
                  _infoTile(
                    context,
                    icon: Icons.numbers,
                    title: "Business ID",
                    subtitle:business?.id.toString() ?? "N/A",
                  ),

                  // _infoTile(
                  //   context,
                  //   icon: Icons.document_scanner_outlined,
                  //   title: "Business PAN - AADHAAR NUMBER",
                  //   subtitle: business?.doc.toString() ?? "N/A",
                  // ),
                  _infoTile(
                    context,
                    icon: Icons.location_on,
                    title: "Business Address",
                    subtitle: business?.address ?? "N/A",
                  ),

                  // _infoTile(
                  //   context,
                  //   icon: Icons.calendar_month,
                  //   title: "Joined On",
                  //   subtitle: "12 Jan 2026",
                  // ),

                  _settingTile(
                    context,
                    icon: Icons.lock_outline,
                    title: "Privacy & Security",
                    onTap:  (){},
                  ),

                  _settingTile(
                    context,
                    icon: Icons.support_agent,
                    title: "Support",
                    onTap:  (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> BusinessQueryScreen()));
                    },
                  ),

                  _settingTile(
                    context,
                    icon: Icons.info_outline,
                    title: "About App",
                    onTap:  (){},
                  ),

                  const SizedBox(height: 26),

                  /// 🔥 LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,

                        backgroundColor: Colors.red.shade50,

                        foregroundColor: Colors.red,

                        padding: const EdgeInsets.symmetric(vertical: 15),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      onPressed: () {
                        CustomDialog.showConfirmDialog(
                          context: context,

                          title: 'Confirm Logout',

                          message:
                              'Are you sure you wanna logout from Biz Reminder?',

                          onConfirm: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                          },
                        );
                      },

                      icon: const Icon(Icons.logout),

                      label: const Text(
                        "Logout",

                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),

            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),

            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: theme.primaryColor),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,

                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
        required VoidCallback onTap,
    required String title,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),

            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

        leading: Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),

            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: theme.primaryColor),
        ),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey.shade500,
        ),

        onTap:onTap,
      ),
    );
  }
}
