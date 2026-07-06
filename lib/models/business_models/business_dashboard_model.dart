import 'dashboard_features.dart';

class BusinessDashboardModel {
  final int businessId;

  // Existing Raw Values
  final String totalIncome;
  final String totalExpenses;
  final String grandTotalPendingAmount;
  final String net;

  // Existing Parsed Values
  final double totalIncomeValue;
  final double totalExpensesValue;
  final double grandTotalPendingAmountValue;
  final double netValue;

  // Monthly Analytics
  final String month;

  final String currentMonthRevenue;
  final String previousMonthRevenue;

  final String currentMonthPurchaseRevenue;
  final String previousMonthPurchaseRevenue;

  final String currentMonthExpense;
  final String previousMonthExpense;

  final String currentMonthProfit;
  final String previousMonthProfit;

  final String revenueGrowthPercent;
  final String expenseGrowthPercent;
  final String profitGrowthPercent;

  // Parsed Analytics Values
  final double currentMonthRevenueValue;
  final double previousMonthRevenueValue;

  final double currentMonthPurchaseRevenueValue;
  final double previousMonthPurchaseRevenueValue;

  final double currentMonthExpenseValue;
  final double previousMonthExpenseValue;

  final double currentMonthProfitValue;
  final double previousMonthProfitValue;

  final double revenueGrowthPercentValue;
  final double expenseGrowthPercentValue;
  final double profitGrowthPercentValue;

  // Subscription
  final int subscriptionId;
  final int planId;
  final String planName;
  final String subscriptionStatus;

  final List<DashboardFeature> features;

  BusinessDashboardModel({
    required this.businessId,

    required this.totalIncome,
    required this.totalExpenses,
    required this.grandTotalPendingAmount,
    required this.net,

    required this.totalIncomeValue,
    required this.totalExpensesValue,
    required this.grandTotalPendingAmountValue,
    required this.netValue,

    required this.month,

    required this.currentMonthRevenue,
    required this.previousMonthRevenue,

    required this.currentMonthPurchaseRevenue,
    required this.previousMonthPurchaseRevenue,

    required this.currentMonthExpense,
    required this.previousMonthExpense,

    required this.currentMonthProfit,
    required this.previousMonthProfit,

    required this.revenueGrowthPercent,
    required this.expenseGrowthPercent,
    required this.profitGrowthPercent,

    required this.currentMonthRevenueValue,
    required this.previousMonthRevenueValue,

    required this.currentMonthPurchaseRevenueValue,
    required this.previousMonthPurchaseRevenueValue,

    required this.currentMonthExpenseValue,
    required this.previousMonthExpenseValue,

    required this.currentMonthProfitValue,
    required this.previousMonthProfitValue,

    required this.revenueGrowthPercentValue,
    required this.expenseGrowthPercentValue,
    required this.profitGrowthPercentValue,

    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.subscriptionStatus,

    required this.features,
  });

  factory BusinessDashboardModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final incomeRaw =
    (json['total_income'] ?? "0").toString();

    final expenseRaw =
    (json['total_expenses'] ?? "0").toString();

    final grandTotalPendingAmountRaw =
    (json['grand_total_pending_amount'] ?? "0")
        .toString();

    final netRaw =
    (json['net'] ?? "0").toString();

    final currentMonthRevenueRaw =
    (json['current_month_revenue'] ?? "0")
        .toString();

    final previousMonthRevenueRaw =
    (json['previous_month_revenue'] ?? "0")
        .toString();

    final currentMonthPurchaseRevenueRaw =
    (json['current_month_purchase_revenue'] ??
        "0")
        .toString();

    final previousMonthPurchaseRevenueRaw =
    (json['previous_month_purchase_revenue'] ??
        "0")
        .toString();

    final currentMonthExpenseRaw =
    (json['current_month_expense'] ?? "0")
        .toString();

    final previousMonthExpenseRaw =
    (json['previous_month_expense'] ?? "0")
        .toString();

    final currentMonthProfitRaw =
    (json['current_month_profit'] ?? "0")
        .toString();

    final previousMonthProfitRaw =
    (json['previous_month_profit'] ?? "0")
        .toString();

    final revenueGrowthPercentRaw =
    (json['revenue_growth_percent'] ?? "0")
        .toString();

    final expenseGrowthPercentRaw =
    (json['expense_growth_percent'] ?? "0")
        .toString();

    final profitGrowthPercentRaw =
    (json['profit_growth_percent'] ?? "0")
        .toString();

    return BusinessDashboardModel(
      businessId: json['business_id'] ?? 0,

      totalIncome: incomeRaw,
      totalExpenses: expenseRaw,
      grandTotalPendingAmount:
      grandTotalPendingAmountRaw,
      net: netRaw,

      totalIncomeValue:
      _parseAmount(incomeRaw),
      totalExpensesValue:
      _parseAmount(expenseRaw),
      grandTotalPendingAmountValue:
      _parseAmount(
          grandTotalPendingAmountRaw),
      netValue:
      _parseAmount(netRaw),

      month:
      (json['month'] ?? "").toString(),

      currentMonthRevenue:
      currentMonthRevenueRaw,

      previousMonthRevenue:
      previousMonthRevenueRaw,

      currentMonthPurchaseRevenue:
      currentMonthPurchaseRevenueRaw,

      previousMonthPurchaseRevenue:
      previousMonthPurchaseRevenueRaw,

      currentMonthExpense:
      currentMonthExpenseRaw,

      previousMonthExpense:
      previousMonthExpenseRaw,

      currentMonthProfit:
      currentMonthProfitRaw,

      previousMonthProfit:
      previousMonthProfitRaw,

      revenueGrowthPercent:
      revenueGrowthPercentRaw,

      expenseGrowthPercent:
      expenseGrowthPercentRaw,

      profitGrowthPercent:
      profitGrowthPercentRaw,

      currentMonthRevenueValue:
      _parseAmount(
          currentMonthRevenueRaw),

      previousMonthRevenueValue:
      _parseAmount(
          previousMonthRevenueRaw),

      currentMonthPurchaseRevenueValue:
      _parseAmount(
          currentMonthPurchaseRevenueRaw),

      previousMonthPurchaseRevenueValue:
      _parseAmount(
          previousMonthPurchaseRevenueRaw),

      currentMonthExpenseValue:
      _parseAmount(
          currentMonthExpenseRaw),

      previousMonthExpenseValue:
      _parseAmount(
          previousMonthExpenseRaw),

      currentMonthProfitValue:
      _parseAmount(
          currentMonthProfitRaw),

      previousMonthProfitValue:
      _parseAmount(
          previousMonthProfitRaw),

      revenueGrowthPercentValue:
      _parseAmount(
          revenueGrowthPercentRaw),

      expenseGrowthPercentValue:
      _parseAmount(
          expenseGrowthPercentRaw),

      profitGrowthPercentValue:
      _parseAmount(
          profitGrowthPercentRaw),

      subscriptionId:
      json['subscription_id'] ?? 0,

      planId:
      json['plan_id'] ?? 0,

      planName:
      (json['plan_name'] ?? "No Plan")
          .toString(),

      subscriptionStatus:
      (json['subscription_status'] ??
          "Inactive")
          .toString(),

      features:
      (json['features'] as List? ?? [])
          .map(
            (e) =>
            DashboardFeature.fromJson(e),
      )
          .toList(),
    );
  }

  static double _parseAmount(String value) {
    final cleaned = value
        .replaceAll(',', '')
        .replaceAll('+', '')
        .trim();

    return double.tryParse(cleaned) ?? 0.0;
  }
}