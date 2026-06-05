class QueryModel {
  final int id;
  final int businessId;
  final String message;
  final String status;
  final String adminResponse;

  QueryModel({
    required this.id,
    required this.businessId,
    required this.message,
    required this.status,
    required this.adminResponse,
  });

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    return QueryModel(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      adminResponse: json['admin_response'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'message': message,
      'status': status,
      'admin_response': adminResponse,
    };
  }
}
