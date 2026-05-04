import '../../models/auth_models/auth_user_model.dart';

class AuthState {
  final bool isLoading;
  final AuthUserModel? user;
  final String? token;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthUserModel? user,
    String? token,
    String? error,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,

      // 🔥 Controlled update (no accidental override)
      user: clearUser ? null : (user ?? this.user),

      token: clearToken ? null : (token ?? this.token),

      error: clearError ? null : (error ?? this.error),
    );
  }
}