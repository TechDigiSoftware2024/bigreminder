import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/total_user_model.dart';

class UserService {
  Future<TotalUserModel> fetchUsers({String? token}) async {
    final response = await http
        .get(
      ApiConfig.url(ApiConfig.totalUserList),
      headers: ApiConfig.headers(token: token),
    )
        .timeout(const Duration(seconds: 10));

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List usersList = [];

      // ✅ handle ALL possible backend structures
      if (decoded is List) {
        usersList = decoded;
      } else if (decoded['data'] is List) {
        usersList = decoded['data'];
      } else if (decoded['data']?['users'] is List) {
        usersList = decoded['data']['users'];
      } else if (decoded['users'] is List) {
        usersList = decoded['users'];
      } else {
        throw Exception("Invalid API structure: $decoded");
      }

      return TotalUserModel.fromJson(usersList);
    } else {
      throw Exception(
        "Failed: ${response.statusCode} | ${response.body}",
      );
    }
  }
}