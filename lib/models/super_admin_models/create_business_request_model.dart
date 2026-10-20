class CreateBusinessRequestModel {
  final String name;
  final String category;
  final int? categoryId;
  final String address;
  final String doc;
  final int userId;
  final int planId;

  CreateBusinessRequestModel({
    required this.name,
    required this.category,
    this.categoryId,
    required this.address,
    required this.doc,
    required this.userId,
    required this.planId,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "category": category,
      if (categoryId != null) "category_id": categoryId,
      "address": address,
      "doc": doc,
      "user_id": userId,
      "plan_id": planId,
    };
  }
}