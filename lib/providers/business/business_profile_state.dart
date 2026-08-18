enum BusinessProfileStatus {
  initial,
  loading,
  success,
  error,
}

class BusinessProfileState {
  final BusinessProfileStatus status;
  final String? errorMessage;

  const BusinessProfileState({
    this.status = BusinessProfileStatus.initial,
    this.errorMessage,
  });

  BusinessProfileState copyWith({
    BusinessProfileStatus? status,
    String? errorMessage,
  }) {
    return BusinessProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}