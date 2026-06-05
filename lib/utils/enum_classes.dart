import 'package:flutter/material.dart';

// ================= ENUM =================
enum ButtonVariant { filled, outline, ghost }
enum AppType {
  gym,
  shop,
  institute,
  salon,
  hospital,
  restaurant,
  finance,
  realEstate,
  generic,
}
// ================= SUBSCRIPTION =================
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  paused,
  trial,
  grace,
}

// ================= PAYMENT =================
enum PaymentStatus {
  paid,
  pending,
  failed,
  refunded,
}

AppType mapStringToAppType(String? type) {
  final t = (type ?? "").toLowerCase().trim();

  switch (t) {
    case "gym":
      return AppType.gym;

    case "general store":
    case "shop":
      return AppType.shop;

    case "institute":
    case "school":
    case "coaching":
      return AppType.institute;

    case "salon":
      return AppType.salon;

    case "medical":
    case "hospital":
      return AppType.hospital;

    case "restaurant":
    case "food":
      return AppType.restaurant;

    case "finance":
      return AppType.finance;

    case "real estate":
      return AppType.realEstate;

    default:
      return AppType.generic;
  }
}
class DashboardText {

  static String title(AppType type) {
    switch (type) {
      case AppType.gym:
        return "Gym Dashboard";
      case AppType.shop:
        return "Shop Dashboard";
      case AppType.institute:
        return "Institute Dashboard";
      case AppType.salon:
        return "Salon Dashboard";
      case AppType.hospital:
        return "Hospital Dashboard";
      case AppType.restaurant:
        return "Restaurant Dashboard";
      case AppType.finance:
        return "Finance Dashboard";
      case AppType.realEstate:
        return "Real Estate Dashboard";
      case AppType.generic:
        return "Business Dashboard";
    }
  }

  static List<String> metrics(AppType type) {
    switch (type) {
      case AppType.gym:
        return ["Members", "Active Plans", "Pending Fees", "Expiring Soon"];
      case AppType.shop:
        return ["Customers", "Orders", "Pending Payments", "Low Stock"];
      case AppType.institute:
        return ["Students", "Active Courses", "Pending Fees", "Classes Today"];
      case AppType.salon:
        return ["Clients", "Appointments", "Pending Payments", "Bookings"];
      case AppType.hospital:
        return ["Patients", "Appointments", "Bills", "Doctors"];
      case AppType.restaurant:
        return ["Orders", "Tables", "Bills", "Revenue"];
      case AppType.finance:
        return ["Clients", "Transactions", "Pending", "Reports"];
      case AppType.realEstate:
        return ["Leads", "Properties", "Deals", "Visits"];
      case AppType.generic:
        return ["Users", "Activity", "Pending", "Alerts"];
    }
  }

  static List<String> actions(AppType type) {
    switch (type) {
      case AppType.gym:
        return ["Member", "Income", "Expense", "Calculator"];
      case AppType.shop:
        return ["Customer", "Income", "Expense", "Calculator"];
      case AppType.institute:
        return ["Student", "Income", "Expense", "Calculator"];
      case AppType.salon:
        return ["Client", "Income", "Expense", "Calculator"];
      case AppType.hospital:
        return ["Patient", "Income", "Expense", "Calculator"];
      case AppType.restaurant:
        return ["Customer", "Income", "Expense", "Calculator"];
      case AppType.finance:
        return ["Client", "Income", "Expense", "Calculator"];
      case AppType.realEstate:
        return ["Client", "Income", "Expense", "Calculator"];
      case AppType.generic:
        return ["Add", "Income", "Expense", "Calculator"];
    }
  }

  static IconData getIcon(AppType type) {
    switch (type) {
      case AppType.gym:
        return Icons.fitness_center;
      case AppType.shop:
        return Icons.store;
      case AppType.institute:
        return Icons.school;
      case AppType.salon:
        return Icons.cut;
      case AppType.hospital:
        return Icons.local_hospital;
      case AppType.restaurant:
        return Icons.restaurant;
      case AppType.finance:
        return Icons.attach_money;
      case AppType.realEstate:
        return Icons.home;
      case AppType.generic:
        return Icons.business;
    }
  }
}