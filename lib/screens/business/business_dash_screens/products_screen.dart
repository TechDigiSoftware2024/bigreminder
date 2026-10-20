import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/business_models/add_product_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../services/business/business_csv_import_service.dart';
import '../../../services/business/product_import_service.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../utils/formatters.dart';
import '../barcode_scanner_dialog.dart';
import '../generate_barcode_screen.dart';
import '../preview_product_screen.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final barcodeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  final desktopFormKey = GlobalKey<FormState>();

  String searchQuery = "";
  bool saving = false;
  int? deletingId;
  ProductModel? editingProduct;

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
  }

  @override
  void dispose() {
    barcodeCtrl.dispose();
    nameCtrl.dispose();
    gstCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    barcodeCtrl.clear();
    nameCtrl.clear();
    gstCtrl.clear();
    priceCtrl.clear();
    stockCtrl.clear();
    editingProduct = null;
  }

  void _fillForm(ProductModel product) {
    editingProduct = product;
    barcodeCtrl.text = product.barcode ?? "";
    nameCtrl.text = product.name;
    gstCtrl.text = product.gst_percent?.toString() ?? "";
    priceCtrl.text = product.price.toString();
    stockCtrl.text = product.stock.toString();
  }

  Future<void> _refreshProducts({bool silent = true}) async {
    final token = ref.read(tokenProvider);
    final businessId = ref.read(businessIdProvider);
    await ref.read(productProvider.notifier).loadProducts(
          token,
          businessId.toString(),
          keepPrevious: silent,
        );
  }

  Future<bool> _submit({
    required GlobalKey<FormState> key,
    VoidCallback? onLoadingChanged,
  }) async {
    if (saving) return false;
    if (!(key.currentState?.validate() ?? false)) return false;

    setState(() => saving = true);
    onLoadingChanged?.call();

    try {
      final token = ref.read(tokenProvider);
      final businessId = ref.read(businessIdProvider);

      final productData = ProductModel(
        id: editingProduct?.id,
        businessId: businessId,
        barcode: barcodeCtrl.text.trim().isEmpty
            ? null
            : barcodeCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        gst_percent: gstCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(gstCtrl.text.trim()),
        price: double.tryParse(priceCtrl.text.trim()) ?? 0,
        stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
      );

      if (editingProduct == null) {
        await ref.read(productProvider.notifier).addProduct(token, productData);
      } else {
        await ref.read(productProvider.notifier).updateProduct(
              token,
              editingProduct!.id!,
              productData,
            );
      }

      if (!mounted) return false;

      final wasEdit = editingProduct != null;
      _resetForm();
      setState(() {});

      CustomDialog.showSuccessSnack(
        context,
        wasEdit
            ? "Product updated successfully"
            : "Product added successfully",
      );

      return true;
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnack(
          context,
          e.toString().replaceFirst("Exception: ", ""),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => saving = false);
        onLoadingChanged?.call();
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await _showDeleteConfirmation(product.name);
    if (confirmed != true) return;

    final token = ref.read(tokenProvider);

    setState(() => deletingId = product.id);

    try {
      await ref.read(productProvider.notifier).deleteProduct(
            token,
            product.id!,
          );

      if (!mounted) return;

      CustomDialog.showSuccessSnack(
        context,
        "Product deleted successfully",
      );
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) {
        setState(() => deletingId = null);
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(String name) {
    final primary = Theme.of(context).colorScheme.primary;
    final dialogWidth = MediaQuery.sizeOf(context).width >= 900
        ? 420.0
        : MediaQuery.sizeOf(context).width - 32;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: Icon(Icons.help, color: primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Delete Product?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete "$name"?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          child: const Text("Delete"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openProductForm({ProductModel? product, String? scannedBarcode}) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    // Desktop: fill the side panel for both add and edit.
    if (isDesktop) {
      _resetForm();
      if (product != null) {
        _fillForm(product);
      } else if (scannedBarcode != null) {
        barcodeCtrl.text = scannedBarcode;
      }
      setState(() => saving = false);
      return;
    }

    // Mobile: dialog for add / edit.
    _resetForm();
    if (product != null) {
      _fillForm(product);
    } else if (scannedBarcode != null) {
      barcodeCtrl.text = scannedBarcode;
    }
    setState(() => saving = false);

    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: ProductAddForm(
                      formKey: dialogFormKey,
                      barcodeController: barcodeCtrl,
                      nameController: nameCtrl,
                      gstController: gstCtrl,
                      priceController: priceCtrl,
                      stockController: stockCtrl,
                      loading: saving,
                      isEditing: editingProduct != null,
                      onScan: () => _scanAndFill(formAlreadyOpen: true),
                      onGenerate: () {
                        Navigator.of(dialogContext).pop();
                        _openGenerate();
                      },
                      onSubmit: () async {
                        final success = await _submit(
                          key: dialogFormKey,
                          onLoadingChanged: () => setDialogState(() {}),
                        );
                        if (!dialogContext.mounted) return;
                        if (success) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(_resetForm);
      }
    });
  }

  Future<void> _showAddOptions() async {
    final cs = Theme.of(context).colorScheme;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the details yourself, or scan a barcode with a USB scanner.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  _AddOptionButton(
                    icon: Icons.edit_outlined,
                    title: 'Enter manually',
                    subtitle: 'Type the product name, price, and stock',
                    color: cs.primary,
                    onTap: () => Navigator.pop(dialogContext, 'manual'),
                  ),
                  const SizedBox(height: 8),
                  _AddOptionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Scan barcode',
                    subtitle: 'Scan first, then fill in the other details',
                    color: cs.primary,
                    onTap: () => Navigator.pop(dialogContext, 'scan'),
                  ),
                  const SizedBox(height: 8),
                  _AddOptionButton(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Generate barcodes',
                    subtitle: 'Create labels with MRP and selling price',
                    color: const Color(0xFF2F6B4A),
                    onTap: () => Navigator.pop(dialogContext, 'generate'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'manual') {
      _openProductForm();
    } else if (choice == 'scan') {
      await _scanAndFill();
    } else if (choice == 'generate') {
      _openGenerate();
    }
  }

  Future<void> _scanAndFill({bool formAlreadyOpen = false}) async {
    final code = await showWindowsBarcodeScanner(context);
    if (!mounted || code == null) return;

    final products = ref.read(productProvider).asData?.value ?? <ProductModel>[];
    ProductModel? existing;
    for (final product in products) {
      if ((product.barcode ?? '').trim() == code) {
        existing = product;
        break;
      }
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (formAlreadyOpen) {
      barcodeCtrl.text = code;
      if (existing != null) {
        CustomDialog.showErrorSnack(
          context,
          'This barcode is already used by ${existing.name}.',
        );
      } else {
        CustomDialog.showSuccessSnack(
          context,
          'Barcode scanned. Add the other details.',
        );
      }
      return;
    }

    if (existing != null) {
      _openProductForm(product: existing);
      if (!mounted) return;
      CustomDialog.showSuccessSnack(
        context,
        'This barcode is already in inventory. You can update it.',
      );
      return;
    }

    if (isDesktop) {
      barcodeCtrl.text = code;
      setState(() {});
      CustomDialog.showSuccessSnack(
        context,
        'Barcode scanned. Add the other details.',
      );
      return;
    }

    _openProductForm(scannedBarcode: code);
  }

  void _openGenerate({ProductModel? seed}) {
    final products = ref.read(productProvider).asData?.value ?? <ProductModel>[];
    final taken = <String>{};
    final missing = <ProductModel>[];
    for (final product in products) {
      final code = (product.barcode ?? '').trim();
      if (code.isEmpty) {
        missing.add(product);
      } else {
        taken.add(code);
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenerateBarcodeScreen(
          productsWithoutBarcode: missing,
          takenBarcodes: taken,
          seed: seed,
        ),
      ),
    );
  }

  // ─── CSV (same backend flow) ──────────────────────────────────────────────

  void showImportResult(BuildContext context, ImportResult result) {
    final cs = Theme.of(context).colorScheme;
    final width = CustomDialog.dialogWidth(
      context,
      desktop: CustomDialog.formWidth,
    );

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        final ok = result.failed == 0;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: (ok ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      ok
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: ok ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    ok ? 'Import Successful' : 'Import Completed',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.uploaded} product${result.uploaded == 1 ? '' : 's'} imported successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (result.failed > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${result.failed} product${result.failed == 1 ? '' : 's'} failed.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop();
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxWidth: CustomDialog.dialogWidth(
          context,
          desktop: CustomDialog.formWideWidth,
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return ImportCsvDialog(
          onFileSelected: (File file) async {
            final result = await CsvImportService().parseProducts(
              file: file,
              businessId: ref.read(businessIdProvider),
            );

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
                    onUpload: (productsToUpload) async {
                      final uploadResult =
                          await ProductImportService().uploadProducts(
                        products: productsToUpload,
                        token: ref.read(tokenProvider),
                        onProgress: (current, total) {
                          debugPrint("$current / $total");
                        },
                      );

                      await _refreshProducts(silent: true);

                      if (context.mounted) {
                        Navigator.pop(context);

                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            showImportResult(context, uploadResult);

                            if (result.errors.isNotEmpty) {
                              Future.delayed(
                                const Duration(milliseconds: 400),
                                () {
                                  if (context.mounted) {
                                    _showCsvErrorDialog(
                                      context,
                                      result.errors,
                                    );
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
    final cs = Theme.of(context).colorScheme;
    final width = CustomDialog.dialogWidth(
      context,
      desktop: CustomDialog.formWidth,
    );

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Import Issues',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errors.isEmpty
                        ? 'No valid products were found in this CSV file.'
                        : '${errors.length} issue${errors.length == 1 ? '' : 's'} found while reading your CSV.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: errors.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 12,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (_, i) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errors[i],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop();
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final cs = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          "Products",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Scan barcode",
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            onPressed: () => _scanAndFill(),
          ),
          IconButton(
            tooltip: "Generate barcodes",
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
            onPressed: _openGenerate,
          ),
          IconButton(
            tooltip: "Import products from CSV",
            icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
            onPressed: _showImportDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: cs.primary,
              onPressed: _showAddOptions,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: isDesktop
          ? _buildDesktopLayout(productsAsync, cs)
          : _buildMobileLayout(productsAsync, cs),
    );
  }

  Widget _buildDesktopLayout(
    AsyncValue<List<ProductModel>> productsAsync,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: ProductListPanel(
              productsAsync: productsAsync,
              searchController: searchCtrl,
              searchQuery: searchQuery,
              deletingId: deletingId,
              onSearchChanged: (value) {
                setState(() => searchQuery = value.trim().toLowerCase());
              },
              onClearSearch: () {
                searchCtrl.clear();
                setState(() => searchQuery = "");
              },
              onRefresh: () => _refreshProducts(silent: true),
              onEdit: (product) => _openProductForm(product: product),
              onDelete: _deleteProduct,
              onGenerateBarcode: (product) => _openGenerate(seed: product),
              isDesktop: true,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: ProductAddForm(
                formKey: desktopFormKey,
                barcodeController: barcodeCtrl,
                nameController: nameCtrl,
                gstController: gstCtrl,
                priceController: priceCtrl,
                stockController: stockCtrl,
                loading: saving,
                isEditing: editingProduct != null,
                onClear: () => setState(_resetForm),
                onScan: () => _scanAndFill(),
                onGenerate: _openGenerate,
                onSubmit: () async {
                  await _submit(key: desktopFormKey);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    AsyncValue<List<ProductModel>> productsAsync,
    ColorScheme cs,
  ) {
    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () => _refreshProducts(silent: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ProductListPanel(
              productsAsync: productsAsync,
              searchController: searchCtrl,
              searchQuery: searchQuery,
              deletingId: deletingId,
              onSearchChanged: (value) {
                setState(() => searchQuery = value.trim().toLowerCase());
              },
              onClearSearch: () {
                searchCtrl.clear();
                setState(() => searchQuery = "");
              },
              onRefresh: () => _refreshProducts(silent: true),
              onEdit: (product) => _openProductForm(product: product),
              onDelete: _deleteProduct,
              onGenerateBarcode: (product) => _openGenerate(seed: product),
              isDesktop: false,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ADD / EDIT FORM
// ============================================================================

class _AddOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffFAFBFD),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductAddForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController barcodeController;
  final TextEditingController nameController;
  final TextEditingController gstController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final bool loading;
  final bool isEditing;
  final VoidCallback onSubmit;
  final VoidCallback? onClear;
  final VoidCallback? onScan;
  final VoidCallback? onGenerate;

  const ProductAddForm({
    super.key,
    required this.formKey,
    required this.barcodeController,
    required this.nameController,
    required this.gstController,
    required this.priceController,
    required this.stockController,
    required this.loading,
    required this.isEditing,
    required this.onSubmit,
    this.onClear,
    this.onScan,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? "Update Product" : "New Product",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing
                              ? "Edit inventory details"
                              : "Scan a barcode or enter the details",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing && onClear != null)
                    IconButton(
                      onPressed: onClear,
                      tooltip: "Clear form",
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                ],
              ),
            ),
            if (onScan != null || (onGenerate != null && !isEditing)) ...[
              const SizedBox(height: 14),
              if (onScan != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Scan barcode'),
                  ),
                ),
              if (onGenerate != null && !isEditing) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onGenerate,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Generate barcodes'),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 18),
            _ProductInputField(
              controller: barcodeController,
              label: "Barcode",
              hint: "Optional, or scan one",
              icon: Icons.qr_code_scanner,
              suffixIcon: onScan == null
                  ? null
                  : IconButton(
                      tooltip: 'Scan barcode',
                      onPressed: loading ? null : onScan,
                      icon: Icon(Icons.qr_code_scanner_rounded, color: cs.primary),
                    ),
            ),
            const SizedBox(height: 10),
            _ProductInputField(
              controller: nameController,
              label: "Product Name",
              hint: "e.g. Coke / Soap",
              icon: Icons.inventory_2_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Product name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _ProductInputField(
              controller: gstController,
              label: "GST %",
              hint: "Optional",
              icon: Icons.percent_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ProductInputField(
                    controller: priceController,
                    label: "Price",
                    hint: "0.00",
                    icon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (double.tryParse(v.trim()) == null) {
                        return "Invalid";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProductInputField(
                    controller: stockController,
                    label: "Stock",
                    hint: "0",
                    icon: Icons.inventory_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (int.tryParse(v.trim()) == null) return "Invalid";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.primary.withOpacity(.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? "Update Product" : "Add Product",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _ProductInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: cs.primary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xffFAFBFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.onSurface.withOpacity(.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LIST PANEL
// ============================================================================

class ProductListPanel extends StatelessWidget {
  final AsyncValue<List<ProductModel>> productsAsync;
  final TextEditingController searchController;
  final String searchQuery;
  final int? deletingId;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;
  final ValueChanged<ProductModel>? onGenerateBarcode;
  final bool isDesktop;

  const ProductListPanel({
    super.key,
    required this.productsAsync,
    required this.searchController,
    required this.searchQuery,
    required this.deletingId,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    this.onGenerateBarcode,
    required this.isDesktop,
  });

  List<ProductModel> _filtered(List<ProductModel> items) {
    if (searchQuery.isEmpty) return items.reversed.toList();

    return items.reversed.where((product) {
      final name = product.name.toLowerCase();
      final barcode = (product.barcode ?? "").toLowerCase();
      return name.contains(searchQuery) || barcode.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = productsAsync.asData?.value ?? <ProductModel>[];
    final filtered = _filtered(items);
    final isInitialLoading =
        productsAsync.isLoading && productsAsync.asData == null;
    final isRefreshing =
        productsAsync.isLoading && productsAsync.asData != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "All Products",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isInitialLoading
                          ? "Loading products..."
                          : "${items.length} product records",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (isDesktop)
                IconButton(
                  onPressed: isInitialLoading ? null : onRefresh,
                  icon: Icon(Icons.refresh_rounded, color: cs.primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search by name or barcode...",
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xffF7F8FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (productsAsync.hasError && items.isEmpty)
            _ErrorState(
              message: productsAsync.error.toString(),
              onRetry: onRefresh,
            )
          else if (isDesktop)
            Expanded(child: _buildList(context, filtered, isInitialLoading))
          else
            _buildMobileList(context, filtered, isInitialLoading),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ProductModel> filtered,
    bool isInitialLoading,
  ) {
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return _EmptyProducts(searching: searchQuery.isNotEmpty);
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = filtered[index];
        return ProductCard(
          product: product,
          deleting: deletingId == product.id,
          onEdit: () => onEdit(product),
          onDelete: () => onDelete(product),
          onGenerateBarcode: onGenerateBarcode == null
              ? null
              : () => onGenerateBarcode!(product),
        );
      },
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<ProductModel> filtered,
    bool isInitialLoading,
  ) {
    if (isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filtered.isEmpty) {
      return _EmptyProducts(searching: searchQuery.isNotEmpty);
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = filtered[index];
        return ProductCard(
          product: product,
          deleting: deletingId == product.id,
          onEdit: () => onEdit(product),
          onDelete: () => onDelete(product),
          onGenerateBarcode: onGenerateBarcode == null
              ? null
              : () => onGenerateBarcode!(product),
        );
      },
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final bool searching;

  const _EmptyProducts({required this.searching});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 32,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searching ? "No products found" : "No products yet",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              searching
                  ? "Try a different name or barcode"
                  : "Add your first product to get started",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            message.replaceFirst("Exception: ", ""),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRODUCT CARD
// ============================================================================

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onGenerateBarcode;
  final bool deleting;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onGenerateBarcode,
    this.deleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowStock = product.stock <= 10;
    final hasBarcode =
        product.barcode != null && product.barcode!.trim().isNotEmpty;
    final priceLabel = AppFormatters.currency(product.price);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: cs.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        hasBarcode ? product.barcode! : "No barcode",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lowStock
                            ? Colors.red.withOpacity(.08)
                            : Colors.green.withOpacity(.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lowStock ? "LOW" : "IN STOCK",
                        style: TextStyle(
                          color: lowStock ? Colors.red : Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (product.gst_percent != null &&
                        product.gst_percent! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${product.gst_percent}% GST",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Stock ${product.stock}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF1B8A3E),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasBarcode && onGenerateBarcode != null) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: deleting ? null : onGenerateBarcode,
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F6B4A).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 16,
                            color: Color(0xFF2F6B4A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: deleting ? null : onEdit,
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: deleting ? null : onDelete,
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: deleting
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.red.shade400,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CSV IMPORT DIALOG (unchanged backend flow)
// ============================================================================

class ImportCsvDialog extends StatefulWidget {
  final Function(File file) onFileSelected;

  const ImportCsvDialog({super.key, required this.onFileSelected});

  @override
  State<ImportCsvDialog> createState() => _ImportCsvDialogState();
}

class _ImportCsvDialogState extends State<ImportCsvDialog> {
  File? selectedFile;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                fontSize: 18,
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
                  disabledBackgroundColor:
                      colorScheme.onSurface.withOpacity(0.03),
                  disabledForegroundColor:
                      colorScheme.onSurface.withOpacity(0.03),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                ),
                onPressed: selectedFile == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onFileSelected(selectedFile!);
                      },
                icon: Icon(
                  Icons.upload_rounded,
                  color: selectedFile != null
                      ? Colors.white
                      : colorScheme.primaryContainer,
                ),
                label: Text(
                  "Continue",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selectedFile != null
                        ? Colors.white
                        : colorScheme.primaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
