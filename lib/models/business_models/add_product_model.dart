class ProductModel {
  final int? id;
  final int businessId;
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final bool? isActive;

  ProductModel({
    this.id,
    required this.businessId,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"],
      businessId: json["business_id"],
      barcode: json["barcode"] ?? "",
      name: json["name"] ?? "",
      price: double.tryParse(json["price"].toString()) ?? 0,
      stock: json["stock"] ?? 0,
      isActive: json["is_active"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "business_id": businessId,
      "barcode": barcode,
      "name": name,
      "price": price,
      "stock": stock,
    };
  }
}