import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_list_model.dart';

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