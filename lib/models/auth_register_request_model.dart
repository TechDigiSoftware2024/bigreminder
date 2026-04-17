class RegisterRequestModel {
  final String ownerName;
  final String phone;
  final String password;
  final String businessName;
  final String businessCategory;
  final String address;
  final String doc;

  RegisterRequestModel({
    required this.ownerName,
    required this.phone,
    required this.password,
    required this.businessName,
    required this.businessCategory,
    required this.address,
    required this.doc,
  });

  Map<String, dynamic> toJson() {
    return {
      "owner_name": ownerName.trim(),
      "phone": phone.trim(),
      "password": password.trim(),
      "business_name": businessName.trim(),
      "business_category": businessCategory.trim(),
      "address": address.trim(),
      "doc": doc.trim(),
    };
  }

  // 🔥 copyWith (future edits / updates)
  RegisterRequestModel copyWith({
    String? ownerName,
    String? phone,
    String? password,
    String? businessName,
    String? businessCategory,
    String? address,
    String? doc,
  }) {
    return RegisterRequestModel(
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      address: address ?? this.address,
      doc: doc ?? this.doc,
    );
  }

  // 🔥 Debug helper
  @override
  String toString() {
    return "RegisterRequest(owner: $ownerName, phone: $phone, business: $businessName)";
  }
}