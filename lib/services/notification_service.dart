import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api_config/api_config.dart';
import '../models/business_models/notification_history_model.dart';
import '../models/business_models/notification_req_model.dart';
import '../providers/business/business_provider.dart';

class NotificationService {
  final String baseUrl;
  final Ref ref;

  NotificationService({
    required this.baseUrl,
    required this.ref,
  });

  Map<String, String> _headers() {
    final token = ref.read(tokenProvider);
    return ApiConfig.headers(token: token);
  }

  Future<int> _getBusinessId(NotificationRequest request) async {
    if (request.businessId != 0) return request.businessId;

    try {
      final id = ref.read(businessIdProvider);
      if (id != 0) return id;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("businessId");

    if (id != null && id != 0) return id;

    throw AppError("Your business is not ready yet. Please login again.");
  }

  Future<List<NotificationHistoryItem>> fetchHistory({
    required int businessId,
    String? type,
    String? status,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = <String, String>{
        'business_id': businessId.toString(),
        'limit': limit.clamp(1, 200).toString(),
        'offset': offset < 0 ? '0' : offset.toString(),
      };

      if (type != null && type.trim().isNotEmpty) {
        query['type'] = type.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        query['status'] = status.trim();
      }
      if (fromDate != null && fromDate.trim().isNotEmpty) {
        query['from_date'] = fromDate.trim();
      }
      if (toDate != null && toDate.trim().isNotEmpty) {
        query['to_date'] = toDate.trim();
      }

      final uri = ApiConfig.url('/api/v1/notifications/history')
          .replace(queryParameters: query);

      final response = await http.get(uri, headers: _headers());

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : [];

        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => NotificationHistoryItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        }

        if (data is Map) {
          final list = data['items'] ??
              data['data'] ??
              data['notifications'] ??
              data['results'];
          if (list is List) {
            return list
                .whereType<Map>()
                .map((e) => NotificationHistoryItem.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList();
          }
        }

        return [];
      }

      _handleResponse(response);
      return [];
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError('Unable to load notification history.');
    }
  }

  Future<void> sendNow(NotificationRequest request) async {
    final businessId = await _getBusinessId(request);

    try {
      final response = await http.post(
        ApiConfig.url("/api/v1/notifications/send-now"),
        headers: _headers(),
        body: jsonEncode(
          request.copyWith(businessId: businessId).toSendNowJson(),
        ),
      );

      _handleResponse(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError("No internet connection. Please try again.");
    }
  }

  Future<void> send(NotificationRequest request) async {
    final businessId = await _getBusinessId(request);

    try {
      final response = await http.post(
        ApiConfig.url("/api/v1/notifications/send"),
        headers: _headers(),
        body: jsonEncode(
          request.copyWith(businessId: businessId).toSendJson(),
        ),
      );

      _handleResponse(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError("Unable to send right now. Try again.");
    }
  }

  Future<void> broadcast(NotificationRequest request) async {
    final businessId = await _getBusinessId(request);

    try {
      final response = await http.post(
        ApiConfig.url("/api/v1/notifications/broadcast"),
        headers: _headers(),
        body: jsonEncode(
          request.copyWith(businessId: businessId).toBroadcastJson(),
        ),
      );

      _handleResponse(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError("Broadcast failed. Please retry.");
    }
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    print("❌ API ERROR: ${response.statusCode}");
    print("❌ BODY: ${response.body}");

    String? apiMessage;

    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        apiMessage = data["message"] ?? data["error"] ?? data["detail"];
      }
    } catch (_) {}

    if (apiMessage != null && apiMessage.isNotEmpty) {
      throw AppError(apiMessage);
    }

    switch (response.statusCode) {
      case 400:
        throw AppError("Invalid request. Please check input.");
      case 401:
        throw AppError("Session expired. Please login again.");
      case 403:
        throw AppError("You are not allowed to perform this action.");
      case 404:
        throw AppError("Service not found.");
      case 500:
        throw AppError("Server error. Try again later.");
      default:
        throw AppError("Something went wrong.");
    }
  }
}

class AppError implements Exception {
  final String message;

  AppError(this.message);

  @override
  String toString() {
    return message;
  }
}
