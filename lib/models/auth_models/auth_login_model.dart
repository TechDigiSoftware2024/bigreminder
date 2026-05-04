class LoginUserModel {
  final String userId;
  final String accessToken;
  final String role;

  LoginUserModel({
    required this.userId,
    required this.accessToken,
    required this.role,
  });

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      userId: (json["user_id"] ?? '').toString(),
      accessToken: json["access_token"] ?? '',
      role: (json["role"] ?? '').toString().toLowerCase(),
    );
  }

  // 🔥 Role helpers (future-proof)
  bool get isSuperAdmin => role == 'super_admin';
  bool get isOwner => role == 'owner';
  bool get isStaff => role == 'staff';

  // 🔥 Useful check
  bool get isLoggedIn => accessToken.isNotEmpty;

  // 🔥 Debug helper
  @override
  String toString() {
    return "User(id: $userId, role: $role)";
  }
}