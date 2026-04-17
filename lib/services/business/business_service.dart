import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_list_model.dart';
import '../local_storage/local_storage.dart';


class BusinessService {
  static Future<List<Business>> fetchBusinesses() async {
    final token = await TokenStorage.getToken();

    final response = await http.get(
      ApiConfig.url(ApiConfig.businessList),
      headers: ApiConfig.headers(token: token),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Business.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }
}