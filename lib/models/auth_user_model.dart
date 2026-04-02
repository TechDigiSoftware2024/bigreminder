class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;

  AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json["id"] ?? '',
      name: json["name"] ?? '',
      email: json["email"] ?? '',
      phone: json["phone"] ?? '',
      role: json["role"] ?? '',
      status: json["status"] ?? '',
    );
  }
}