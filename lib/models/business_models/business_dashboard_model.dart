import 'dashboard_features.dart';

class BusinessDashboardModel {
  final int businessId;

  // Raw values (API ke same)
  final String totalIncome;
  final String totalExpenses;
  final String net;

  // ✅ Parsed usable values (NEW - important)
  final double totalIncomeValue;
  final double totalExpensesValue;
  final double netValue;

  final int subscriptionId;
  final int planId;
  final String planName;
  final String subscriptionStatus;

  final List<DashboardFeature> features;

  BusinessDashboardModel({
    required this.businessId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.net,

    required this.totalIncomeValue,
    required this.totalExpensesValue,
    required this.netValue,

    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.subscriptionStatus,
    required this.features,
  });

  factory BusinessDashboardModel.fromJson(Map<String, dynamic> json) {
    final incomeRaw = (json['total_income'] ?? "0").toString();
    final expenseRaw = (json['total_expenses'] ?? "0").toString();
    final netRaw = (json['net'] ?? "0").toString();

    return BusinessDashboardModel(
      businessId: json['business_id'] ?? 0,

      totalIncome: incomeRaw,
      totalExpenses: expenseRaw,
      net: netRaw,

      // ✅ Clean + parse here (single source of truth)
      totalIncomeValue: _parseAmount(incomeRaw),
      totalExpensesValue: _parseAmount(expenseRaw),
      netValue: _parseAmount(netRaw),

      subscriptionId: json['subscription_id'] ?? 0,
      planId: json['plan_id'] ?? 0,

      planName: (json['plan_name'] ?? "No Plan").toString(),
      subscriptionStatus:
      (json['subscription_status'] ?? "Inactive").toString(),

      features: (json['features'] as List? ?? [])
          .map((e) => DashboardFeature.fromJson(e))
          .toList(),
    );
  }

  /// 🔥 Core fix: sanitize + convert
  static double _parseAmount(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^0-9\.\-]'), '') // remove junk (+ etc)
        .replaceFirst(RegExp(r'^0+'), '');     // remove leading zeros

    return double.tryParse(cleaned.isEmpty ? "0" : cleaned) ?? 0.0;
  }
}