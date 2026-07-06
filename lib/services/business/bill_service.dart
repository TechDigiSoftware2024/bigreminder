import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_models/business_purchase_list_model.dart';

class BillService {
  /// Fetches full bill detail including line items.
  /// GET /api/v1/bills/{bill_id}
  Future<PurchaseModel> getBillDetail({
    required String token,
    required int billId,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}${ApiConfig.bills}/$billId");

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PurchaseModel.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      "Failed to load bill detail (${response.statusCode}): ${response.body}",
    );
  }
}