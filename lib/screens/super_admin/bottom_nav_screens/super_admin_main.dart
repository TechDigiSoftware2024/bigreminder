import 'dart:ui';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/settings_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/subscription_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/super_admin_home.dart';
import 'package:bigreminder/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../auth/signup_screen.dart';
import 'notification_screen.dart';

class SuperAdminMain extends StatefulWidget {
  const SuperAdminMain({super.key});

  @override
  State<SuperAdminMain> createState() => _SuperAdminMainState();
}

class _SuperAdminMainState extends State<SuperAdminMain> {
  int currentIndex = 0;

  final List<Widget> screens = [
    SuperAdminHome(),        // 0
    SubscriptionScreen(),    // 1
    SizedBox(),              // 2 (center - not used)
    NotificationScreen(),    // 3
    SettingsScreen(),        // 4
  ];

  void onTabChange(int index) {
    if (index == 2) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.15), // soft dim
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // glass effect
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85), // glass white
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // 🔹 Top Icon (subtle)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Icon(
                        Icons.add_business_rounded,
                        size: 24,
                        color: AppColors.iconColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Title
                    const Text(
                      "Create Business",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 🔹 Subtitle
                    Text(
                      "Quickly onboard a new business account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 🔥 Primary Button (clean)
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignupScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.buttonPrimaryBg, // strong contrast CTA
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              "Create Business Account",
                              style: TextStyle(
                                color: AppColors.buttonPrimaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Secondary Action
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    setState(() => currentIndex = index);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              /// Dashboard
              _navItem(Icons.home_rounded, "Dashboard", 0),

              /// Subscriptions
              _navItem(Icons.wallet_rounded, "Subscriptions", 1),

              /// CENTER BUTTON
              GestureDetector(
                onTap: () => onTabChange(2),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:  AppColors.primaryDark
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),

              /// Notification
              _navItem(Icons.bar_chart_rounded, "Notification", 3),

              /// Settings
              _navItem(Icons.person_rounded, "Settings", 4),
            ],
          ),
        ),
      ),
    );

  }Widget _navItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabChange(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: isSelected
                ? BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            )
                : null,
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ?  AppColors.primaryDark
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}