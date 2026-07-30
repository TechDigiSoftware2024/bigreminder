class BusinessIncomeRequest {
  final double amount;
  final String source;
  final String remark;
  final int businessId;

  BusinessIncomeRequest({
    required this.amount,
    required this.source,
    required this.remark,
    required this.businessId,
  });

  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "source": source.toString().toLowerCase(),
      "remark": remark.toString().toLowerCase(),
      "business_id": businessId,
    };
  }
}