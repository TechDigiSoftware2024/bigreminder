import 'dart:convert';

import 'package:bigreminder/api_config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

    final List<String> errors = [];

    for (int i = 0; i < products.length; i++) {
      final product = products[i];

      try {
        final payload = {
          "business_id": product.businessId,
          "barcode": product.barcode?.trim().isNotEmpty == true
              ? product.barcode!.trim()
              : "",
          "name": product.name,
          "price": product.price,
          "gst_percent": product.gst_percent.toString() ?? 0,
          "stock": product.stock,
        };
        debugPrint(product.gst_percent.toString()+"GST");

        debugPrint(
          "Uploading ${i + 1}/${products.length}\n"
              "Payload: ${jsonEncode(payload)}",
        );

        final response = await http.post(
          Uri.parse("${ApiConfig.baseUrl}${ApiConfig.products}"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(payload),
        );

        debugPrint(
          "Status: ${response.statusCode}\n"
              "Response: ${response.body}",
        );

        if (response.statusCode == 200 ||
            response.statusCode == 201) {
          uploaded++;
        } else {
          failed++;

          errors.add(
            "${product.name} (${response.statusCode})\n${response.body}",
          );
        }
      } catch (e, stackTrace) {
        failed++;

        errors.add("${product.name}: $e");

        debugPrint("Exception while uploading ${product.name}");
        debugPrint(e.toString());
        debugPrint(stackTrace.toString());
      }

      onProgress(i + 1, products.length);
    }

    debugPrint(
      "Finished Upload\n"
          "Uploaded : $uploaded\n"
          "Failed   : $failed",
    );

    return ImportResult(
      uploaded: uploaded,
      failed: failed,
      errors: errors,
    );
  }
}