class ProductModel {
  final int? id;
  final int businessId;
  final String? barcode;
  final String name;
  final int? gst_percent;
  final double price;
  final double? gstAmount;
  final double? totalPrice;
  final int stock;
  final bool? isActive;

  ProductModel({
    this.id,
    required this.businessId,
    this.barcode,
    required this.name,
    this.gst_percent,
    this.gstAmount,
    this.totalPrice,
    required this.price,
    required this.stock,
    this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"] as int?,
      businessId: json["business_id"] as int,
      barcode: json["barcode"]?.toString(),
      name: json["name"]?.toString() ?? "",

      gst_percent: json["gst_percent"] == null
          ? null
          : (double.tryParse(json["gst_percent"].toString()) ?? 0).toInt(),

      price: double.tryParse(json["price"].toString()) ?? 0.0,

      gstAmount: json["gst_amount"] == null
          ? null
          : double.tryParse(json["gst_amount"].toString()),

      totalPrice: json["total_price"] == null
          ? null
          : double.tryParse(json["total_price"].toString()),

      stock: int.tryParse(json["stock"].toString()) ?? 0,

      isActive: json["is_active"] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "business_id": businessId,
      "name": name,
      "price": price,
      "gst_percent": gst_percent ?? 0,
      "stock": stock,
    };

    if (barcode != null && barcode!.trim().isNotEmpty) {
      data["barcode"] = barcode!.trim();
    }

    return data;
  }
}