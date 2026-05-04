import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/super_admin_models/business_list_model.dart';

Future<List<Business>> fetchBusinessList(String token) async {
  final response = await http.get(
    ApiConfig.url(ApiConfig.businessList),
    headers: ApiConfig.headers(token: token),
  );

  print(response.statusCode);
  print(response.body); // DEBUG

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => Business.fromJson(e)).toList();
  } else {
    throw Exception("Error: ${response.statusCode}");
  }
}

Future<bool> deleteBusiness({
  required String token,
  required int businessId,
}) async {
  final response = await http.delete(
    ApiConfig.url("${ApiConfig.businessList}/$businessId"),
    headers: ApiConfig.headers(token: token),
  );

  print("DELETE STATUS: ${response.statusCode}");
  print("DELETE BODY: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 204) {
    return true;
  } else {
    throw Exception("Failed to delete business: ${response.statusCode}");
  }
}