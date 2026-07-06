class ReceivePaymentRequest {
  final int purchaseId;
  final double receivedAmount;

  ReceivePaymentRequest({
    required this.purchaseId,
    required this.receivedAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      "purchase_id": purchaseId,
      "received_amount": receivedAmount,
    };
  }
}