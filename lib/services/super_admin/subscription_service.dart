import 'dart:convert';
import 'package:bigreminder/models/super_admin_models/subscription_model.dart';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';

class SubscriptionService {
  // ================================
  // 🔥 CREATE SUBSCRIPTION
  // ================================
  Future<SubscriptionModel> createSubscription({
    required String token,
    required int businessId,
    required int planId,
  }) async {
    final res = await http.post(
      ApiConfig.url(ApiConfig.subscriptions),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        "business_id": businessId,
        "plan_id": planId,
        "status": "pending",
        "payment_status": "pending",
        "start_date": DateTime.now().toIso8601String(),
        "end_date": DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        "auto_renew": true,
        "metadata": {}
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return SubscriptionModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("❌ Create failed: ${res.body}");
    }
  }

  // ================================
  // 🔥 GET CURRENT (same endpoint)
  // ================================
  Future<SubscriptionModel> getMySubscription(String token) async {
    final res = await http.get(
      ApiConfig.url(ApiConfig.subscriptions),
      headers: ApiConfig.headers(token: token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // backend can return object OR list
      if (data is List) {
        if (data.isEmpty) {
          throw Exception("❌ No subscription found");
        }
        return SubscriptionModel.fromJson(data.first);
      } else {
        return SubscriptionModel.fromJson(data);
      }
    } else {
      throw Exception("❌ Fetch failed: ${res.body}");
    }
  }

  // ================================
  // 🔥 GET ALL (list)
  // ================================
  Future<List<SubscriptionModel>> getAllSubscriptions(
      String token, {
        required int businessId, // 🔥 make required
      }) async {

    final uri = ApiConfig.url(ApiConfig.subscriptions).replace(
      queryParameters: {
        'business_id': businessId.toString(),
      },
    );

    print("🌐 FINAL URL: $uri");

    final res = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    print("📡 STATUS: ${res.statusCode}");
    print("📦 BODY: ${res.body}");

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list
          .map((e) => SubscriptionModel.fromJson(e))
          .toList();
    }

    throw Exception("❌ Fetch failed: ${res.body}");
  }
  // ================================
  // 🔥 UPDATE STATUS
  // ================================
  Future<void> updateSubscription({
    required String token,
    required int id,
    required String status,
    required String paymentStatus,
  }) async {
    final res = await http.patch(
      ApiConfig.url("${ApiConfig.subscriptions}/$id"),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        "status": status,
        "payment_status": paymentStatus,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("❌ Update failed: ${res.body}");
    }
  }
}