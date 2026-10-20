import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config/api_config.dart';
import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> fetchPublic({String? search}) {
    return _getList(
      ApiConfig.categories,
      search: search,
    );
  }

  Future<List<CategoryModel>> fetchAdmin({
    required String token,
    String? search,
    bool? isActive,
  }) {
    return _getList(
      ApiConfig.adminCategories,
      token: token,
      search: search,
      isActive: isActive,
    );
  }

  Future<void> create({
    required String token,
    required String name,
    required bool isActive,
  }) async {
    final response = await http
        .post(
          ApiConfig.url(ApiConfig.adminCategories),
          headers: ApiConfig.headers(token: token),
          body: jsonEncode({
            'name': name.trim(),
            'isActive': isActive,
          }),
        )
        .timeout(const Duration(seconds: 20));

    _ensureSuccess(response);
  }

  Future<void> update({
    required String token,
    required int id,
    required String name,
    required bool isActive,
  }) async {
    final response = await http
        .put(
          ApiConfig.url(ApiConfig.adminCategoryById(id)),
          headers: ApiConfig.headers(token: token),
          body: jsonEncode({
            'name': name.trim(),
            'isActive': isActive,
          }),
        )
        .timeout(const Duration(seconds: 20));

    _ensureSuccess(response);
  }

  /// Deactivates the category. [hard] deletes it permanently.
  Future<void> delete({
    required String token,
    required int id,
    bool hard = false,
  }) async {
    final uri = ApiConfig.url(ApiConfig.adminCategoryById(id)).replace(
      queryParameters: hard ? {'hard': 'true'} : null,
    );

    final response = await http
        .delete(
          uri,
          headers: ApiConfig.headers(token: token),
        )
        .timeout(const Duration(seconds: 20));

    _ensureSuccess(response);
  }

  Future<List<CategoryModel>> _getList(
    String endpoint, {
    String? token,
    String? search,
    bool? isActive,
  }) async {
    final query = <String, String>{};
    final trimmed = search?.trim() ?? '';
    if (trimmed.isNotEmpty) query['search'] = trimmed;
    if (isActive != null) query['is_active'] = isActive.toString();

    final uri = ApiConfig.url(endpoint).replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await http
        .get(
          uri,
          headers: ApiConfig.headers(token: token),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);
    _ensureSuccess(response, decoded: data);
    return _parseList(data);
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response');
    }
  }

  void _ensureSuccess(http.Response response, {dynamic decoded}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final data = decoded ?? _safeDecode(response);
    throw Exception(_message(data, response.statusCode));
  }

  dynamic _safeDecode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  String _message(dynamic data, int statusCode) {
    if (data is Map) {
      final detail = data['detail'] ?? data['message'] ?? data['error'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
        return first.toString();
      }
    }
    return 'Request failed ($statusCode)';
  }

  List<CategoryModel> _parseList(dynamic data) {
    dynamic list = data;
    if (data is Map) {
      list = data['data'] ?? data['categories'] ?? data['items'] ?? data['results'];
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
        .where((category) => category.id != 0 && category.name.isNotEmpty)
        .toList();
  }
}
