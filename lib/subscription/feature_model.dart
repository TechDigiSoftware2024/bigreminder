class FeatureModel {
  final int id;
  final String key;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  FeatureModel({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['id'] ?? 0,
      key: json['key']?.toString() ?? "",
      name: json['name']?.toString() ?? "",
      description: json['description']?.toString() ?? "", // ✅ FIX
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}