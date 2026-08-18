import 'businesss_edit_profile_model.dart';

class UpdateCustomerRequestModel {
  final String name;
  final String phone;
  final String gender;
  final String email;
  final String fcmToken;
  final double pendingAmount;

  const UpdateCustomerRequestModel({
    required this.name,
    required this.phone,
    required this.gender,
    required this.email,
    required this.fcmToken,
    required this.pendingAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone": phone,
      "gender": gender,
      "email": email,
      "fcm_token": fcmToken,
      "pending_amount": pendingAmount,
    };
  }
}
