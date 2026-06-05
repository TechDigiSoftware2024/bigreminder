import 'package:bigreminder/screens/business/business_home.dart' hide AppType;
import 'package:bigreminder/screens/business/business_notification.dart';
import 'package:flutter/material.dart';
import '../screens/business/business_profile.dart';
import '../screens/business/business_subs_screen.dart';
import '../utils/enum_classes.dart';

// ================= SCREENS =================
List<Widget> getBottomBarScreens(AppType type) {

  return [

    BusinessHome(type: type), // 0

    BusinessSubscriptionScreen(), // 1

    const SizedBox(), // 2 CENTER BUTTON PLACEHOLDER

    BusinessNotificationScreen(), // 3

    BusinessProfile(), // 4
  ];
}


//✅ LABELS (fixed + generic safe)
List<String> getBottomBarLabels(AppType type) {
  return const [
    "Home",
    "Plans",
    " ",
    "Notify",
    "Profile",
  ];

}