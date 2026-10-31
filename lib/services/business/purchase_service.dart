import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_models/business_purchase_list_model.dart';
import '../../models/business_models/create_purchase_model.dart';
import '../../models/business_models/create_purchase_response_model.dart';

class PurchaseService {
  Future<List<PurchaseModel>> getPurchases({
    required String token,
    required int businessId,
    int? customerId,
  }) async {
    try {
      final queryParams = {
        'business_id': businessId.toString(),
        if (customerId != null)
          'customer_id': customerId.toString(),
      };

      final uri = ApiConfig.url(
        ApiConfig.purchases,
      ).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headers(
          token: token,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load purchases (${response.statusCode})',
        );
      }

      final Map<String, dynamic> jsonData =
      jsonDecode(response.body);
debugPrint("RESPONSE BODY:${response.body}");
      if (jsonData['success'] != true) {
        throw Exception(
          'API returned success = false',
        );
      }

      final List<dynamic> data =
          jsonData['data'] as List<dynamic>? ?? [];

      return data
          .map((e) => PurchaseModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to load purchases: $e',
      );
    }
  }
  // static Future<String> createPurchase({
  //   required String token,
  //   required CreatePurchaseModel model,
  // }) async {
  //
  //   try {
  //
  //     final response = await http.post(
  //       ApiConfig.url(ApiConfig.purchases),
  //
  //       headers: ApiConfig.headers(token: token),
  //
  //       body: jsonEncode(model.toJson()),
  //     );
  //
  //     final data = jsonDecode(response.body);
  //
  //     /// 🔥 SUCCESS
  //     if (response.statusCode == 200 ||
  //         response.statusCode == 201) {
  //
  //       return data["message"] ?? "Purchase created successfully";
  //     }
  //
  //     /// 🔥 API ERROR
  //     throw Exception(
  //       data["detail"] ??
  //           data["message"] ??
  //           "Failed to create purchase",
  //     );
  //
  //   } on SocketException {
  //     throw Exception("No internet connection");
  //
  //   } on HttpException {
  //     throw Exception("Server error");
  //
  //   } on FormatException {
  //     throw Exception("Invalid server response");
  //
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }

  static Future<CreatePurchaseResponseModel> createPurchase({
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handles both a bare bill object and one wrapped in "data".
        final billJson = (data is Map && data['data'] is Map)
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;

        return CreatePurchaseResponseModel.fromJson(billJson);
      }

      throw Exception(_purchaseErrorMessage(data));
    } on SocketException {
      throw Exception("No internet connection");
    } on HttpException {
      throw Exception("Server error");
    } on FormatException {
      throw Exception("Invalid server response");
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception("Failed to create purchase");
    }
  }
}

String _purchaseErrorMessage(dynamic data) {
  final text = _purchaseErrorValue(data);
  if (text != null && text.trim().isNotEmpty) return text.trim();
  return 'Failed to create purchase';
}

String? _purchaseErrorValue(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is List) {
    return _joinErrorParts(value.map(_purchaseErrorValue));
  }
  if (value is Map) {
    return _joinErrorParts([
      for (final key in ['message', 'msg', 'detail', 'error', 'reason'])
        if (value.containsKey(key)) _purchaseErrorValue(value[key]),
    ]);
  }
  return null;
}

String? _joinErrorParts(Iterable<String?> parts) {
  final unique = <String>[];
  for (final part in parts) {
    final trimmed = part?.trim() ?? '';
    if (trimmed.isEmpty) continue;
    final exists = unique.any(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) unique.add(trimmed);
  }
  if (unique.isEmpty) return null;
  return unique.join('\n');
}