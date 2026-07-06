class ReceivePaymentResponse {
  final int purchaseId;
  final String paid;
  final String pending;
  final String customerPendingAmount;
  final String receivedAmount;

  ReceivePaymentResponse({
    required this.purchaseId,
    required this.paid,
    required this.pending,
    required this.customerPendingAmount,
    required this.receivedAmount,
  });

  factory ReceivePaymentResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return ReceivePaymentResponse(
      purchaseId: json['purchase_id'],
      paid: json['paid'].toString(),
      pending: json['pending'].toString(),
      customerPendingAmount:
      json['customer_pending_amount'].toString(),
      receivedAmount:
      json['received_amount'].toString(),
    );
  }
}