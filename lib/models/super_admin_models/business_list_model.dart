class Business {
  final int id;
  final String name;
  final String category;
  final String phone;
  final String address;
  final bool isActive;

  final String? doc;
  final int? userId;

  Business({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.address,
    required this.isActive,
    this.doc,
    this.userId,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      phone: json['user_phone'] ?? '',
      address: json['address'] ?? '',
      isActive: json['is_active'] ?? false,
      doc: json['doc'],
      userId: json['user_id'],
    );
  }
}