class DashboardFeature {
  final int id;
  final String name;
  final bool enabled;

  DashboardFeature({
    required this.id,
    required this.name,
    required this.enabled,
  });

  factory DashboardFeature.fromJson(Map<String, dynamic> json) {
    return DashboardFeature(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      enabled: json['enabled'] ?? false,
    );
  }
}