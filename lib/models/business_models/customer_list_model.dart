class CustomerResponseModel {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String pendingAmount;
  final String gender;
  final int businessId;
  final String fcmToken;

  CustomerResponseModel({
    required this.id,
    required this.name,
    required this.email,
    required this.pendingAmount,
    required this.phone,
    required this.gender,
    required this.businessId,
    required this.fcmToken,
  });

  factory CustomerResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CustomerResponseModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      pendingAmount: json['pending_amount'] ?? "",
      gender: json['gender'] ?? "",
      businessId: json['business_id'] ?? 0,
      fcmToken: json['fcm_token'] ?? "",
    );
  }
}