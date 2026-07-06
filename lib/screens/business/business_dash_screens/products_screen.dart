import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../models/business_models/add_product_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../services/business/business_csv_import_service.dart';
import '../../../services/business/product_import_service.dart';
import '../preview_product_screen.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    final token = ref.read(tokenProvider);
    final businessId = ref.read(businessIdProvider);

    Future.microtask(() {
      ref
          .read(productProvider.notifier)
          .loadProducts(token, businessId.toString());
    });

    _searchController.addListener(_onSearchChanged);
  }
  void showImportResult(
      BuildContext context,
      ImportResult result,
      ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                result.failed == 0
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color:
                result.failed == 0 ? Colors.green : Colors.orange,
                size: 70,
              ),

              const SizedBox(height: 20),

              Text(
                result.failed == 0
                    ? "Import Successful"
                    : "Import Completed",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                "${result.uploaded} products imported successfully.",
              ),

              if (result.failed > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "${result.failed} products failed.",
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
  void _showImportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return ImportCsvDialog(
          onFileSelected: (File file) async {
            final result = await CsvImportService().parseProducts(
              file: file,
              businessId: ref.read(businessIdProvider),
            );

            // Only bail out if there is literally nothing to upload.
            if (result.products.isEmpty) {
              if (context.mounted) {
                _showCsvErrorDialog(context, result.errors);
              }
              return;
            }

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviewProductsScreen(
                    products: result.products,
                    onUpload: () async {
                      final uploadResult = await ProductImportService().uploadProducts(
                        products: result.products,
                        token: ref.read(tokenProvider),
                        onProgress: (current, total) {
                          debugPrint("$current / $total");
                        },
                      );

                      final token = ref.read(tokenProvider);
                      final businessId = ref.read(businessIdProvider);

                      await ref.read(productProvider.notifier).loadProducts(
                        token,
                        businessId.toString(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);

                        Future.delayed(
                          const Duration(milliseconds: 300),
                              () {
                            if (context.mounted) {
                              showImportResult(context, uploadResult);

                              // Let them know some rows were skipped, if any.
                              if (result.errors.isNotEmpty) {
                                Future.delayed(
                                  const Duration(milliseconds: 400),
                                      () {
                                    if (context.mounted) {
                                      _showCsvErrorDialog(context, result.errors);
                                    }
                                  },
                                );
                              }
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showCsvErrorDialog(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Import Issues"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: errors.isEmpty
              ? const Text("No valid products were found in this CSV file.")
              : ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "• ${errors[i]}",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final token = ref.watch(tokenProvider);
    final businessId = ref.watch(businessIdProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Import CSV",
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
            onPressed: _showImportDialog,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),

      body: products.when(
        loading: () => Center(child: CircularProgressIndicator(color: primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          final filteredProducts = items.where((product) {
            if (_searchQuery.isEmpty) return true;
            return product.name.toLowerCase().contains(_searchQuery) ||
                product.barcode.toLowerCase().contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              _buildSearchBar(primary),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(primary)
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: () async {
                          await ref
                              .read(productProvider.notifier)
                              .loadProducts(token, businessId.toString());
                        },
                        child: filteredProducts.isEmpty
                            ? _buildNoResults()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (_, index) {
                                  return ProductCard(
                                    product: filteredProducts[index],
                                    onEdit: () {
                                      _showAddProductDialog(
                                        context,
                                        product: filteredProducts[index],
                                      );
                                    },
                                    onDelete: () async {
                                      await ref
                                          .read(productProvider.notifier)
                                          .deleteProduct(
                                            token,
                                            filteredProducts[index].id!,
                                          );
                                    },
                                  );
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
            });
          },
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Search products by name or barcode...",
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 64, color: primary),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Products Yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap the button below to add\nyour first product.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              "No Products Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try adjusting your search terms",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, {ProductModel? product}) {
    final formKey = GlobalKey<FormState>();

    final barcodeController = TextEditingController(
      text: product?.barcode ?? '',
    );

    final nameController = TextEditingController(text: product?.name ?? '');

    final priceController = TextEditingController(
      text: product != null ? product.price.toString() : '',
    );

    final stockController = TextEditingController(
      text: product != null ? product.stock.toString() : '',
    );

    final businessId = ref.read(businessIdProvider);
    final token = ref.read(tokenProvider);
    bool isSaving = false;
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            product == null
                                ? "Add New Product"
                                : "Update Product",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product == null
                                ? "Fill in the details to add a new product to your inventory"
                                : "Update the product details",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: barcodeController,
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration(
                              "Barcode (Optional)",
                              Icons.qr_code_scanner,
                              primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: nameController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Product name is required";
                              }
                              return null;
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration(
                              "Product Name *",
                              Icons.inventory_2,
                              primary,
                            ),
                            textCapitalization: TextCapitalization.words,
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Required";
                                    }
                                    if (double.tryParse(v) == null) {
                                      return "Invalid price";
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(color: Colors.black),
                                  decoration: _inputDecoration(
                                    "Price *",
                                    Icons.currency_rupee,
                                    primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Required";
                                    }
                                    if (int.tryParse(v) == null) {
                                      return "Invalid";
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(color: Colors.black),
                                  decoration: _inputDecoration(
                                    "Stock *",
                                    Icons.inventory,
                                    primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;

                                      setModalState(() => isSaving = true);

                                      try {
                                        final productData = ProductModel(
                                          id: product?.id,
                                          businessId: businessId,
                                          barcode: barcodeController.text
                                              .trim(),
                                          name: nameController.text.trim(),
                                          price: double.parse(
                                            priceController.text,
                                          ),
                                          stock: int.parse(
                                            stockController.text,
                                          ),
                                        );

                                        if (product == null) {
                                          await ref
                                              .read(productProvider.notifier)
                                              .addProduct(token, productData);
                                        } else {
                                          await ref
                                              .read(productProvider.notifier)
                                              .updateProduct(
                                                token,
                                                product.id!,
                                                productData,
                                              );
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                product == null
                                                    ? "Product added successfully"
                                                    : "Product updated successfully",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setModalState(() => isSaving = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: primary.withOpacity(
                                  0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      product == null
                                          ? "Save Product"
                                          : "Update Product",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color primary) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bool lowStock = product.stock <= 10;
    final bool hasBarcode = product.barcode.isNotEmpty;
    final bool isActive = product.stock > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle product tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasBarcode ? product.barcode : "No Barcode",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == "edit") {
                          onEdit();
                        } else if (value == "delete") {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: "edit",
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text("Edit"),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: "delete",
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.inventory_2_outlined,
                        title: "Stock",
                        value: "${product.stock}",
                        primary: primary,
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.currency_rupee,
                        title: "Price",
                        value: "₹${product.price.toStringAsFixed(2)}",
                        primary: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: lowStock
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            lowStock
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            size: 14,
                            color: lowStock ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lowStock ? "Low Stock" : "In Stock",
                            style: TextStyle(
                              color: lowStock ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: isActive ? primary : Colors.grey.shade300,
                      size: 28,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? "Active" : "Inactive",
                      style: TextStyle(
                        color: isActive ? primary : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color primary;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ImportCsvDialog extends StatefulWidget {
  final Function(File file) onFileSelected;

  const ImportCsvDialog({super.key, required this.onFileSelected});

  @override
  State<ImportCsvDialog> createState() => _ImportCsvDialogState();
}

class _ImportCsvDialogState extends State<ImportCsvDialog> {
  File? selectedFile;

  bool loading = false;

  Future<void> pickCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    setState(() {
      selectedFile = File(result.files.single.path!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.upload_file_rounded, size: 70, color: Colors.blue),

          const SizedBox(height: 15),

          const Text(
            "Import Products",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),

          const SizedBox(height: 10),

          Text(
            "Upload a CSV file containing your products.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 25),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Required Columns",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 10),

                Text("• barcode"),
                Text("• name"),
                Text("• price"),
                Text("• stock"),

                SizedBox(height: 20),

                Divider(),

                SizedBox(height: 10),

                Text(
                  "Sample CSV",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 10),

                Text(
                  "barcode,name,price,stock",
                  style: TextStyle(fontFamily: 'monospace'),
                ),

                Text(
                  "890123,Coke,20,50",
                  style: TextStyle(fontFamily: 'monospace'),
                ),

                Text(
                  "890124,Pepsi,40,25",
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: pickCsv,
              icon: const Icon(Icons.folder_open),
              label: const Text("Choose CSV File"),
            ),
          ),

          if (selectedFile != null) ...[
            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),

                  const SizedBox(width: 10),

                  Expanded(child: Text(selectedFile!.path.split('/').last)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: selectedFile == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onFileSelected(selectedFile!);
                    },
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text(
                "Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
