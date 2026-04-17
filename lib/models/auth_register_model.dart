class RegisterUserModel {
  final String id;
  final String ownerName;
  final String phone;
  final String businessName;
  final String businessCategory;
  final String address;
  final String doc;
  final String role;
  final String status;

  RegisterUserModel({
    required this.id,
    required this.ownerName,
    required this.phone,
    required this.businessName,
    required this.businessCategory,
    required this.address,
    required this.doc,
    required this.role,
    required this.status,
  });

  factory RegisterUserModel.fromJson(Map<String, dynamic> json) {
    return RegisterUserModel(
      id: (json["id"] ?? '').toString(),
      ownerName: (json["owner_name"] ?? '').toString(),
      phone: (json["phone"] ?? '').toString(),
      businessName: (json["business_name"] ?? '').toString(),
      businessCategory: (json["business_category"] ?? '').toString(),
      address: (json["address"] ?? '').toString(),
      doc: (json["doc"] ?? '').toString(),
      role: (json["role"] ?? '').toString().toLowerCase(),
      status: (json["status"] ?? '').toString().toLowerCase(),
    );
  }

  // 🔥 Helpers (very useful)
  bool get isActive => status == "active";
  bool get isPending => status == "pending";

  bool get isOwner => role == "owner";
  bool get isSuperAdmin => role == "super_admin";

  // 🔥 Debug
  @override
  String toString() {
    return "RegisterUser(id: $id, business: $businessName, status: $status)";
  }
}