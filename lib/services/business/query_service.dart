import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';
import '../../models/business_models/query_model.dart';

class QueryService {
  Future<List<QueryModel>> getAllQueries({required String token}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/queries'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => QueryModel.fromJson(e)).toList();
    }

    throw Exception('Failed to fetch queries');
  }
  Future<void> deleteQuery({
    required int queryId,
    required String token,
  }) async {

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/queries/$queryId',
      ),
      headers: ApiConfig.headers(
        token: token,
      ),
    );

    print(
      "DELETE STATUS => ${response.statusCode}",
    );

    print(
      "DELETE BODY => ${response.body}",
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        response.body,
      );
    }
  }
  Future<void> updateQuery({
    required int queryId,
    required String status,
    required String adminResponse,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/queries/$queryId',
        ),
        headers: ApiConfig.headers(
          token: token,
        ),
        body: jsonEncode({
          "status": status,
          "admin_response": adminResponse,
        }),
      );

      print("================================");
      print("QUERY ID => $queryId");
      print("STATUS CODE => ${response.statusCode}");
      print("RESPONSE BODY => ${response.body}");
      print("================================");

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return;
      }

      throw Exception(
        "Update Query Failed\n"
            "Status Code: ${response.statusCode}\n"
            "Response: ${response.body}",
      );
    } catch (e, st) {
      print("================================");
      print("UPDATE QUERY ERROR");
      print(e);
      print(st);
      print("================================");

      rethrow;
    }
  }
  Future<List<QueryModel>> getQueries({required String token}) async {
    final response = await http.get(
      Uri.parse(ApiConfig.createQuery),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((e) => QueryModel.fromJson(e)).toList();
    }

    throw Exception('Failed to fetch queries');
  }

  Future<QueryModel> createQuery({
    required String message,
    required int businessId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createQuery),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({"message": message, "business_id": businessId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return QueryModel.fromJson(data);
      }

      throw Exception("Failed to create query");
    } catch (e) {
      throw Exception("Error creating query: $e");
    }
  }
}
