import '../utils/enum_classes.dart';

class Subscription {
  final int id;
  final int businessId;
  final int planId;
  final SubscriptionStatus status;
  final PaymentStatus paymentStatus;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final List<String> features;
  final Map<String, dynamic> metadata;

  Subscription({
    required this.id,
    required this.businessId,
    required this.planId,
    required this.status,
    required this.paymentStatus,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.features,
    required this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      planId: json['plan_id'] ?? 0,

      // 🔥 SAFE ENUM PARSING
      status: SubscriptionStatus.values.firstWhere(
            (e) => e.name.toLowerCase() ==
            (json['status'] ?? '').toString().toLowerCase(),
        orElse: () => SubscriptionStatus.active,
      ),

      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name.toLowerCase() ==
            (json['payment_status'] ?? '').toString().toLowerCase(),
        orElse: () => PaymentStatus.pending,
      ),

      // 🔥 SAFE DATE PARSING
      startDate: DateTime.tryParse(json['start_date'] ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ??
          DateTime.now(),

      autoRenew: json['auto_renew'] ?? false,

      // 🔥 SAFE LIST
      features: List<String>.from(json['features'] ?? []),

      // 🔥 SAFE MAP
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}