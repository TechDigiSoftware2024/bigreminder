class BusinessIncomeRequest {
  final double amount;
  final String source;
  final int businessId;

  BusinessIncomeRequest({
    required this.amount,
    required this.source,
    required this.businessId,
  });

  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "source": source,
      "business_id": businessId,
    };
  }
}