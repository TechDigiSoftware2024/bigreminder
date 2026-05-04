class PlanModel {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final String billingCycle;
  final int trialDays;
  final bool isActive;

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.billingCycle,
    required this.trialDays,
    required this.isActive,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    try {
      return PlanModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        name: json['name']?.toString() ?? "",
        price: double.tryParse(json['price'].toString()) ?? 0.0,
        durationDays:
        int.tryParse(json['duration_days'].toString()) ?? 0,
        billingCycle: json['billing_cycle']?.toString() ?? "",
        trialDays:
        int.tryParse(json['trial_days'].toString()) ?? 0,
        isActive: json['is_active'] ?? false,
      );
    } catch (e) {
      print("❌ PLAN PARSE ERROR: $e");
      print("❌ RAW JSON: $json");
      rethrow;
    }
  }
}