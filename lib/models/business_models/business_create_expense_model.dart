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
      "category": category.toLowerCase(),
      "source": source.toLowerCase(),
      "business_id": businessId,
    };
  }
}
