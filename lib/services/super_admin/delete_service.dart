import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';

class DeleteService {
  // ================= DELETE PLAN =================
  static Future<String> deletePlan({
    required int planId,
    String? token,
  }) async {
    try {
      final response = await http.delete(
        ApiConfig.url("/api/v1/plans/$planId"),
        headers: ApiConfig.headers(token: token),
      );

      // SUCCESS
      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return "Plan deleted successfully";
      }

      // SERVER MESSAGE
      final data = jsonDecode(response.body);

      return data["message"] ??
          "Unable to delete plan";
    }

    // INTERNET ISSUE
    catch (e) {
      return "Something went wrong. Please check your internet connection.";
    }
  }

  // ================= DELETE FEATURE =================
  static Future<String> deleteFeature({
    required int featureId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        ApiConfig.url("/api/v1/features/$featureId"),
        headers: ApiConfig.headers(token: token),
      );

      // SUCCESS
      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return "Feature deleted successfully";
      }

      // SERVER MESSAGE
      final data = jsonDecode(response.body);

      return data["message"] ??
          "Unable to delete feature";
    }

    // INTERNET ISSUE
    catch (e) {
      return "Something went wrong. Please check your internet connection.";
    }
  }
}