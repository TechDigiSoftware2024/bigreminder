import '../../models/auth_user_model.dart';

class BusinessState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String message;
  final AuthUserModel? user; // 🔥 ADD THIS

  const BusinessState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.message = '',
    this.user,
  });

  BusinessState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? message,
    AuthUserModel? user, // 🔥 ADD
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
      user: user ?? this.user, // 🔥 IMPORTANT
    );
  }
}