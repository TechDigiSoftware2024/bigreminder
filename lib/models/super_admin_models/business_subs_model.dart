class BizSubscription {
  final int subscriptionId;
  final int planId;
  final String planName;
  final String status;
  final bool isActive;

  BizSubscription({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.isActive,
  });

  factory BizSubscription.fromJson(Map<String, dynamic> json) {
    final status = (json['subscription_status'] ?? 'inactive').toString();

    return BizSubscription(
      subscriptionId: json['subscription_id'] ?? 0,
      planId: json['plan_id'] ?? 0,
      planName: json['plan_name'] ?? 'Free',
      status: status,
      isActive: status.toLowerCase() == 'active',
    );
  }
}