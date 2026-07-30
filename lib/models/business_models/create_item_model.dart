class PurchaseItemModel {
  final int? productId;
  final String? barcode;
  final String name;
  final double price;
  final int quantity;
  final double? gstPercent;

  PurchaseItemModel({
    this.productId,
    this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    this.gstPercent,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "barcode": barcode?.trim() ?? "",
      "name": name.trim(),
      "price": price,
      "quantity": quantity,
      "gst_percent": gstPercent ?? 0,
    };

    if (productId != null && productId! > 0) {
      data["product_id"] = productId;
    }

    return data;
  }
}