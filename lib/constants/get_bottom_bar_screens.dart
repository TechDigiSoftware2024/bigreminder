import 'package:bigreminder/screens/business/business_home.dart' hide AppType;
import 'package:bigreminder/screens/business/business_notification.dart';
import 'package:bigreminder/screens/business/create_purchase_screen.dart';
import 'package:flutter/material.dart';
import '../screens/business/business_profile.dart';
import '../screens/business/business_purchase_history.dart';
import '../screens/business/business_subs_screen.dart';
import '../utils/enum_classes.dart';

// ================= SCREENS =================
List<Widget> getBottomBarScreens(AppType type) {

  return [
    BusinessHome(type: type),
    // BusinessSubscriptionScreen(),
    BusinessPurchaseHistoryScreen(),
    CreatePurchaseScreen(),
    BusinessNotificationScreen(),
    BusinessProfile(),
  ];
}


//✅ LABELS (fixed + generic safe)
List<String> getBottomBarLabels(AppType type) {
  return const [
    "Home",
    "Invoices",
    "Billing",
    "Reminders",
    "Profile",
  ];

}