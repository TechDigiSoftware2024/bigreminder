import 'package:intl/intl.dart';

class CreatePurchaseResponseModel {
  final int id;
  final int businessId;
  final int customerId;

  final String customerName;
  final String customerPhone;
  final String customerEmail;

  final String billNumber;
  final String barcode;

  final double subtotal;
  final double totalGst;
  final double totalAmount;
  final double paid;
  final double pending;

  final String status;
  final String paymentMode;
  final String notes;
  final String billDate;

  final DateTime createdAt;

  final List<PurchaseResponseItemModel> items;

  CreatePurchaseResponseModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.billNumber,
    required this.barcode,
    required this.subtotal,
    required this.totalGst,
    required this.totalAmount,
    required this.paid,
    required this.pending,
    required this.status,
    required this.paymentMode,
    required this.notes,
    required this.billDate,
    required this.createdAt,
    required this.items,
  });

  factory CreatePurchaseResponseModel.fromJson(Map<String, dynamic> json) {
    return CreatePurchaseResponseModel(
      id: json["id"] ?? 0,
      businessId: json["business_id"] ?? 0,
      customerId: json["customer_id"] ?? 0,

      customerName: json["customer_name"]?.toString() ?? "",
      customerPhone: json["customer_phone"]?.toString() ?? "",
      customerEmail: json["customer_email"]?.toString() ?? "",

      billNumber: json["bill_number"]?.toString() ?? "",
      barcode: json["barcode"]?.toString() ?? "",

      subtotal: parseDecimal(json["subtotal"]),
      totalGst: parseDecimal(json["total_gst"]),
      totalAmount: parseDecimal(json["total_amount"]),
      paid: parseDecimal(json["paid"]),
      pending: parseDecimal(json["pending"]),

      status: json["status"]?.toString() ?? "",
      paymentMode: json["payment_mode"]?.toString() ?? "",
      notes: json["notes"]?.toString() ?? "",
      billDate: formatIndianDate(json["bill_date"]?.toString() ?? ""),

      createdAt: DateTime.tryParse(
        json["created_at"]?.toString() ?? "",
      ) ??
          DateTime.now(),

      items: (json["items"] as List<dynamic>? ?? [])
          .map((e) => PurchaseResponseItemModel.fromJson(e))
          .toList(),
    );
  }
}
class PurchaseResponseItemModel {
  final int id;
  final int productId;
  final String barcode;
  final String name;

  final double price;
  final int quantity;

  final int? gstPercent;

  final double lineSubtotal;
  final double gstAmount;
  final double lineTotal;

  PurchaseResponseItemModel({
    required this.id,
    required this.productId,
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    this.gstPercent,
    required this.lineSubtotal,
    required this.gstAmount,
    required this.lineTotal,
  });

  factory PurchaseResponseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseResponseItemModel(
      id: json["id"] ?? 0,
      productId: json["product_id"] ?? 0,
      barcode: json["barcode"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",

      price: parseDecimal(json["price"]),
      quantity: json["quantity"] ?? 0,

      gstPercent: json["gst_percent"] == null
          ? null
          : num.tryParse(json["gst_percent"].toString())?.toInt(),

      lineSubtotal: parseDecimal(json["line_subtotal"]),
      gstAmount: parseDecimal(json["gst_amount"]),
      lineTotal: parseDecimal(json["line_total"]),
    );
  }
}
class PurchaseItemRequestModel {
  final int productId;
  final String barcode;
  final String name;
  final double price;
  final int quantity;
  final int? gstPercent;

  PurchaseItemRequestModel({
    required this.productId,
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    this.gstPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      "product_id": productId,
      "barcode": barcode,
      "name": name,
      "price": price,
      "quantity": quantity,
      "gst_percent": gstPercent ?? 0,
    };
  }
}
/// Backend sends total_amount/paid/pending/price as STRING
/// (decimal-as-string). Parse safely regardless of whether the
/// backend sends a number or a string.
///
String formatIndianDate(String date) {
  try {
    final parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  } catch (e) {
    print("Date Error: $e");
    return date;
  }
}
double parseDecimal(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}