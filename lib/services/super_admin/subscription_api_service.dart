import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';

class PlanAndFeatureService {

  void _logRequest(String title, http.Response res, String token) {
    print("====================================");
    print("🚀 API: $title");
    print("🌐 URL: ${res.request?.url}");
    print("🔑 TOKEN: ${token.isEmpty ? "❌ EMPTY" : "✅ PRESENT"}");
    print("📊 STATUS: ${res.statusCode}");
    print("📦 BODY: ${res.body}");
    print("====================================");
  }

  // ================================
  // ✅ GET ALL PLANS
  // ================================
  Future<List<Map<String, dynamic>>> getPlans(String token) async {
    final res = await http.get(
      ApiConfig.url("/api/v1/plans"),
      headers: ApiConfig.headers(token: token),
    );

    _logRequest("GET PLANS", res, token);

    if (res.statusCode != 200) {
      throw Exception("Plans failed: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    if (decoded is Map && decoded['data'] is List) {
      return List<Map<String, dynamic>>.from(decoded['data']);
    }

    throw Exception("Invalid response format");
  }

  // ================================
  // ✅ GET PLAN BY ID
  // ================================
  Future<Map<String, dynamic>> getPlanById(
      String token,
      int id,
      ) async {
    final res = await http.get(
      ApiConfig.url("/api/v1/plans/$id"),
      headers: ApiConfig.headers(token: token),
    );

    _logRequest("GET PLAN BY ID", res, token);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch plan");
    }

    return jsonDecode(res.body);
  }

  // ================================
  // ✅ CREATE PLAN (FIXED)
  // ================================
  Future<void> createPlan({
    required String token,
    required String name,
    required int price,
    String duration = "monthly",
    String billingCycle = "monthly",
    int durationDays = 30,
    int trialDays = 0,
    bool isActive = true,
  }) async {

    final body = {
      "name": name,
      "price": price,
      "duration": duration,
      "billing_cycle": billingCycle,
      "duration_days": durationDays,
      "trial_days": trialDays,
      "is_active": isActive,
    };

    final res = await http.post(
      ApiConfig.url("/api/v1/plans"),
      headers: {
        ...ApiConfig.headers(token: token),
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    _logRequest("CREATE PLAN", res, token);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Create Plan Failed: ${res.body}");
    }
  }

  // ================================
  // ✅ GET FEATURES
  // ================================
  Future<List<Map<String, dynamic>>> getFeatures(String token) async {
    final res = await http.get(
      ApiConfig.url("/api/v1/features"),
      headers: ApiConfig.headers(token: token),
    );

    _logRequest("GET FEATURES", res, token);

    if (res.statusCode != 200) {
      throw Exception("Features failed: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    if (decoded is Map && decoded['data'] is List) {
      return List<Map<String, dynamic>>.from(decoded['data']);
    }

    throw Exception("Invalid response format");
  }

  // ================================
  // ✅ CREATE FEATURE
  // ================================
  Future<void> createFeature({
    required String token,
    required String key,
    required String name,
    required String description,
  }) async {
    final body = {
      "key": key,
      "name": name,
      "description": description,
      "is_active": true,
    };

    final res = await http.post(
      ApiConfig.url("/api/v1/features"),
      headers: {
        ...ApiConfig.headers(token: token),
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    _logRequest("CREATE FEATURE", res, token);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Create Feature Failed: ${res.body}");
    }
  }

  // ================================
  // ✅ GET PLAN FEATURES (FIXED SAFE)
  // ================================
  Future<List<Map<String, dynamic>>> getPlanFeatures(
      String token, int planId) async {

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/v1/plan-features?plan_id=$planId"),
      headers: ApiConfig.headers(token: token),
    );

    _logRequest("GET PLAN FEATURES", res, token);

    if (res.statusCode != 200) {
      throw Exception("Plan features failed: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    print("📦 PLAN FEATURES DECODED: $decoded");

    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    }

    if (decoded is Map && decoded['data'] is List) {
      return List<Map<String, dynamic>>.from(decoded['data']);
    }

    throw Exception("Invalid response format");
  }

  // ================================
  // ➕ ADD FEATURE TO PLAN (FIXED)
  // ================================
  Future<void> addFeatureToPlan({
    required String token,
    required int planId,
    required int featureId,
  }) async {
    if (planId <= 0 || featureId <= 0) {
      throw Exception("Invalid IDs: planId=$planId, featureId=$featureId");
    }

    final body = {
      "plan_id": planId,
      "feature_id": featureId,
    };

    final res = await http.post(
      ApiConfig.url("/api/v1/plan-features"),
      headers: {
        ...ApiConfig.headers(token: token),
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    _logRequest("ADD FEATURE TO PLAN", res, token);

    if (res.statusCode == 200 || res.statusCode == 201) return;

    // ✅ Now throws instead of silently returning — lets UI rollback properly
    throw Exception("Add feature failed [${res.statusCode}]: ${res.body}");
  }

  // ================================
  // ❌ REMOVE FEATURE FROM PLAN
  // ================================

  Future<void> removeFeatureFromPlan({
    required String token,
    required int planId,
    required int featureId,
  }) async {
    final res = await http.delete(
      ApiConfig.url("/api/v1/plan-features/$planId/$featureId"),
      headers: ApiConfig.headers(token: token),
    );

    _logRequest("REMOVE FEATURE FROM PLAN", res, token);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("Remove feature failed: ${res.body}");
    }
  }
}