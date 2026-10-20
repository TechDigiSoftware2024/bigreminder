class CategoryBusiness {
  final int businessId;
  final String businessName;

  const CategoryBusiness({
    required this.businessId,
    required this.businessName,
  });

  factory CategoryBusiness.fromJson(Map<String, dynamic> json) {
    return CategoryBusiness(
      businessId: _asInt(json['business_id'] ?? json['businessId']),
      businessName: (json['business_name'] ?? json['businessName'] ?? '')
          .toString(),
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final List<CategoryBusiness> businesses;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.createdAt,
    this.businesses = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawBusinesses = json['businesses'];
    final businesses = rawBusinesses is List
        ? rawBusinesses
            .whereType<Map>()
            .map(
              (item) => CategoryBusiness.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <CategoryBusiness>[];

    return CategoryModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      isActive: _asBool(json['is_active'] ?? json['isActive'] ?? true),
      createdAt: DateTime.tryParse(
        (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      ),
      businesses: businesses,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
