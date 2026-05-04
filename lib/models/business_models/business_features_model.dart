class FeatureModel {
  final int id;
  final String name;
  final bool enabled;

  FeatureModel({
    required this.id,
    required this.name,
    required this.enabled,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      enabled: json['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
    };
  }
}