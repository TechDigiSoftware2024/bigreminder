class BusinessExpenseModel {
  final int amount;
  final String category;
  final int businessId;

  BusinessExpenseModel({
    required this.amount,
    required this.category,
    required this.businessId,
  });

  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "category": category,
      "business_id": businessId,
    };
  }
}