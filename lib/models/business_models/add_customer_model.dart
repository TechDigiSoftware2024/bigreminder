class AddCustomerRequest {
  final String name;
  final String phone;
  final int businessId;
  final String? fcmToken; // ✅ nullable

  AddCustomerRequest({
    required this.name,
    required this.phone,
    required this.businessId,
    this.fcmToken, // ✅ not required
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "phone": phone,
    "business_id": businessId,
    "fcm_token": fcmToken ?? "", // ✅ safe fallback
  };
}