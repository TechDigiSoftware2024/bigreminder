class PurchaseItemModel {
  final String name;
  final double price;
  final int quantity;

  PurchaseItemModel({
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "price": price,
      "quantity": quantity,
    };
  }
}