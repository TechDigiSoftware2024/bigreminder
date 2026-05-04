class NotificationRequest {
  final int businessId;
  final int? customerId;
  final String? type;
  final String title;
  final String message;
  final List<String>? sendVia;

  NotificationRequest({
    required this.businessId,
    required this.title,
    required this.message,
    this.customerId,
    this.type,
    this.sendVia,
  });

  Map<String, dynamic> toSendNowJson() {
    return {
      "business_id": businessId,
      "title": title,
      "message": message,
      "customer_id": customerId,
    };
  }

  Map<String, dynamic> toSendJson() {
    return {
      "customer_id": customerId,
      "business_id": businessId,
      "type": type,
      "title": title,
      "message": message,
      "send_via": sendVia,
    };
  }

  Map<String, dynamic> toBroadcastJson() {
    return {
      "business_id": businessId,
      "type": type,
      "title": title,
      "message": message,
      "send_via": sendVia,
    };
  }
  NotificationRequest copyWith({
    int? businessId,
    int? customerId,
    String? type,
    String? title,
    String? message,
    List<String>? sendVia,
  }) {
    return NotificationRequest(
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      sendVia: sendVia ?? this.sendVia,
    );
  }
}