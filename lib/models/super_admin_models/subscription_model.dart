class SubscriptionModel {
  final int id;
  final int businessId;
  final int planId;
  final String status;
  final String paymentStatus;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final Map<String, dynamic> metadata;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.businessId,
    required this.planId,
    required this.status,
    required this.paymentStatus,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.metadata,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      planId: json['plan_id'] ?? 0,
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      startDate:
      DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      autoRenew: json['auto_renew'] ?? false,
      metadata: json['metadata'] ?? {},
      features: List<String>.from(json['features'] ?? []),
      createdAt:
      DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:
      DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "business_id": businessId,
      "plan_id": planId,
      "status": status,
      "payment_status": paymentStatus,
      "start_date": startDate.toIso8601String(),
      "end_date": endDate.toIso8601String(),
      "auto_renew": autoRenew,
      "metadata": metadata,
    };
  }

  // 🔥 Helpers
  bool get isActive => status == "active";

  bool hasFeature(String key) {
    return features.contains(key);
  }
}