class CustomerResponseModel {
  final int id;
  final String name;
  final String phone;
  final int businessId;
  final String fcmToken;

  CustomerResponseModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.businessId,
    required this.fcmToken,
  });

  factory CustomerResponseModel.fromJson(Map<String, dynamic> json) {
    return CustomerResponseModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      phone: json['phone'] ?? "",
      businessId: json['business_id'] ?? 0,
      fcmToken: json['fcm_token'] ?? "",
    );
  }
}