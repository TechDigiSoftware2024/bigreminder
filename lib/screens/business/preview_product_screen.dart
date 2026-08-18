import 'package:flutter/material.dart';

import '../../models/business_models/add_product_model.dart';

class PreviewProductsScreen extends StatefulWidget {
  final List<ProductModel> products;
  final Future<void> Function() onUpload;

  const PreviewProductsScreen({
    super.key,
    required this.products,
    required this.onUpload,
  });

  @override
  State<PreviewProductsScreen> createState() => _PreviewProductsScreenState();
}

class _PreviewProductsScreenState extends State<PreviewProductsScreen> {
  bool _isUploading = false;

  Future<void> _handleUpload() async {
    if (_isUploading) return; // guard against double-tap

    setState(() => _isUploading = true);

    try {
      await widget.onUpload();
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final products = widget.products;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: const Text(
          "Preview Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17
          ),
        ),
      ),
      body: products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 90,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            Text(
              "No Products Found",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Import a CSV file to preview products.",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: products.length + 1,
        itemBuilder: (_, index) {
          // Header Card
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${products.length} Products",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            "Ready to import into your inventory",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = products[index - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "$index",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if ((product.barcode ?? "").isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  product.barcode!,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip(
                              Icons.inventory,
                              "Stock ${product.stock}",
                              Colors.orange,
                            ),
                            if (product.gst_percent != 0)
                              _buildChip(
                                Icons.receipt_long,
                                "GST ${product.gst_percent}%",
                                Colors.green,
                              ),

                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${product.price}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Selling Price",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: SizedBox(
            height: 45,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
              (_isUploading || products.isEmpty) ? null : _handleUpload,
              icon: _isUploading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.cloud_upload_rounded,
                color: Colors.white,
              ),
              label: Text(
                _isUploading
                    ? "Uploading..."
                    : "Upload ${products.length} Products",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildChip(
    IconData icon,
    String text,
    Color color,
    ) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8, vertical: 4,),
    decoration: BoxDecoration(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: color.withOpacity(.20),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}