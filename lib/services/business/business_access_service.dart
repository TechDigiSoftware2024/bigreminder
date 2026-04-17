import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';
import '../../models/business_access_model.dart';
import '../local_storage/local_storage.dart';

class BusinessAccessService {

  /// 🔥 GET ACCESS
  static Future<BusinessAccess> fetchAccess(int businessId) async {
    final token = await TokenStorage.getToken();

    final response = await http.get(
      ApiConfig.url("${ApiConfig.businessAccess}/$businessId"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return BusinessAccess.fromJson(data);
    } else {
      throw Exception("Fetch failed: ${response.statusCode}");
    }
  }

  /// 🔥 PATCH UPDATE (FINAL FIX)
  static Future<void> updateAccess(BusinessAccess access) async {
    final token = await TokenStorage.getToken();

    final response = await http.patch(
      ApiConfig.url("${ApiConfig.businessAccess}/${access.businessId}"),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(access.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Update failed: ${response.statusCode}");
    }
  }
}