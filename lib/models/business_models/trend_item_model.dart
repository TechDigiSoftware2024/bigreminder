class TrendItemModel {
  final String month;
  final String amount;
  final double amountValue;

  const TrendItemModel({
    required this.month,
    required this.amount,
    required this.amountValue,
  });

  factory TrendItemModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final raw =
    (json['amount'] ?? '0').toString();

    return TrendItemModel(
      month: (json['month'] ?? '').toString(),
      amount: raw,
      amountValue: _parseAmount(raw),
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