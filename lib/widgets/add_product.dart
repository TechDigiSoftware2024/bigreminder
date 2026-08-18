import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business_models/add_product_model.dart';
import '../providers/business/business_provider.dart';

class ProductSaveButton extends StatefulWidget {
  const ProductSaveButton({
    super.key,
    required this.formKey,
    required this.product,
    required this.businessId,
    required this.token,
    required this.barcodeController,
    required this.nameController,
    required this.gstController,
    required this.priceController,
    required this.stockController,
    required this.ref,
    this.onSuccess,
  });

  final GlobalKey<FormState> formKey;
  final ProductModel? product;
  final int businessId;
  final String token;

  final TextEditingController barcodeController;
  final TextEditingController nameController;
  final TextEditingController gstController;
  final TextEditingController priceController;
  final TextEditingController stockController;

  final WidgetRef ref;

  final Function(ProductModel? product)? onSuccess;

  @override
  State<ProductSaveButton> createState() => _ProductSaveButtonState();
}

class _ProductSaveButtonState extends State<ProductSaveButton> {
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSaving
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          widget.product == null
              ? "Save Product"
              : "Update Product",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final productData = ProductModel(
        id: widget.product?.id,
        businessId: widget.businessId,
        barcode: widget.barcodeController.text.trim().isEmpty
            ? null
            : widget.barcodeController.text.trim(),
        name: widget.nameController.text.trim(),
        gst_percent: widget.gstController.text.trim().isEmpty
            ? null
            : int.tryParse(widget.gstController.text.trim()),
        price: double.tryParse(widget.priceController.text.trim()) ?? 0,
        stock: int.tryParse(widget.stockController.text.trim()) ?? 0,
      );

      if (widget.product == null) {
        await widget.ref
            .read(productProvider.notifier)
            .addProduct(widget.token, productData);
      } else {
        await widget.ref
            .read(productProvider.notifier)
            .updateProduct(
          widget.token,
          widget.product!.id!,
          productData,
        );
      }

      if (!mounted) return;

      widget.onSuccess?.call(productData);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}