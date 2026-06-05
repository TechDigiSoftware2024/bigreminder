import 'create_item_model.dart';

class CreatePurchaseModel {
  final int customerId;
  final int businessId;

  final List<PurchaseItemModel> items;

  final double totalAmount;
  final double paid;
  final double pending;

  final String date;

  CreatePurchaseModel({
    required this.customerId,
    required this.businessId,
    required this.items,
    required this.totalAmount,
    required this.paid,
    required this.pending,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      "customer_id": customerId,
      "business_id": businessId,
      "items": items.map((e) => e.toJson()).toList(),
      "total_amount": totalAmount,
      "paid": paid,
      "pending": pending,
      "date": date,
    };
  }
}