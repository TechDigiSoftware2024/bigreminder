class PurchaseItem {
  final int? id;
  final int? productId;
  final String barcode;
  final String name;
  final String price;
  final int quantity;

  PurchaseItem({
    this.id,
    this.productId,
    this.barcode = '',
    required this.name,
    required this.price,
    required this.quantity,
  });

  /// The detail API doesn't return a pre-computed `total` per item —
  /// derive it from price × quantity instead.
  double get total => (double.tryParse(price) ?? 0) * quantity;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      productId: json['product_id'],
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      quantity: json['quantity'] ?? 0,
    );
  }
}

class PurchaseModel {
  final int billId;
  final int businessId;
  final String billNumber;
  final String barcode;
  final int customerId;
  final String customerName;
  final String totalAmount;
  final String paid;
  final String pending;
  final String status;
  final String paymentMode;
  final String notes;
  final String billDate;
  final String createdAt;

  /// Line items — empty for list-endpoint responses, populated once the
  /// detail endpoint (/api/v1/bills/{bill_id}) has been fetched.
  final List<PurchaseItem> items;

  PurchaseModel({
    required this.billId,
    this.businessId = 0,
    required this.billNumber,
    required this.barcode,
    required this.customerId,
    this.customerName = '',
    required this.totalAmount,
    required this.paid,
    required this.pending,
    required this.status,
    this.paymentMode = '',
    this.notes = '',
    required this.billDate,
    this.createdAt = '',
    this.items = const [],
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      // Detail endpoint returns `id`; list endpoint returns `bill_id`.
      // Support both without breaking either screen.
      billId: json['id'] ?? json['bill_id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      billNumber: json['bill_number']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      paid: json['paid']?.toString() ?? '0',
      pending: json['pending']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      paymentMode: json['payment_mode']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      billDate: json['bill_date']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PurchaseItem.fromJson(e))
          .toList(),
    );
  }

  /// Returns a copy of this bill merged with detail-endpoint data
  /// (items, payment mode, notes) while keeping list-endpoint fields
  /// like customerName that the detail endpoint doesn't return.
  PurchaseModel mergeWithDetail(PurchaseModel detail) {
    return PurchaseModel(
      billId: billId,
      businessId: detail.businessId,
      billNumber: billNumber,
      barcode: barcode,
      customerId: customerId,
      customerName: customerName, // keep list-endpoint's name
      totalAmount: detail.totalAmount,
      paid: detail.paid,
      pending: detail.pending,
      status: detail.status,
      paymentMode: detail.paymentMode,
      notes: detail.notes,
      billDate: billDate,
      createdAt: detail.createdAt,
      items: detail.items,
    );
  }
}