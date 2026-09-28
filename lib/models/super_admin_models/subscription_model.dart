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
    int asInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    final rawFeatures = json['features'];
    List<String> features = [];
    if (rawFeatures is List) {
      features = rawFeatures.map((e) {
        if (e is Map) {
          return (e['key'] ?? e['name'] ?? e['id'] ?? '').toString();
        }
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
    }

    return SubscriptionModel(
      id: asInt(json['id']),
      businessId: asInt(json['business_id']),
      planId: asInt(json['plan_id']),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      startDate:
          DateTime.tryParse(json['start_date']?.toString() ?? '') ??
              DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          DateTime.now(),
      autoRenew: json['auto_renew'] == true ||
          json['auto_renew']?.toString() == 'true',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
      features: features,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
              DateTime.now(),
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