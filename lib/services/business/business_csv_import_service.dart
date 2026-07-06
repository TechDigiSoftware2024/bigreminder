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
  // Maps our internal field -> list of acceptable header names (all lowercase).
  static const Map<String, List<String>> _headerAliases = {
    "barcode": ["barcode", "code", "sku"],
    "name": ["name", "productname", "product_name", "product name", "title"],
    "price": ["price", "sellingprice", "selling_price", "selling price", "mrp", "amount"],
    "stock": ["stock", "quantity", "qty"],
  };

  /// Splits a single CSV line into fields, stripping surrounding quotes
  /// and unescaping doubled quotes ("" -> "). Does NOT support fields
  /// containing embedded commas or newlines inside quotes — this is a
  /// deliberate tradeoff so one stray quote can't swallow the whole file.
  List<String> _splitLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
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

    // Normalize line endings, split into lines, drop blank lines.
    final lines = csvString
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    debugPrint("CSV: total lines read = ${lines.length}");

    if (lines.isEmpty) {
      return CsvImportResult(
        products: [],
        errors: ["CSV file is empty."],
      );
    }

    final headers = _splitLine(lines.first)
        .map((e) => e.trim().toLowerCase())
        .toList();

    debugPrint("CSV: headers found = $headers");

    // Resolve each required field to whichever column index matches an alias.
    final Map<String, int> resolvedIndex = {};
    final List<String> missing = [];

    _headerAliases.forEach((field, aliases) {
      final idx = headers.indexWhere((h) => aliases.contains(h));
      if (idx == -1) {
        missing.add(field);
      } else {
        resolvedIndex[field] = idx;
      }
    });

    debugPrint("CSV: resolvedIndex = $resolvedIndex, missing = $missing");

    // Only name, price, and stock are truly required. Barcode is optional.
    const hardRequired = ["name", "price", "stock"];
    final missingHard = missing.where((m) => hardRequired.contains(m)).toList();

    if (missingHard.isNotEmpty) {
      debugPrint("CSV: aborting, missing hard-required columns = $missingHard");
      return CsvImportResult(
        products: [],
        errors: [
          "Missing required column(s): ${missingHard.join(', ')}. "
              "Found headers: ${headers.join(', ')}",
        ],
      );
    }

    final barcodeIndex = resolvedIndex["barcode"]; // may be null, that's fine
    final nameIndex = resolvedIndex["name"]!;
    final priceIndex = resolvedIndex["price"]!;
    final stockIndex = resolvedIndex["stock"]!;

    List<ProductModel> products = [];
    List<String> errors = [];

    for (int i = 1; i < lines.length; i++) {
      final row = _splitLine(lines[i]);

      try {
        final barcode = barcodeIndex != null && barcodeIndex < row.length
            ? row[barcodeIndex].trim()
            : "";
        final name = nameIndex < row.length ? row[nameIndex].trim() : "";
        final price = priceIndex < row.length
            ? double.tryParse(row[priceIndex].trim()) ?? -1
            : -1;
        final stock = stockIndex < row.length
            ? int.tryParse(row[stockIndex].trim()) ?? -1
            : -1;

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
            barcode: barcode,
            name: name,
            price: price.toDouble(),
            stock: stock,
          ),
        );
      } catch (e) {
        errors.add("Row ${i + 1}: ${e.toString()}");
        debugPrint("CSV: row ${i + 1} threw exception: $e");
      }
    }

    debugPrint("CSV: parsed products = ${products.length}, errors = ${errors.length}");
    if (errors.isNotEmpty) {
      debugPrint("CSV: error details = $errors");
    }

    return CsvImportResult(
      products: products,
      errors: errors,
    );
  }
}