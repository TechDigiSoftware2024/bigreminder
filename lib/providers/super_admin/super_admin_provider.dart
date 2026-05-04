import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../business/business_provider.dart';


/// ================= USERS =================
final userProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = ref.read(tokenProvider);

  final response = await http.get(
    ApiConfig.url(ApiConfig.totalUserList),
    headers: ApiConfig.headers(token: token),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    // 🔥 handle both formats
    if (data is List) return data;
    if (data["data"] != null) return data["data"];

    return [];
  }

  throw Exception("Failed to load users");
});

/// ================= BUSINESSES =================
final businessListProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = ref.read(tokenProvider);

  final response = await http.get(
    ApiConfig.url(ApiConfig.businessList),
    headers: ApiConfig.headers(token: token),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) return data;
    if (data["data"] != null) return data["data"];

    return [];
  }

  throw Exception("Failed to load businesses");
});