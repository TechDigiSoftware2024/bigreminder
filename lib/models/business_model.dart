class CreateBusinessModel {
  final String message;
  final bool success;

  const CreateBusinessModel({
    required this.message,
    required this.success,
  });

  factory CreateBusinessModel.fromJson(Map<String, dynamic> json) {
    return CreateBusinessModel(
      message: json['message'] ?? 'Business created successfully!',
      success: json['success'] ?? true,
    );
  }
}