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
class BusinessIncome {
  final double amount;
  final String source;
  final String remark;
  final int id;
  final int businessId;
  final DateTime? recordedAt;

  const BusinessIncome({
    required this.amount,
    required this.source,
    required this.remark,
    required this.id,
    required this.businessId,
    this.recordedAt,
  });

  factory BusinessIncome.fromJson(
      Map<String, dynamic> json,
      ) {
    return BusinessIncome(
      amount: double.tryParse(
        json["amount"]?.toString() ?? "0",
      ) ??
          0.0,

      source: json["source"]?.toString() ?? "",

      remark: json["remark"]?.toString() ?? "",

      id: int.tryParse(
        json["id"]?.toString() ?? "0",
      ) ??
          0,

      businessId: int.tryParse(
        json["business_id"]?.toString() ?? "0",
      ) ??
          0,

      recordedAt: json["recorded_at"] != null
          ? DateTime.tryParse(
        json["recorded_at"].toString(),
      )
          : null,
    );
  }
}