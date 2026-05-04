class BizFinancials {
  final double totalIncome;
  final double totalExpenses;
  final double net;

  BizFinancials({
    required this.totalIncome,
    required this.totalExpenses,
    required this.net,
  });

  factory BizFinancials.fromJson(Map<String, dynamic> json) {
    return BizFinancials(
      totalIncome: _safeParse(json['total_income']),
      totalExpenses: _safeParse(json['total_expenses']),
      net: _safeParse(json['net']),
    );
  }

  /// 🔥 critical sanitizer (backend garbage fix)
  static double _safeParse(dynamic value) {
    if (value == null) return 0;

    try {
      String v = value.toString();

      // remove leading zeros
      v = v.replaceFirst(RegExp(r'^0+'), '');

      if (v.isEmpty) return 0;

      // prevent crash from huge values
      if (v.length > 18) {
        v = v.substring(0, 18);
      }

      return double.tryParse(v) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}