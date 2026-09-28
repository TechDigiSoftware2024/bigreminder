import 'dart:convert';
import 'package:bigreminder/models/super_admin_models/subscription_model.dart';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';

class SubscriptionService {
  // ================================
  // CREATE — POST /api/v1/subscriptions
  // ================================
  Future<SubscriptionModel> createSubscription({
    required String token,
    required int businessId,
    required int planId,
    String status = 'pending',
    String paymentStatus = 'pending',
    bool autoRenew = true,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
  }) async {
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));

    final res = await http.post(
      ApiConfig.url(ApiConfig.subscriptions),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'business_id': businessId,
        'plan_id': planId,
        'status': status,
        'payment_status': paymentStatus,
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'auto_renew': autoRenew,
        'metadata': metadata ?? {},
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return SubscriptionModel.fromJson(_unwrapMap(jsonDecode(res.body)));
    }
    throw Exception(
      _errorMessage(
        res.body,
        statusCode: res.statusCode,
        fallback: 'Create failed',
      ),
    );
  }

  // ================================
  // LIST — GET /api/v1/subscriptions
  // Optional ?business_id=
  // ================================
  Future<List<SubscriptionModel>> getAllSubscriptions(
    String token, {
    int? businessId,
  }) async {
    final uri = businessId == null
        ? ApiConfig.url(ApiConfig.subscriptions)
        : ApiConfig.url(ApiConfig.subscriptions).replace(
            queryParameters: {'business_id': businessId.toString()},
          );

    final res = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (res.statusCode == 200) {
      final list = _unwrapList(jsonDecode(res.body));
      return list
          .map((e) => SubscriptionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception(
      _errorMessage(res.body, statusCode: res.statusCode, fallback: 'Fetch failed'),
    );
  }

  // ================================
  // GET ONE — GET /api/v1/subscriptions/{subscription_id}
  // ================================
  Future<SubscriptionModel> getSubscriptionById({
    required String token,
    required int subscriptionId,
  }) async {
    final res = await http.get(
      ApiConfig.url(ApiConfig.subscriptionById(subscriptionId)),
      headers: ApiConfig.headers(token: token),
    );

    if (res.statusCode == 200) {
      return SubscriptionModel.fromJson(_unwrapMap(jsonDecode(res.body)));
    }
    throw Exception(
      _errorMessage(res.body, statusCode: res.statusCode, fallback: 'Fetch failed'),
    );
  }

  // ================================
  // UPDATE — PUT/PATCH /api/v1/subscriptions/{subscription_id}
  // ================================
  Future<SubscriptionModel> updateSubscription({
    required String token,
    required int subscriptionId,
    int? planId,
    String? status,
    String? paymentStatus,
    bool? autoRenew,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{};
    if (planId != null) body['plan_id'] = planId;
    if (status != null) body['status'] = status;
    if (paymentStatus != null) body['payment_status'] = paymentStatus;
    if (autoRenew != null) body['auto_renew'] = autoRenew;
    if (startDate != null) body['start_date'] = startDate.toIso8601String();
    if (endDate != null) body['end_date'] = endDate.toIso8601String();
    if (metadata != null) body['metadata'] = metadata;

    // Prefer PUT for full admin update; fall back to PATCH if needed.
    var res = await http.put(
      ApiConfig.url(ApiConfig.subscriptionById(subscriptionId)),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    if (res.statusCode == 405 || res.statusCode == 404) {
      res = await http.patch(
        ApiConfig.url(ApiConfig.subscriptionById(subscriptionId)),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(body),
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        return SubscriptionModel.fromJson(_unwrapMap(decoded));
      }
      // Some APIs return empty body on success — re-fetch.
      return getSubscriptionById(
        token: token,
        subscriptionId: subscriptionId,
      );
    }
    throw Exception(
      _errorMessage(res.body, statusCode: res.statusCode, fallback: 'Update failed'),
    );
  }

  // ================================
  // DELETE — DELETE /api/v1/subscriptions/{subscription_id}
  // ================================
  Future<void> deleteSubscription({
    required String token,
    required int subscriptionId,
  }) async {
    final res = await http.delete(
      ApiConfig.url(ApiConfig.subscriptionById(subscriptionId)),
      headers: ApiConfig.headers(token: token),
    );

    if (res.statusCode == 200 ||
        res.statusCode == 204 ||
        (res.statusCode >= 200 && res.statusCode < 300)) {
      return;
    }
    throw Exception(
      _errorMessage(res.body, statusCode: res.statusCode, fallback: 'Delete failed'),
    );
  }

  // ================================
  // Legacy helper: current user's subscription from list endpoint
  // ================================
  Future<SubscriptionModel> getMySubscription(String token) async {
    final list = await getAllSubscriptions(token);
    if (list.isEmpty) {
      throw Exception('No subscription found');
    }
    return list.first;
  }

  // ---------- response helpers ----------

  Map<String, dynamic> _unwrapMap(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }
    throw Exception('Invalid subscription response');
  }

  List<dynamic> _unwrapList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final data = decoded['data'] ??
          decoded['subscriptions'] ??
          decoded['items'] ??
          decoded['results'];
      if (data is List) return data;
      // Single object returned as map
      if (decoded['id'] != null) return [decoded];
    }
    throw Exception('Invalid subscriptions list response');
  }

  String _errorMessage(
    String body, {
    required String fallback,
    int? statusCode,
  }) {
    String? serverMsg;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded['message'] ??
            decoded['detail'] ??
            decoded['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          serverMsg = msg.toString();
        }
      }
    } catch (_) {}

    final lower = '${serverMsg ?? ''} $body'.toLowerCase();
    final looksDuplicate = lower.contains('already') ||
        lower.contains('duplicate') ||
        lower.contains('unique') ||
        lower.contains('exists') ||
        lower.contains('conflict');

    if (statusCode == 409 || looksDuplicate) {
      return 'This business already has a subscription. Edit or remove the existing one first.';
    }
    if (statusCode == 500 ||
        lower.contains('internal server') ||
        lower.contains('internal error')) {
      return 'Could not assign subscription. This business may already have one — edit or delete it, then try again.';
    }
    if (statusCode == 404) {
      return 'Business or plan not found.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return statusCode == 401
          ? 'Session expired. Please login again.'
          : "You don't have permission to do this.";
    }

    if (serverMsg != null &&
        serverMsg.length < 140 &&
        !serverMsg.toLowerCase().contains('<html')) {
      return serverMsg;
    }
    if (statusCode != null) return '$fallback ($statusCode)';
    return fallback;
  }
}
