import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/business_models/add_product_model.dart';

class CsvImportResult {
  final List<ProductModel> products;
  final List<String> errors;

  CsvImportResult({
    required this.products,
    required this.errors,
  });
}

class CsvImportService {
  /// Maps our internal field -> acceptable CSV headers (lowercase)
  static const Map<String, List<String>> _headerAliases = {
    "barcode": [
      "barcode",
      "code",
      "sku",
    ],
    "name": [
      "item name",
      "name",
      "productname",
      "product_name",
      "product name",
      "title",
    ],
    "price": [
      "price",
      "sellingprice",
      "selling_price",
      "selling price",
      "mrp",
      "amount",
    ],
    "stock": [
      "stock",
      "quantity",
      "qty",
    ],
    "gst_percent": [
      "gst",
      "GST",
      "gst_percent",
      "productgst",
      "product_gst",
      "product gst",
      "tax",
      "taxrate",
      "tax_rate",
      "tax rate",
    ],
  };

  List<String> _splitLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes &&
            i + 1 < line.length &&
            line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    fields.add(buffer.toString().trim());

    return fields;
  }

  Future<CsvImportResult> parseProducts({
    required File file,
    required int businessId,
  }) async {
    final csvString = await file.readAsString();

    final lines = csvString
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    debugPrint("CSV Lines : ${lines.length}");

    if (lines.isEmpty) {
      return CsvImportResult(
        products: [],
        errors: ["CSV file is empty."],
      );
    }

    final headers = _splitLine(lines.first)
        .map((e) => e.replaceAll('\uFEFF', '').trim().toLowerCase())
        .toList();

    debugPrint("Headers : $headers");

    final Map<String, int> resolvedIndex = {};
    final List<String> missing = [];

    _headerAliases.forEach((field, aliases) {
      final index = headers.indexWhere(
            (header) => aliases.contains(header),
      );

      if (index == -1) {
        missing.add(field);
      } else {
        resolvedIndex[field] = index;
      }
    });

    const requiredColumns = [
      "name",
      "price",
      "stock",
    ];

    final missingRequired = missing
        .where((e) => requiredColumns.contains(e))
        .toList();

    if (missingRequired.isNotEmpty) {
      return CsvImportResult(
        products: [],
        errors: [
          "Missing required column(s): ${missingRequired.join(", ")}"
        ],
      );
    }

    final barcodeIndex = resolvedIndex["barcode"];
    final nameIndex = resolvedIndex["name"]!;
    final priceIndex = resolvedIndex["price"]!;
    final stockIndex = resolvedIndex["stock"]!;
    final gstIndex = resolvedIndex["gst_percent"];

    final List<ProductModel> products = [];
    final List<String> errors = [];

    for (int i = 1; i < lines.length; i++) {
      try {
        final row = _splitLine(lines[i]);

        final barcode =
        barcodeIndex != null && barcodeIndex < row.length
            ? row[barcodeIndex].trim()
            : "";

        final name =
        nameIndex < row.length ? row[nameIndex].trim() : "";

        final price =
        priceIndex < row.length
            ? double.tryParse(row[priceIndex].trim()) ?? -1
            : -1;

        final stock =
        stockIndex < row.length
            ? int.tryParse(row[stockIndex].trim()) ?? -1
            : -1;

        final gst_percent = () {
          if (gstIndex == null || gstIndex >= row.length) return 0;

          final gstText = row[gstIndex]
              .trim()
              .replaceAll('%', '')
              .replaceAll(' ', '');

          return int.tryParse(gstText) ?? 0;
        }();

        if (name.isEmpty) {
          errors.add("Row ${i + 1}: Product name is empty.");
          continue;
        }

        if (price < 0) {
          errors.add("Row ${i + 1}: Invalid price.");
          continue;
        }

        if (stock < 0) {
          errors.add("Row ${i + 1}: Invalid stock.");
          continue;
        }

        products.add(
          ProductModel(
            businessId: businessId,
            barcode: barcode.isEmpty ? null : barcode,
            name: name,
            price: price.toDouble(),
            stock: stock,
            gst_percent: gst_percent.toString().isEmpty ? null : gst_percent,
          ),
        );
      } catch (e) {
        errors.add("Row ${i + 1}: $e");
        debugPrint("Error parsing row ${i + 1}: $e");
      }
    }
    debugPrint(
      "Imported Products : ${products.length}, Errors : ${errors.length}",
    );

    return CsvImportResult(
      products: products,
      errors: errors,
    );
  }
}