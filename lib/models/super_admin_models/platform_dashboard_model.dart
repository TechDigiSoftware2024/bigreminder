class PlatformDashboardModel {
  final double totalIncomeValue;
  final double totalExpensesValue;
  final double pendingValue;
  final int totalCustomers;

  const PlatformDashboardModel({
    required this.totalIncomeValue,
    required this.totalExpensesValue,
    required this.pendingValue,
    required this.totalCustomers,
  });

  factory PlatformDashboardModel.fromJson(Map<String, dynamic> json) {
    final source = _unwrap(json);
    return PlatformDashboardModel(
      totalIncomeValue: _asDouble(source, const [
        'total_income',
        'totalIncome',
        'total_income_value',
        'income',
      ]),
      totalExpensesValue: _asDouble(source, const [
        'total_expenses',
        'totalExpenses',
        'total_expense',
        'expenses',
      ]),
      pendingValue: _asDouble(source, const [
        'pending',
        'pending_amount',
        'pending_value',
        'grand_total_pending_amount',
        'total_pending',
      ]),
      totalCustomers: _asInt(source, const [
        'total_customers',
        'totalCustomers',
        'customers',
        'customer_count',
      ]),
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    for (final key in const ['data', 'dashboard', 'platform']) {
      final nested = json[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return json;
  }

  static double _asDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key) || json[key] == null) continue;
      final raw = json[key].toString().replaceAll(',', '').replaceAll('+', '').trim();
      final value = double.tryParse(raw);
      if (value != null) return value;
    }
    return 0;
  }

  static int _asInt(Map<String, dynamic> json, List<String> keys) {
    return _asDouble(json, keys).round();
  }
}
