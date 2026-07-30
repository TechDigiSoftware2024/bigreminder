import 'dart:io';

import 'package:bigreminder/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../models/business_models/add_product_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../services/business/business_csv_import_service.dart';
import '../../../services/business/product_import_service.dart';
import '../../../widgets/add_product.dart';
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

  void showImportResult(BuildContext context, ImportResult result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
                color: result.failed == 0 ? Colors.green : Colors.orange,
                size: 70,
              ),

              const SizedBox(height: 20),

              Text(
                result.failed == 0 ? "Import Successful" : "Import Completed",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 15),

              Text("${result.uploaded} products imported successfully."),

              if (result.failed > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "${result.failed} products failed.",
                    style: const TextStyle(color: Colors.red),
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
                      final uploadResult = await ProductImportService()
                          .uploadProducts(
                            products: result.products,
                            token: ref.read(tokenProvider),
                            onProgress: (current, total) {
                              debugPrint("$current / $total");
                            },
                          );

                      final token = ref.read(tokenProvider);
                      final businessId = ref.read(businessIdProvider);

                      await ref
                          .read(productProvider.notifier)
                          .loadProducts(token, businessId.toString());

                      if (context.mounted) {
                        Navigator.pop(context);

                        Future.delayed(const Duration(milliseconds: 300), () {
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
                        });
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Import product from CSV file",
            icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
            onPressed: _showImportDialog,
          ),
          const SizedBox(width: 10),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Product",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
            return product.name.toLowerCase().contains(_searchQuery);
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (_, index) {
                            final reverseIndex = filteredProducts.length - 1 - index;
                            final product = filteredProducts[reverseIndex];

                            return ProductCard(
                              product: product,
                              onEdit: () {
                                _showAddProductDialog(
                                  context,
                                  product: product,
                                );
                              },
                              onDelete: () async {
                                await ref
                                    .read(productProvider.notifier)
                                    .deleteProduct(
                                  token,
                                  product.id!,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
    final productGSTController = TextEditingController(
      text: product?.gst_percent.toString() ?? '',
    );
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
                              fontSize: 18,
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
                              fontWeight: FontWeight.w500,
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
                          TextFormField(
                            controller: productGSTController,
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration(
                              "Product GST (Optional)",
                              Icons.percent_outlined,
                              primary,
                            ),
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ProductSaveButton(
                              formKey: formKey,
                              product: product,
                              businessId: businessId,
                              token: token,
                              barcodeController: barcodeController,
                              nameController: nameController,
                              gstController: productGSTController,
                              priceController: priceController,
                              stockController: stockController,
                              ref: ref,
                              onSuccess: (savedProduct) {
                                if (!context.mounted) return;

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      product == null
                                          ? "Product added successfully"
                                          : "Product updated successfully",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
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
    final bool hasBarcode =
        product.barcode != null && product.barcode!.trim().isNotEmpty;
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: primary,
                        size: 18,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasBarcode ? product.barcode! : "No Barcode",
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
                const SizedBox(height: 4),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 4),
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
                        value: "₹${product.price}",
                        primary: primary,
                        gst:
                            (product.gst_percent != null &&
                                product.gst_percent! > 0)
                            ? product.gst_percent.toString()
                            : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lowStock
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
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
                              fontSize: 10,
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
  final String? gst;
  final Color primary;

  const _InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.primary,
    this.gst,
  });

  @override
  Widget build(BuildContext context) {
    final hasGst = gst != null && gst!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: primary),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),

                if (hasGst) ...[
                  const SizedBox(height: 2),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "+ ${gst!}% GST",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header icon in a soft circular container instead of a bare icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upload_file_rounded,
                size: 36,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Import Products",
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 18
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Upload a CSV file containing your products.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Required columns + sample, using a bordered surface (no shadow)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Required Columns",
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['name', 'price', 'stock']
                      .map(
                        (col) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            col,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 16),

                Divider(color: colorScheme.outlineVariant, height: 1),

                const SizedBox(height: 16),

                Text(
                  "Sample CSV",
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                      verticalInside: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.3),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(0.9),
                      3: FlexColumnWidth(0.9),
                      4: FlexColumnWidth(0.8),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                        ),
                        children: ['barcode', 'name', 'price', 'stock', 'gst%']
                            .map(
                              (col) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 8,
                                ),
                                child: Text(
                                  col,
                                  style: textTheme.labelMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      // Data row 1
                      TableRow(
                        children: ['890123', 'Coke', '20', '50', '18']
                            .map(
                              (val) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  val,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      // Data row 2
                      TableRow(
                        children: ['890124', 'Pepsi', '40', '25', '18']
                            .map(
                              (val) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  val,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // File picker button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: colorScheme.primary,
            ),
            onPressed: pickCsv,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text("Choose CSV File"),
          ),

          if (selectedFile != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedFile!.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => setState(() => selectedFile = null),
                    tooltip: 'Remove file',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.03,),
                disabledForegroundColor: colorScheme.onSurface.withOpacity(0.03,),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2))
                ),
              ),
              onPressed: selectedFile == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onFileSelected(selectedFile!);
                    },
              icon: Icon(Icons.upload_rounded, color: colorScheme.primaryContainer,),
              label: Text(
                "Continue",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
