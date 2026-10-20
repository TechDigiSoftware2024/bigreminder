class NotificationHistoryItem {
  final String title;
  final String message;
  final String type;
  final String status;
  final String? channel;
  final DateTime? sentAt;
  final int? customerId;

  const NotificationHistoryItem({
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    this.channel,
    this.sentAt,
    this.customerId,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    final channel = _text(json['channel'] ?? json['delivery_channel']);
    return NotificationHistoryItem(
      title: _text(json['title'] ?? json['subject']) ?? '',
      message: _text(json['message'] ?? json['body'] ?? json['content']) ?? '',
      type: _text(json['type'] ?? json['notification_type']) ?? 'general',
      status: _text(json['status'] ?? json['delivery_status']) ?? 'unknown',
      channel: channel == null || channel.isEmpty ? null : channel,
      sentAt: _date(json['sent_at'] ?? json['sentAt'] ?? json['created_at'] ?? json['createdAt']),
      customerId: _int(json['customer_id'] ?? json['customerId']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
