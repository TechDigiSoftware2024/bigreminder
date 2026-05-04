import '../../models/super_admin_models/business_list_model.dart';

class BusinessState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String message;

  final List<Business> businesses; // ✅ CORE FIX

  const BusinessState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.message = '',
    this.businesses = const [], // ✅ default empty list
  });

  BusinessState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? message,
    List<Business>? businesses,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
      businesses: businesses ?? this.businesses, // ✅ IMPORTANT
    );
  }
}