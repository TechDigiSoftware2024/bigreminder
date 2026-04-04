import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_model.dart';

class BusinessApiService {
  final String baseUrl;

  BusinessApiService(this.baseUrl);

  Future<CreateBusinessModel> createBusiness({
    required String name,
    required String address,
    required String category,
  }) async {
    final url = Uri.parse("$baseUrl/create-business");

    try {
      final response = await http
          .post(
        url,
        headers: {
          "Content-Type": "application/json", // ✅ FIXED
        },
        body: jsonEncode({
          "name": name,
          "category": category,
          "address": address,
        }),
      )
          .timeout(const Duration(seconds: 10));

      final data =
      response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateBusinessModel.fromJson(data);
      }

      throw Exception(_handleError(response.statusCode, data));
    } on http.ClientException {
      throw Exception("No internet connection.");
    } on FormatException {
      throw Exception("Invalid server response.");
    } catch (e) {
      if (e is Exception) rethrow; // ✅ preserve original error
      throw Exception("Something went wrong. Try again.");
    }
  }

  String _handleError(int statusCode, Map data) {
    switch (statusCode) {
      case 400:
        return data['message'] ?? "Invalid input.";
      case 401:
        return "Session expired. Login again.";
      case 500:
        return "Server error. Try later.";
      default:
        return "Unexpected error.";
    }
  }
}