import 'package:bigreminder/screens/business/receipt_preview_screen.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/business_models/add_product_model.dart';
import '../../models/business_models/create_item_model.dart';
import '../../models/business_models/create_purchase_model.dart';
import '../../models/business_models/customer_list_model.dart';
import '../../providers/business/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/business/business_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_dialog.dart';

class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() =>
      _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  final paidCtrl = TextEditingController();

  final itemNameCtrl = TextEditingController();
  final itemBarCodeCtrl = TextEditingController();
  final productGSTCtrl = TextEditingController();
  final itemPriceCtrl = TextEditingController();
  final itemQtyCtrl = TextEditingController();

  /// This field now doubles as both the search box AND the
  /// new-customer name field.
  final searchCtrl = TextEditingController();

  final _customerFormKey = GlobalKey<FormState>();
  /// Inline "create customer" form controllers (phone + gender only —
  /// name comes from searchCtrl directly).
  final _newCustomerPhoneCtrl = TextEditingController();

  List<CustomerResponseModel> customers = [];

  List<Map<String, dynamic>> items = [];

  /// Product search & selection state. The actual product list itself
  /// comes from `productProvider` (watched in build) — not stored here.
  String itemSearchQuery = "";
  int? selectedProductId;

  bool isLoading = true;
  bool isCreating = false;

  /// Gender for the inline create-customer form (default: male)
  String _newCustomerGender = "male";

  CustomerResponseModel? selectedCustomer;

  int businessId = 0;

  int? selectedCustomerId;

  String searchQuery = "";

  double totalAmount = 0;
  double pendingAmount = 0;
  double subtotalAmount = 0;
  double totalGstAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();

    final token = ref.read(tokenProvider);
    final productBusinessId = ref.read(businessIdProvider);

    Future.microtask(() {
      ref
          .read(productProvider.notifier)
          .loadProducts(token, productBusinessId.toString());
    });
  }

  @override
  void dispose() {
    paidCtrl.dispose();
    itemNameCtrl.dispose();
    itemBarCodeCtrl.dispose();
    itemPriceCtrl.dispose();
    itemQtyCtrl.dispose();
    searchCtrl.dispose();
    _newCustomerPhoneCtrl.dispose();
    super.dispose();
  }
  bool get showCreateCustomerForm {
    final query = searchQuery.trim();

    if (selectedCustomer == null && query.isNotEmpty) {
      final filteredCustomers = customers.where((customer) {
        return customer.name
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();

      return filteredCustomers.isEmpty;
    }

    return false;
  }

  Future<void> _createBill(BuildContext context) async {
    final navigator = Navigator.of(context);

    // ─────────────────────────────────────
    // CUSTOMER VALIDATION
    // ─────────────────────────────────────
    if (selectedCustomerId == null) {
      final typedName = searchCtrl.text.trim();

      if (typedName.isEmpty) {
        CustomDialog.showErrorSnack(
          context,
          "Select or enter a customer",
        );
        return;
      }

      // ─────────────────────────────────
      // NEW CUSTOMER
      // ─────────────────────────────────
      if (showCreateCustomerForm) {
        final phone = _newCustomerPhoneCtrl.text.trim();

        if (phone.isEmpty) {
          CustomDialog.showErrorSnack(
            context,
            "Enter phone number for new customer",
          );
          return;
        }

        setState(() {
          isCreating = true;
        });

        try {
          final newCustomer = await _createCustomer(
            name: typedName,
            phone: phone,
          );

          if (!mounted) return;

          setState(() {
            selectedCustomer = newCustomer;
            selectedCustomerId = newCustomer.id;
          });
        } catch (e) {
          if (!mounted) return;

          setState(() {
            isCreating = false;
          });

          CustomDialog.showErrorSnack(
            context,
            "Failed to create customer: $e",
          );

          return;
        }
      } else {
        CustomDialog.showErrorSnack(
          context,
          "Select customer",
        );
        return;
      }
    }

    // ─────────────────────────────────────
    // ITEM VALIDATION
    // ─────────────────────────────────────
    if (items.isEmpty) {
      CustomDialog.showErrorSnack(
        context,
        "Add items first",
      );

      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }

      return;
    }

    // ─────────────────────────────────────
    // START CREATION
    // ─────────────────────────────────────
    if (!isCreating) {
      setState(() {
        isCreating = true;
      });
    }

    try {
      // ─────────────────────────────────────
      // PURCHASE ITEMS
      // ─────────────────────────────────────
      final purchaseItems = items.map((e) {
        return PurchaseItemModel(
          productId: e["productId"] ?? 0,
          barcode: e["barcode"] ?? "",
          name: e["name"],
          price: e["price"],
          quantity: e["quantity"],
          gstPercent: e["gst_percent"],
        );
      }).toList();

      // ─────────────────────────────────────
      // PURCHASE MODEL
      // ─────────────────────────────────────
      final model = CreatePurchaseModel(
        customerId: selectedCustomerId!,
        businessId: businessId,
        items: purchaseItems,
        totalAmount: totalAmount,
        paid: double.tryParse(paidCtrl.text) ?? 0,
        pending: pendingAmount,
        date: DateTime.now()
            .toIso8601String()
            .split("T")
            .first,
      );

      // ─────────────────────────────────────
      // BUSINESS INFORMATION
      // ─────────────────────────────────────
      final businessName = ref.read(
        businessNameProvider,
      );

      final businessPhone = ref.read(
        businessPhoneProvider,
      );

      final businessAddress = ref.read(
        businessAddressProvider,
      );

      debugPrint(model.toJson().toString());
      debugPrint(businessName);
      debugPrint(businessAddress);
      debugPrint(businessPhone);

      // ─────────────────────────────────────
      // CREATE PURCHASE
      // ─────────────────────────────────────
      final createdBill = await ref
          .read(businessControllerProvider.notifier)
          .createPurchase(
        model: model,
      );

      // ─────────────────────────────────────
      // SUCCESS
      // ─────────────────────────────────────
      if (mounted) {
        CustomDialog.showSuccessSnack(
          context,
          "Purchase added successfully",
        );
      }

      // ─────────────────────────────────────
      // RECEIPT
      // ─────────────────────────────────────
      if (navigator.mounted) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => ReceiptPreviewScreen(
              bill: createdBill,
              businessName: businessName,
              businessPhone: businessPhone,
              businessAddress: businessAddress,
              customerName: selectedCustomer?.name,
              isThermal: true,
            ),
          ),
        );
      }

      // Reset form after leaving receipt so next bill starts clean.
      if (mounted) {
        _resetBillForm();
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnack(
          context,
          e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }
  Future<void> _fetchCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";

      final businessIdFromPrefs = prefs.getInt("businessId") ?? 0;

      final data = await BusinessService().fetchCustomers(
        token: token,
        businessId: businessIdFromPrefs,
      );

      if (!mounted) return;

      setState(() {
        businessId = businessIdFromPrefs;

        customers = data;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      CustomDialog.showErrorSnack(context, e.toString());
    }
  }
  void calculateAmounts(BuildContext context) {
    subtotalAmount = items.fold<double>(
      0,
          (sum, e) => sum + (e["line_subtotal"] as double),
    );

    totalGstAmount = items.fold<double>(
      0,
          (sum, e) => sum + (e["gst_amount"] as double),
    );

    totalAmount = items.fold<double>(
      0,
          (sum, e) => sum + (e["line_total"] as double),
    );

    final paid = double.tryParse(paidCtrl.text) ?? 0;

    // Allow tiny floating-point precision differences.
    if (paid - totalAmount > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paid amount can't exceed total amount"),
          backgroundColor: Colors.red,
        ),
      );

      paidCtrl.clear();
      pendingAmount = totalAmount;
      return;
    }

    pendingAmount = totalAmount - paid;

    // Avoid values like 0.0000000001
    if (pendingAmount.abs() < 0.01) {
      pendingAmount = 0;
    }
  }
  /// Reads the current product list from the provider safely,
  /// regardless of loading/error state.
  List<ProductModel> _currentProducts() {
    return ref
        .read(productProvider)
        .maybeWhen(data: (value) => value, orElse: () => <ProductModel>[]);
  }

  void addItem() {
    if (itemNameCtrl.text.trim().isEmpty) {
      CustomDialog.showErrorSnack(context, "Enter item name");
      return;
    }

    final price = double.tryParse(itemPriceCtrl.text.trim()) ?? 0;
    final qty = int.tryParse(itemQtyCtrl.text.trim()) ?? 1;

    if (price <= 0) {
      CustomDialog.showErrorSnack(context, "Enter a valid price");
      return;
    }

    if (qty <= 0) {
      CustomDialog.showErrorSnack(context, "Enter a valid quantity");
      return;
    }

    final products = _currentProducts();

    double? gstPercent = 0;

    // Product selected from catalog
    if (selectedProductId != null) {
      final product = products.firstWhere((p) => p.id == selectedProductId);

      if (qty > product.stock) {
        CustomDialog.showErrorSnack(context, "Only ${product.stock} in stock");
        return;
      }

      gstPercent = (product.gst_percent?.toDouble() ?? 0);
    }
    // Manual Item
    else {
      gstPercent = double.tryParse(productGSTCtrl.text.trim()) ?? 0;
    }

    final lineSubtotal = price * qty;
    final gstAmount = lineSubtotal * gstPercent! / 100;
    final lineTotal = lineSubtotal + gstAmount;

    setState(() {
      items.add({
        "productId": selectedProductId ?? 0,
        "name": itemNameCtrl.text.trim(),
        "price": price,
        "quantity": qty,
        "barcode": itemBarCodeCtrl.text.trim(),
        "gst_percent": gstPercent,
        "gst_amount": gstAmount,
        "line_subtotal": lineSubtotal,
        "line_total": lineTotal,
      });

      calculateAmounts(context);

      itemNameCtrl.clear();
      itemPriceCtrl.clear();
      itemQtyCtrl.text = "1";
      itemBarCodeCtrl.clear();
      productGSTCtrl.clear();

      itemSearchQuery = "";
      selectedProductId = null;
    });
  }
  // void addItem() {
  //   if (itemNameCtrl.text
  //       .trim()
  //       .isEmpty) {
  //     return;
  //   }
  //
  //   final price = double.tryParse(itemPriceCtrl.text) ?? 0;
  //   final qty = int.tryParse(itemQtyCtrl.text) ?? 1;
  //
  //   if (qty <= 0) {
  //     CustomDialog.showErrorSnack(context, "Enter a valid quantity");
  //     return;
  //   }
  //
  //   if (selectedProductId != null) {
  //     final products = _currentProducts();
  //     final matched = products.where((p) => p.id == selectedProductId).toList();
  //     if (matched.isNotEmpty && qty > matched.first.stock) {
  //       CustomDialog.showErrorSnack(
  //         context,
  //         "Only ${matched.first.stock} in stock",
  //       );
  //       return;
  //     }
  //   }
  //
  //   final products = _currentProducts();
  //   final product = products.firstWhere(
  //         (p) => p.id == selectedProductId,
  //   );
  //
  //   final gstPercent = product.gst_percent ?? 0;
  //
  //   final lineSubtotal = price * qty;
  //   final gstAmount = lineSubtotal * gstPercent / 100;
  //   final lineTotal = lineSubtotal + gstAmount;
  //
  //   setState(() {
  //     items.add({
  //       "productId": selectedProductId,
  //       "name": itemNameCtrl.text.trim(),
  //       "price": price,
  //       "quantity": qty,
  //
  //       "gst_percent": gstPercent,
  //       "gst_amount": gstAmount,
  //       "line_subtotal": lineSubtotal,
  //       "line_total": lineTotal,
  //     });
  //
  //     calculateAmounts(context);
  //
  //     itemNameCtrl.clear();
  //     itemPriceCtrl.clear();
  //     itemQtyCtrl.text = "1";
  //     itemBarCodeCtrl.clear();
  //     itemSearchQuery = "";
  //     selectedProductId = null;
  //
  //   });
  //
  // }

  void _clearCustomerSelection() {
    setState(() {
      selectedCustomer = null;
      selectedCustomerId = null;
      searchQuery = "";
      searchCtrl.clear();
      _newCustomerPhoneCtrl.clear();
      _newCustomerGender = "male";
    });
  }

  /// Clears customer, cart, paid amount, and item-entry fields after a
  /// successful bill (called when user returns from the receipt screen).
  void _resetBillForm() {
    setState(() {
      selectedCustomer = null;
      selectedCustomerId = null;
      searchQuery = "";
      searchCtrl.clear();
      _newCustomerPhoneCtrl.clear();
      _newCustomerGender = "male";

      items = [];
      totalAmount = 0;
      pendingAmount = 0;
      subtotalAmount = 0;
      totalGstAmount = 0;
      paidCtrl.clear();

      itemNameCtrl.clear();
      itemPriceCtrl.clear();
      itemQtyCtrl.text = "1";
      itemBarCodeCtrl.clear();
      productGSTCtrl.clear();
      itemSearchQuery = "";
      selectedProductId = null;
    });
  }

  /// Creates a new customer via the existing API and returns it.
  /// Throws on failure — caller decides how to handle/report the error.
  Future<CustomerResponseModel> _createCustomer({
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    await BusinessService().addCustomer(
      name: name,
      phone: phone,
      token: token,
      businessId: businessId,
      email: '',
      gender: _newCustomerGender,
      fcmToken: '',
      pendingAmount: pendingAmount.toString(),
    );

    await _fetchCustomers();

    final matches = customers.where((c) => c.phone == phone).toList();
    return matches.isNotEmpty ? matches.last : customers.last;
  }

  @override
  Widget build(BuildContext context) {
    // Keep in sync with MaterialApp theme (appType → themeProvider).
    ref.watch(themeProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final productsAsync = ref.watch(productProvider);
    final products = productsAsync.asData?.value ?? <ProductModel>[];

    final filteredCustomers = customers.where((customer) {
      final q = searchQuery.toLowerCase();
      return customer.name.toLowerCase().contains(q);
    }).toList();

    final showCreateCustomerForm = selectedCustomer == null &&
        searchQuery.trim().isNotEmpty &&
        filteredCustomers.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Bill',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: cs.onPrimary,
              ),
            ),
            Text(
              'Customer → Items → Payment',
              style: TextStyle(
                fontSize: 11,
                color: cs.onPrimary.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _buildBillContent(
                        context,
                        theme,
                        products,
                        productsAsync,
                        filteredCustomers,
                        showCreateCustomerForm,
                      ),
                    ),
                    _buildDesktopRightPanel(context, theme),
                  ],
                )
              : _buildBillContent(
                  context,
                  theme,
                  products,
                  productsAsync,
                  filteredCustomers,
                  showCreateCustomerForm,
                ),
      bottomNavigationBar: isDesktop ? null : _buildBillSummary(context, theme),
    );
  }

  // ─── Shared section chrome ────────────────────────────────────────────────

  Color _softPrimary(ThemeData theme) =>
      theme.colorScheme.primary.withValues(alpha: 0.12);

  Color _muted(ThemeData theme) =>
      theme.colorScheme.onSurface.withValues(alpha: 0.55);

  Color _line(ThemeData theme) =>
      theme.colorScheme.onSurface.withValues(alpha: 0.10);

  Widget _sectionCard({
    required ThemeData theme,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line(theme)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required ThemeData theme,
    required int step,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _softPrimary(theme),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP $step',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _muted(theme),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _moneyRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: _muted(theme),
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Desktop summary panel ────────────────────────────────────────────────

  Widget _buildDesktopRightPanel(BuildContext context, ThemeData theme) {
    final cs = theme.colorScheme;
    final paid = double.tryParse(paidCtrl.text) ?? 0;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: _line(theme))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                items.isEmpty
                    ? 'Add items to see totals'
                    : '${items.length} item${items.length == 1 ? '' : 's'} on this bill',
                style: TextStyle(fontSize: 12, color: _muted(theme)),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL DUE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: cs.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.currency(totalAmount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                theme: theme,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    _moneyRow(
                      theme,
                      'Subtotal',
                      AppFormatters.currency(subtotalAmount),
                    ),
                    _moneyRow(
                      theme,
                      'GST',
                      AppFormatters.currency(totalGstAmount),
                      valueColor: AppColors.credit,
                    ),
                    Divider(height: 16, color: _line(theme)),
                    _moneyRow(
                      theme,
                      'Paid',
                      AppFormatters.currency(paid),
                      valueColor: cs.primary,
                    ),
                    _moneyRow(
                      theme,
                      'Pending',
                      AppFormatters.currency(pendingAmount),
                      valueColor: pendingAmount > 0
                          ? AppColors.warning
                          : AppColors.credit,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment received',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _muted(theme),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: paidCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() => calculateAmounts(context)),
                decoration: _inputDecoration(
                  theme,
                  '0.00',
                  'Paid amount',
                ).copyWith(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (selectedCustomer != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _softPrimary(theme),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedCustomer!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor:
                        cs.primary.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isCreating ? null : () => _createBill(context),
                  icon: isCreating
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.receipt_long_rounded, size: 20),
                  label: Text(
                    isCreating ? 'Creating…' : 'Create Bill',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile bottom summary ────────────────────────────────────────────────

  Widget _buildBillSummary(BuildContext context, ThemeData theme) {
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, -4),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 11,
                      color: _muted(theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(totalAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pendingAmount > 0
                        ? 'Pending ${AppFormatters.currency(pendingAmount)}'
                        : 'GST ${AppFormatters.currency(totalGstAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pendingAmount > 0
                          ? AppColors.warning
                          : AppColors.credit,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              width: 148,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  disabledBackgroundColor: cs.primary.withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isCreating ? null : () => _createBill(context),
                child: isCreating
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text(
                        'Create Bill',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main scroll content ──────────────────────────────────────────────────

  Widget _buildBillContent(
    BuildContext context,
    ThemeData theme,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync,
    List<CustomerResponseModel> filteredCustomers,
    bool showCreateCustomerForm,
  ) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 28 : 16,
        16,
        isDesktop ? 28 : 16,
        isDesktop ? 28 : 120,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerSelector(
              theme,
              filteredCustomers,
              showCreateCustomerForm,
            ),
            const SizedBox(height: 14),
            _buildAddItemCard(theme, products, productsAsync),
            const SizedBox(height: 14),
            _buildItemsSection(context, theme),
            if (!isDesktop) ...[
              const SizedBox(height: 14),
              _sectionCard(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      theme: theme,
                      step: 3,
                      title: 'Payment',
                      subtitle: 'How much did the customer pay?',
                      icon: Icons.payments_outlined,
                    ),
                    TextField(
                      controller: paidCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) =>
                          setState(() => calculateAmounts(context)),
                      decoration: _inputDecoration(theme, '0.00', 'Paid amount')
                          .copyWith(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _moneyRow(
                            theme,
                            'Subtotal',
                            AppFormatters.currency(subtotalAmount),
                          ),
                          _moneyRow(
                            theme,
                            'GST',
                            AppFormatters.currency(totalGstAmount),
                            valueColor: AppColors.credit,
                          ),
                          _moneyRow(
                            theme,
                            'Pending',
                            AppFormatters.currency(pendingAmount),
                            valueColor: pendingAmount > 0
                                ? AppColors.warning
                                : AppColors.credit,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemCard(
    ThemeData theme,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync,
  ) {
    final cs = theme.colorScheme;

    return _sectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            theme: theme,
            step: 2,
            title: 'Add items',
            subtitle: 'Search catalog or enter a custom item',
            icon: Icons.add_shopping_cart_rounded,
            trailing: selectedProductId != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.creditBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.credit,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Catalog',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.credit,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          TextField(
            controller: itemNameCtrl,
            onChanged: (v) {
              setState(() {
                itemSearchQuery = v;
                if (selectedProductId != null) {
                  final matched =
                      products.where((p) => p.id == selectedProductId).toList();
                  if (matched.isEmpty || matched.first.name != v) {
                    selectedProductId = null;
                  }
                }
              });
            },
            decoration: _inputDecoration(
              theme,
              'Search product or type item name',
              'Item / Service',
            ).copyWith(
              prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
              suffixIcon: selectedProductId != null
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.credit,
                      size: 20,
                    )
                  : null,
            ),
          ),
          if (itemSearchQuery.trim().isNotEmpty && selectedProductId == null)
            _buildProductSuggestions(theme, products, productsAsync),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: itemPriceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  readOnly: selectedProductId != null,
                  decoration: _inputDecoration(theme, '0.00', 'Price').copyWith(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: itemQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(theme, '1', 'Qty'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemBarCodeCtrl,
                  readOnly: selectedProductId != null,
                  decoration: _inputDecoration(theme, 'Optional', 'Barcode'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: productGSTCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  readOnly: selectedProductId != null,
                  decoration: _inputDecoration(theme, '0', 'GST %'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: addItem,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Add to bill',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, ThemeData theme) {
    final cs = theme.colorScheme;

    if (items.isEmpty) {
      return _sectionCard(
        theme: theme,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: _softPrimary(theme),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 30,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No items yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search a product above and tap Add to bill',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _muted(theme),
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Text(
                'Items on bill',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _softPrimary(theme),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(items.length, (i) {
          final item = items[i];
          final subtotal = item['line_subtotal'] as double;
          final gstPercent = item['gst_percent'] ?? 0;
          final gstAmount = item['gst_amount'] as double;
          final lineTotal =
              item['line_total'] as double? ?? (subtotal + gstAmount);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line(theme)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 36,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip(theme, AppFormatters.currencyOf(item['price'])),
                          _chip(theme, 'Qty ${item['quantity']}'),
                          _chip(theme, 'GST $gstPercent%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.currency(lineTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GST ${AppFormatters.currency(gstAmount)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.credit,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          items.removeAt(i);
                          calculateAmounts(context);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductSuggestions(
    ThemeData theme,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync,
  ) {
    final cs = theme.colorScheme;

    if (productsAsync.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
        ),
      );
    }

    if (productsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.debitBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Couldn't load products — you can still add a manual item",
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ),
      );
    }

    final query = itemSearchQuery.toLowerCase();
    final matches = products
        .where((p) => p.name.toLowerCase().contains(query))
        .take(6)
        .toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line(theme)),
          ),
          child: Text(
            'No catalog match — will be added as a custom item',
            style: TextStyle(color: _muted(theme), fontSize: 12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line(theme)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final product = matches[i];
            final outOfStock = product.stock <= 0;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: outOfStock
                  ? null
                  : () {
                      setState(() {
                        itemNameCtrl.text = product.name;
                        itemPriceCtrl.text = product.price.toString();
                        selectedProductId = product.id;
                        productGSTCtrl.text = product.gst_percent.toString();
                        itemSearchQuery = '';
                        if (product.barcode != null &&
                            product.barcode!.trim().isNotEmpty) {
                          itemBarCodeCtrl.text = product.barcode!;
                        } else {
                          itemBarCodeCtrl.clear();
                        }
                      });
                    },
              child: Opacity(
                opacity: outOfStock ? 0.45 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line(theme)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: _softPrimary(theme),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outOfStock
                                  ? 'Out of stock'
                                  : 'In stock · ${product.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                color: outOfStock ? Colors.red : _muted(theme),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.currency(product.price),
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomerSelector(
    ThemeData theme,
    List<CustomerResponseModel> filteredCustomers,
    bool showCreateCustomerForm,
  ) {
    final type = ref.watch(appTypeProvider);
    final cs = theme.colorScheme;

    return _sectionCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            theme: theme,
            step: 1,
            title: 'Customer',
            subtitle: selectedCustomer != null
                ? 'Customer selected for this bill'
                : 'Search existing or type a new name',
            icon: Icons.person_outline_rounded,
          ),
          if (selectedCustomer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _softPrimary(theme),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedCustomer!.name.isNotEmpty
                          ? selectedCustomer!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCustomer!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedCustomer!.phone ?? 'No phone',
                          style: TextStyle(
                            fontSize: 12,
                            color: _muted(theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Change customer',
                    onPressed: _clearCustomerSelection,
                    icon: Icon(Icons.close_rounded, color: cs.primary),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: searchCtrl,
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: DashboardText.prsSearchCustomer(type),
                hintStyle: TextStyle(fontSize: 14, color: _muted(theme)),
                prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            searchCtrl.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _line(theme)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: showCreateCustomerForm
                    ? _buildInlineCreateCustomerForm(theme)
                    : filteredCustomers.isEmpty
                        ? _buildNoCustomerFound(theme)
                        : _buildCustomerList(theme, filteredCustomers),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNoCustomerFound(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      key: const ValueKey('no_customer'),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line(theme)),
      ),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, size: 36, color: _muted(theme)),
          const SizedBox(height: 8),
          Text(
            'No customer found',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another name, or keep typing to create new',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted(theme), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(
    ThemeData theme,
    List<CustomerResponseModel> filteredCustomers,
  ) {
    final cs = theme.colorScheme;

    return ConstrainedBox(
      key: const ValueKey('customer_list'),
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: filteredCustomers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final customer = filteredCustomers[i];
          final isSelected = selectedCustomerId == customer.id;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                selectedCustomer = customer;
                selectedCustomerId = customer.id;
                searchCtrl.text = customer.name;
                searchQuery = customer.name;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? _softPrimary(theme) : cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? cs.primary : _line(theme),
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : _softPrimary(theme),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isSelected ? cs.onPrimary : cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          customer.phone ?? 'No phone',
                          style: TextStyle(color: _muted(theme), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: cs.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInlineCreateCustomerForm(ThemeData theme) {
    final cs = theme.colorScheme;

    return Form(
      key: _customerFormKey,
      child: Container(
        key: const ValueKey('create_customer_form'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  color: cs.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'New customer — will be saved when you create the bill',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: cs.primary.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 355,
              child: TextFormField(
                controller: _newCustomerPhoneCtrl,
                keyboardType: TextInputType.phone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  labelStyle: TextStyle(color: _muted(theme)),
                  filled: true,
                  fillColor: cs.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _line(theme)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.error),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 10) {
                    return null;
                  }
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                    return 'Enter a valid Indian mobile number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderChip(theme, 'male', 'Male'),
                const SizedBox(width: 10),
                _buildGenderChip(theme, 'female', 'Female'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(ThemeData theme, String value, String label) {
    final isSelected = _newCustomerGender == value;
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _newCustomerGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _softPrimary(theme) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : _line(theme),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSelected ? cs.primary : _muted(theme),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    String hint,
    String label,
  ) {
    final cs = theme.colorScheme;
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: TextStyle(fontSize: 14, color: _muted(theme)),
      labelStyle: TextStyle(fontSize: 13, color: _muted(theme)),
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _line(theme)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  Widget _chip(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line(theme)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _muted(theme),
        ),
      ),
    );
  }
}
