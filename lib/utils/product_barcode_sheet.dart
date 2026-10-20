import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'formatters.dart';

/// One sticker size. Columns and rows are how many of that size fit on A4.
class BarcodeLabelPreset {
  final String id;
  final String name;
  final double widthMm;
  final double heightMm;

  const BarcodeLabelPreset({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.heightMm,
  });

  static const List<BarcodeLabelPreset> options = [
    BarcodeLabelPreset(
      id: 'small',
      name: 'Small',
      widthMm: 38,
      heightMm: 25,
    ),
    BarcodeLabelPreset(
      id: 'compact',
      name: 'Compact',
      widthMm: 50,
      heightMm: 30,
    ),
    BarcodeLabelPreset(
      id: 'medium',
      name: 'Medium',
      widthMm: 64,
      heightMm: 34,
    ),
    BarcodeLabelPreset(
      id: 'large',
      name: 'Large',
      widthMm: 70,
      heightMm: 40,
    ),
    BarcodeLabelPreset(
      id: 'shelf',
      name: 'Shelf',
      widthMm: 100,
      heightMm: 50,
    ),
  ];

  String get sizeLabel =>
      '${widthMm.toStringAsFixed(0)} × ${heightMm.toStringAsFixed(0)} mm';

  /// How many labels of this size fit on A4 with a small gap and margin.
  SheetFit fitOnA4({double marginMm = 6, double gapMm = 2}) {
    int fit(double pageMm, double itemMm) {
      var count = 0;
      while (true) {
        final next = count + 1;
        final used = marginMm * 2 + next * itemMm + (next - 1) * gapMm;
        if (used <= pageMm + 0.01) {
          count = next;
        } else {
          break;
        }
      }
      return count < 1 ? 1 : count;
    }

    return SheetFit(
      columns: fit(210, widthMm),
      rows: fit(297, heightMm),
    );
  }
}

class SheetFit {
  final int columns;
  final int rows;

  const SheetFit({required this.columns, required this.rows});

  int get perSheet => columns * rows;
}

class PrintableProductLabel {
  final String name;
  final String barcode;
  final double mrp;
  final double sellingPrice;
  final int copies;

  const PrintableProductLabel({
    required this.name,
    required this.barcode,
    required this.mrp,
    required this.sellingPrice,
    required this.copies,
  });
}

/// In-store EAN-13. Leading 2 marks an internal code, plus a valid check digit.
String generateStoreBarcode(Set<String> used) {
  var seed = DateTime.now().microsecondsSinceEpoch;
  while (true) {
    final body = '2${(seed % 100000000000).toString().padLeft(11, '0')}';
    final code = '$body${ean13CheckDigit(body)}';
    if (used.add(code)) return code;
    seed++;
  }
}

int ean13CheckDigit(String twelveDigits) {
  if (twelveDigits.length != 12) {
    throw ArgumentError('EAN-13 body must be 12 digits');
  }
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final digit = int.parse(twelveDigits[i]);
    sum += i.isEven ? digit : digit * 3;
  }
  return (10 - (sum % 10)) % 10;
}

Future<void> printProductBarcodeSheet({
  required List<PrintableProductLabel> labels,
  required BarcodeLabelPreset preset,
  required int columns,
  required int rows,
}) async {
  final bytes = await buildProductBarcodePdf(
    labels: labels,
    preset: preset,
    columns: columns,
    rows: rows,
  );

  await Printing.layoutPdf(
    name: 'Product-barcodes',
    format: PdfPageFormat.a4,
    onLayout: (_) async => bytes,
  );
}

Future<Uint8List> buildProductBarcodePdf({
  required List<PrintableProductLabel> labels,
  required BarcodeLabelPreset preset,
  required int columns,
  required int rows,
}) async {
  final expanded = <PrintableProductLabel>[];
  for (final label in labels) {
    final copies = label.copies < 1 ? 1 : label.copies;
    for (var i = 0; i < copies; i++) {
      expanded.add(label);
    }
  }

  if (expanded.isEmpty) {
    throw StateError('No labels to print');
  }

  final fonts = await _labelFonts();
  final perSheet = columns * rows;
  const marginMm = 6.0;
  const gapMm = 2.0;
  final pdf = pw.Document();

  for (var start = 0; start < expanded.length; start += perSheet) {
    final pageItems = expanded.skip(start).take(perSheet).toList();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(marginMm * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            children: [
              for (var row = 0; row < rows; row++)
                pw.Padding(
                  padding: pw.EdgeInsets.only(
                    bottom: row == rows - 1 ? 0 : gapMm * PdfPageFormat.mm,
                  ),
                  child: pw.Row(
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) pw.SizedBox(width: gapMm * PdfPageFormat.mm),
                        _labelBox(
                          item: _itemAt(pageItems, row * columns + col),
                          preset: preset,
                          regular: fonts.regular,
                          bold: fonts.bold,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}

PrintableProductLabel? _itemAt(List<PrintableProductLabel> items, int index) {
  if (index < 0 || index >= items.length) return null;
  return items[index];
}

pw.Widget _labelBox({
  required PrintableProductLabel? item,
  required BarcodeLabelPreset preset,
  required pw.Font regular,
  required pw.Font bold,
}) {
  final width = preset.widthMm * PdfPageFormat.mm;
  final height = preset.heightMm * PdfPageFormat.mm;

  if (item == null) {
    return pw.SizedBox(width: width, height: height);
  }

  final compact = preset.heightMm <= 26;
  final nameSize = preset.heightMm >= 40
      ? 9.0
      : preset.heightMm >= 30
          ? 7.0
          : 5.5;
  final priceSize = compact ? 5.0 : nameSize - 0.5;
  final codeSize = compact ? 5.0 : 6.5;
  final barcodeHeight = height * (compact ? 0.36 : 0.42);

  return pw.Container(
    width: width,
    height: height,
    padding: pw.EdgeInsets.symmetric(
      horizontal: 1.4 * PdfPageFormat.mm,
      vertical: 1.0 * PdfPageFormat.mm,
    ),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: 0.4),
    ),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          _clipName(item.name, preset.widthMm),
          maxLines: 1,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: bold,
            fontSize: nameSize,
          ),
        ),
        pw.SizedBox(height: 1),
        pw.SizedBox(
          height: barcodeHeight,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.ean13(),
            data: item.barcode,
            drawText: false,
          ),
        ),
        pw.Text(
          item.barcode,
          style: pw.TextStyle(font: regular, fontSize: codeSize),
        ),
        pw.SizedBox(height: 1),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'MRP ${AppFormatters.plain(item.mrp)}',
                maxLines: 1,
                style: pw.TextStyle(font: regular, fontSize: priceSize),
              ),
            ),
            pw.Text(
              'Rs.${AppFormatters.plain(item.sellingPrice)}',
              maxLines: 1,
              style: pw.TextStyle(font: bold, fontSize: priceSize),
            ),
          ],
        ),
      ],
    ),
  );
}

String _clipName(String value, double widthMm) {
  final text = value.trim();
  final maxChars = (widthMm * 0.55).round().clamp(12, 42);
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars - 3)}...';
}

Future<({pw.Font regular, pw.Font bold})> _labelFonts() async {
  try {
    return (
      regular: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    );
  } catch (_) {
    return (
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }
}
