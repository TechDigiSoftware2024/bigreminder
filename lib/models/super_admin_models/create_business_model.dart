class BusinessModel {
  final int id;
  final String name;
  final String category;
  final String address;
  final String doc;
  final int userId;
  final bool isActive;

  BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.doc,
    required this.userId,
    required this.isActive,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      doc: json['doc'] ?? '',
      userId: json['user_id'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}