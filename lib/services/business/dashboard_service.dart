import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';

Future<Map<String, dynamic>> fetchDashboard({
  required String token,
  required int businessId,
}) async {
  try {
    final url = ApiConfig.url("/api/v1/dashboard/business/$businessId");

    // 🚀 Request Logs
    print("========== DASHBOARD API REQUEST ==========");
    print("URL        : $url");
    print("METHOD     : GET");
    print("BUSINESS ID: $businessId");
    print("TOKEN      : ${token.substring(0, 10)}..."); // safe log
    print("HEADERS    : ${ApiConfig.headers(token: token)}");

    final response = await http
        .get(
      url,
      headers: ApiConfig.headers(token: token),
    )
        .timeout(const Duration(seconds: 15));

    // 📦 Response Logs
    print("========== DASHBOARD API RESPONSE ==========");
    print("STATUS CODE: ${response.statusCode}");
    print("BODY RAW   : ${response.body}");


    if (response.body.isEmpty) {
      throw Exception("Empty response from server");
    }

    final decoded = jsonDecode(response.body);

    print("BODY DECODED TYPE: ${decoded.runtimeType}");
    print("===========================================");

    if (response.statusCode == 200) {
      return decoded;
    } else {
      throw Exception(
        "Dashboard API Error → ${response.statusCode}: ${decoded.toString()}",
      );
    }
  } catch (e, stack) {
    // ❌ Error Logs
    print("========== DASHBOARD API ERROR ==========");
    print("ERROR: $e");
    print("STACK: $stack");
    print("========================================");

    rethrow;
  }
}