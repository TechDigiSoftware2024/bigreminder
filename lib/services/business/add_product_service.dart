import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_models/add_product_model.dart';

class ProductService {
  Future<List<ProductModel>> getProducts({
    required String token,
    required int businessId,
  }) async {
    final uri = Uri.parse(
      "${ApiConfig.baseUrl}${ApiConfig.products}?business_id=$businessId",
    );

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = jsonDecode(response.body);

      return data.map((e) => ProductModel.fromJson(e)).toList();
    }

    throw Exception(
      "Failed to load products (${response.statusCode}): ${response.body}",
    );
  }

  Future<ProductModel> createProduct({
    required String token,
    required ProductModel product,
  }) async {
    final response = await http.post(
      ApiConfig.url(ApiConfig.products),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProductModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Unable to create product");
  }

  /// Update Product
  Future<ProductModel> updateProduct({
    required String token,
    required int productId,
    required ProductModel product,
  }) async {
    final response = await http.patch(
      ApiConfig.url("${ApiConfig.products}/$productId"),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProductModel.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      "Unable to update product (${response.statusCode}): ${response.body}",
    );
  }

  /// Delete Product
  Future<void> deleteProduct({
    required String token,
    required int productId,
  }) async {
    final response = await http.delete(
      ApiConfig.url("${ApiConfig.products}/$productId"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    throw Exception(
      "Unable to delete product (${response.statusCode}): ${response.body}",
    );
  }
}