import 'package:bigreminder/screens/business/business_home.dart' hide AppType;
import 'package:bigreminder/screens/business/business_notification.dart';
import 'package:flutter/material.dart';
import '../screens/business/business_profile.dart';
import '../screens/business/business_staff.dart';
import '../utils/enum_classes.dart';

// ================= SCREENS =================
List<Widget> getBottomBarScreens(AppType type) {
  final commonScreens = [
    BusinessHome(type: type),
    BusinessStaff(),
    const SizedBox(),
    BusinessNotificationScreen(),
    BusinessProfile(),
  ];

  // 🔥 All types use same structure for now
  return commonScreens;
}


//✅ LABELS (fixed + generic safe)
List<String> getBottomBarLabels(AppType type) {
  return const [
    "Home",
    "Manage",
    " ",
    "Notify",
    "Profile",
  ];

}