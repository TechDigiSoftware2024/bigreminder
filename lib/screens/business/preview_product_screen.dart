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
    final primary = Theme.of(context).colorScheme.primary;
    final products = widget.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Products"),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: primary.withOpacity(.08),
            padding: const EdgeInsets.all(16),
            child: Text(
              "${products.length} Products Ready To Import",
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),

          Expanded(
            child: products.isEmpty
                ? const Center(
              child: Text(
                "No products to preview.",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final product = products[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text("${index + 1}"),
                  ),
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.barcode.isNotEmpty)
                        Text("Barcode : ${product.barcode}"),
                      Text("Stock : ${product.stock}"),
                    ],
                  ),
                  trailing: Text(
                    "₹${product.price}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withOpacity(0.5),
                  ),
                  icon: _isUploading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.cloud_upload, color: Colors.white),
                  label: Text(
                    _isUploading ? "Uploading..." : "Upload Products",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed:
                  (_isUploading || products.isEmpty) ? null : _handleUpload,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}