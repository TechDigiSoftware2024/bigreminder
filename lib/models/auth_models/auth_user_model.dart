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
    // Support flat and nested { data: {...} } / { user: {...} } payloads.
    final nested = () {
      final data = json['data'];
      if (data is Map<String, dynamic>) return data;
      final user = json['user'];
      if (user is Map<String, dynamic>) return user;
      return json;
    }();

    final token = json['access_token'] ??
        json['token'] ??
        nested['access_token'] ??
        nested['token'];

    final userId = nested['user_id'] ??
        nested['id'] ??
        json['user_id'] ??
        json['id'] ??
        '';

    final role = (nested['role'] ?? json['role'] ?? '').toString();

    return AuthUserModel(
      userId: userId.toString(),
      accessToken: token?.toString(),
      role: role,
    );
  }

  bool get isSuperAdmin => role == 'super_admin';

  // 🔥 helper
  bool get hasValidToken =>
      accessToken != null && accessToken!.isNotEmpty;
}
