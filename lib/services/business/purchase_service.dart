import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_models/create_purchase_model.dart';

class PurchaseService {

  static Future<String> createPurchase({
    required String token,
    required CreatePurchaseModel model,
  }) async {

    try {

      final response = await http.post(
        ApiConfig.url(ApiConfig.purchases),

        headers: ApiConfig.headers(token: token),

        body: jsonEncode(model.toJson()),
      );

      final data = jsonDecode(response.body);

      /// 🔥 SUCCESS
      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        return data["message"] ??
            "Purchase created successfully";
      }

      /// 🔥 API ERROR
      throw Exception(
        data["detail"] ??
            data["message"] ??
            "Failed to create purchase",
      );

    } on SocketException {
      throw Exception("No internet connection");

    } on HttpException {
      throw Exception("Server error");

    } on FormatException {
      throw Exception("Invalid server response");

    } catch (e) {
      throw Exception(e.toString());
    }
  }
}