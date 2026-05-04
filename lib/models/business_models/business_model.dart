class CreateBusinessResponse {
  final String message;
  final bool success;

  const CreateBusinessResponse({
    required this.message,
    required this.success,
  });

  factory CreateBusinessResponse.fromJson(Map<String, dynamic> json) {
    return CreateBusinessResponse(
      message: (json['message'] ?? 'Business created successfully!')
          .toString(),
      success: json['success'] ?? true,
    );
  }

  // 🔥 helper
  bool get isSuccess => success;

  @override
  String toString() {
    return "CreateBusinessResponse(success: $success, message: $message)";
  }
}