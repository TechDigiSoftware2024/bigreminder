import 'trend_item_model.dart';

class BusinessMonthlyGrowthModel {
  final int businessId;
  final int months;

  final List<TrendItemModel> monthlyRevenue;
  final List<TrendItemModel> monthlyPurchaseRevenue;
  final List<TrendItemModel> monthlyExpense;
  final List<TrendItemModel> monthlyProfit;

  const BusinessMonthlyGrowthModel({
    required this.businessId,
    required this.months,
    required this.monthlyRevenue,
    required this.monthlyPurchaseRevenue,
    required this.monthlyExpense,
    required this.monthlyProfit,
  });

  factory BusinessMonthlyGrowthModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return BusinessMonthlyGrowthModel(
      businessId: json['business_id'] ?? 0,

      months: json['months'] ?? 0,

      monthlyRevenue:
      (json['monthly_revenue'] as List? ?? [])
          .map(
            (e) => TrendItemModel.fromJson(e),
      )
          .toList(),

      monthlyPurchaseRevenue:
      (json['monthly_purchase_revenue']
      as List? ??
          [])
          .map(
            (e) => TrendItemModel.fromJson(e),
      )
          .toList(),

      monthlyExpense:
      (json['monthly_expense'] as List? ?? [])
          .map(
            (e) => TrendItemModel.fromJson(e),
      )
          .toList(),

      monthlyProfit:
      (json['monthly_profit'] as List? ?? [])
          .map(
            (e) => TrendItemModel.fromJson(e),
      )
          .toList(),
    );
  }
}