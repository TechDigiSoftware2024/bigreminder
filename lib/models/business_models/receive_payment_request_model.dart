class ReceivePaymentRequest {
  final int billId;
  final double receivedAmount;
  final String paymentMode;

  ReceivePaymentRequest({
    required this.billId,
    required this.receivedAmount,
    required this.paymentMode,
  });

  /// Maps UI labels (Cash / UPI / ...) to API PaymentSource values.
  static String toApiMode(String uiLabel) {
    switch (uiLabel.trim().toLowerCase()) {
      case 'cash':
        return 'cash';
      case 'upi':
        return 'upi';
      case 'card':
        return 'card';
      case 'bank transfer':
      case 'bank_transfer':
        return 'bank_transfer';
      case 'other':
        return 'other';
      default:
        return uiLabel.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'received_amount': receivedAmount,
      'payment_mode': paymentMode,
    };
  }
}
