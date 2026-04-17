class AuthUserModel {
  final String userId;
  final String? accessToken; // 🔥 nullable
  final String role;

  AuthUserModel({
    required this.userId,
    required this.accessToken,
    required this.role,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      userId: json["user_id"].toString(),

      // 🔥 handle multiple backend formats
      accessToken: json["access_token"] ?? json["token"],

      role: json["role"] ?? '',
    );
  }

  bool get isSuperAdmin => role == 'super_admin';

  // 🔥 helper
  bool get hasValidToken =>
      accessToken != null && accessToken!.isNotEmpty;
}