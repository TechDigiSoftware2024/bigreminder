import 'package:bigreminder/api_config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/business_models/add_product_model.dart';

class ImportResult {
  final int uploaded;
  final int failed;
  final List<String> errors;

  ImportResult({
    required this.uploaded,
    required this.failed,
    required this.errors,
  });
}

class ProductImportService {
  Future<ImportResult> uploadProducts({
    required List<ProductModel> products,
    required String token,
    required Function(int current, int total) onProgress,
  }) async {
    int uploaded = 0;
    int failed = 0;

    List<String> errors = [];

    for (int i = 0; i < products.length; i++) {
      final product = products[i];

      try {
        final payload = {
          "business_id": product.businessId,
          "barcode": product.barcode,
          "name": product.name,
          "price": product.price,
          "stock": product.stock,
        };

        debugPrint("Uploading product ${i + 1}/${products.length}: $payload");

        final response = await http.post(
          Uri.parse("${ApiConfig.baseUrl}${ApiConfig.products}"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(payload),
        );

        debugPrint(
          "Product '${product.name}' -> status ${response.statusCode}, "
              "body: ${response.body}",
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          uploaded++;
        } else {
          failed++;
          errors.add(
            "${product.name} (${response.statusCode}): ${response.body}",
          );
        }
      } catch (e, stack) {
        failed++;
        errors.add("${product.name}: ${e.toString()}");
        debugPrint("Exception uploading '${product.name}': $e");
        debugPrint("$stack");
      }

      onProgress(i + 1, products.length);
    }

    debugPrint(
      "Upload finished: uploaded=$uploaded, failed=$failed, errors=$errors",
    );

    return ImportResult(
      uploaded: uploaded,
      failed: failed,
      errors: errors,
    );
  }
}