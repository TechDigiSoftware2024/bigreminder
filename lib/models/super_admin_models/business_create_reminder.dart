class BusinessReminderModel {
  final int id;
  final int businessId;
  final String message;
  final String targetGender;
  final String status;
  final String? lastError;
  final DateTime scheduledAt;
  final DateTime? sentAt;

  BusinessReminderModel({
    required this.id,
    required this.businessId,
    required this.message,
    required this.targetGender,
    required this.status,
    this.lastError,
    required this.scheduledAt,
    this.sentAt,
  });

  factory BusinessReminderModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return BusinessReminderModel(
      id: json["id"] ?? 0,
      businessId: json["business_id"] ?? 0,
      message: json["message"] ?? "",
      targetGender: json["target_gender"] ?? "all",
      status: json["status"] ?? "",
      lastError: json["last_error"],
      scheduledAt: DateTime.parse(
        json["scheduled_at"],
      ),
      sentAt: json["sent_at"] != null
          ? DateTime.parse(
        json["sent_at"],
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "scheduled_at":
      scheduledAt.toIso8601String(),
      "target_gender":
      targetGender,
      "business_id":
      businessId,
    };
  }
}