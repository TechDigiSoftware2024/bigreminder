class BusinessExpenseModel {
  final int amount;
  final String category;
  final String source;
  final int businessId;

  BusinessExpenseModel({
    required this.amount,
    required this.category,
    required this.source,
    required this.businessId,
  });

  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "category": category.toString().toLowerCase(),
      "source": source.toString().toLowerCase(),
      "business_id": businessId,
    };
  }
}

class BusinessExpense {
  final double amount;
  final String source;
  final String category;
  final int id;
  final int businessId;
  final DateTime? recordedAt;

  const BusinessExpense({
    required this.amount,
    required this.source,
    required this.category,
    required this.id,
    required this.businessId,
    this.recordedAt,
  });

  factory BusinessExpense.fromJson(Map<String, dynamic> json) {
    return BusinessExpense(
      amount: double.tryParse(json["amount"]?.toString() ?? "0") ?? 0.0,
      source: json["source"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      id: int.tryParse(json["id"]?.toString() ?? "0") ?? 0,
      businessId: int.tryParse(json["business_id"]?.toString() ?? "0") ?? 0,
      recordedAt: json["recorded_at"] != null
          ? DateTime.tryParse(json["recorded_at"].toString())
          : null,
    );
  }
}
