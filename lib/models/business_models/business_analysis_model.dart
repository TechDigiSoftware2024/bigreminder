class BusinessAnalysisModel {
  final int businessId;
  final int months;

  final List<MonthlyData> monthlyRevenue;
  final List<MonthlyData> monthlyPurchaseRevenue;
  final List<MonthlyData> monthlyExpense;
  final List<MonthlyData> monthlyProfit;

  BusinessAnalysisModel({
    required this.businessId,
    required this.months,
    required this.monthlyRevenue,
    required this.monthlyPurchaseRevenue,
    required this.monthlyExpense,
    required this.monthlyProfit,
  });

  factory BusinessAnalysisModel.fromJson(Map<String, dynamic> json) {
    return BusinessAnalysisModel(
      businessId: json["business_id"] ?? 0,
      months: json["months"] ?? 0,
      monthlyRevenue: (json["monthly_revenue"] as List? ?? [])
          .map((e) => MonthlyData.fromJson(e))
          .toList(),
      monthlyPurchaseRevenue:
      (json["monthly_purchase_revenue"] as List? ?? [])
          .map((e) => MonthlyData.fromJson(e))
          .toList(),
      monthlyExpense: (json["monthly_expense"] as List? ?? [])
          .map((e) => MonthlyData.fromJson(e))
          .toList(),
      monthlyProfit: (json["monthly_profit"] as List? ?? [])
          .map((e) => MonthlyData.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyData {
  final String month;
  final String amount;

  MonthlyData({
    required this.month,
    required this.amount,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json["month"] ?? "",
      amount: json["amount"]?.toString() ?? "0",
    );
  }

  double get value => double.tryParse(amount) ?? 0;
}