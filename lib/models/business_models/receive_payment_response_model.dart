class ReceivePaymentResponse {
  final int billId;
  final String billNumber;
  final String paid;
  final String pending;
  final String status;
  final String customerPendingAmount;
  final String receivedAmount;

  ReceivePaymentResponse({
    required this.billId,
    required this.paid,
    required this.pending,
    required this.customerPendingAmount,
    required this.receivedAmount,
    this.billNumber = '',
    this.status = '',
  });

  /// Bills API returns `bill_id`; older purchases API used `purchase_id`.
  int get purchaseId => billId;

  factory ReceivePaymentResponse.fromJson(Map<String, dynamic> json) {
    final id = json['bill_id'] ?? json['purchase_id'] ?? json['id'];

    return ReceivePaymentResponse(
      billId: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      billNumber: json['bill_number']?.toString() ?? '',
      paid: json['paid']?.toString() ?? '0',
      pending: json['pending']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      customerPendingAmount:
          json['customer_pending_amount']?.toString() ?? '0',
      receivedAmount: json['received_amount']?.toString() ?? '0',
    );
  }
}
