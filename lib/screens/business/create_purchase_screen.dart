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
  }Future<void> _createBill(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
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

          messenger.showSnackBar(
            SnackBar(
              content: Text(
                "Failed to create customer: $e",
              ),
              backgroundColor: Colors.red,
            ),
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Purchase added successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // ─────────────────────────────────────
      // RECEIPT
      // ─────────────────────────────────────
      if (!navigator.mounted) return;

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
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    // 🔥 watch the same product provider ProductScreen uses
    final productsAsync = ref.watch(productProvider);
    final products = productsAsync.asData?.value ?? <ProductModel>[];

    final filteredCustomers = customers.where((customer) {
      final q = searchQuery.toLowerCase();
      return customer.name.toLowerCase().contains(q);
    }).toList();

    final showCreateCustomerForm =
        selectedCustomer == null &&
        searchQuery.trim().isNotEmpty &&
        filteredCustomers.isEmpty;
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Create Bill",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : isDesktop
          ? Row(
        children: [
          // MAIN BILL CONTENT
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

          // DESKTOP RIGHT PANEL
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

      // MOBILE ONLY
      bottomNavigationBar: isDesktop
          ? null
          : _buildBillSummary(context, theme),
    );
    // return Scaffold(
    //   backgroundColor: const Color(0xffF5F7FB),
    //   appBar: AppBar(
    //     title: const Text(
    //       "Create Bill",
    //       style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
    //     ),
    //   ),
    //
    //   bottomNavigationBar: Container(
    //     padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    //
    //     decoration: BoxDecoration(
    //       color: Colors.white,
    //
    //       borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    //
    //       boxShadow: [
    //         BoxShadow(
    //           blurRadius: 18,
    //
    //           offset: const Offset(0, -2),
    //
    //           color: Colors.black.withOpacity(0.04),
    //         ),
    //       ],
    //     ),
    //
    //     child: SafeArea(
    //       child: Row(
    //         children: [
    //           Expanded(
    //             child: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Column(
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     Text(
    //                       "₹${totalAmount.toStringAsFixed(2)}",
    //                       style: TextStyle(
    //                         fontSize: 22,
    //                         fontWeight: FontWeight.bold,
    //                         color: theme.primaryColor,
    //                       ),
    //                     ),
    //
    //                     const SizedBox(height: 2),
    //
    //                     Text(
    //                       "Subtotal ₹${subtotalAmount.toStringAsFixed(0)}",
    //                       style: const TextStyle(fontSize: 11),
    //                     ),
    //
    //                     Text(
    //                       "GST Total ₹${totalGstAmount.toStringAsFixed(0)}",
    //                       style: const TextStyle(
    //                         fontSize: 11,
    //                         color: Colors.green,
    //                       ),
    //                     ),
    //
    //                     Text(
    //                       "Pending ₹${pendingAmount.toStringAsFixed(0)}",
    //                       style: TextStyle(
    //                         color: Colors.grey.shade600,
    //                         fontSize: 11,
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ],
    //             ),
    //           ),
    //           const SizedBox(width: 14),
    //           Expanded(
    //             child: SizedBox(
    //               height: 40,
    //               child: ElevatedButton(
    //                 style: ElevatedButton.styleFrom(
    //                   elevation: 0,
    //                   backgroundColor: theme.primaryColor,
    //                   foregroundColor: Colors.white,
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(16),
    //                   ),
    //                 ),
    //                 onPressed: isCreating
    //                     ? null
    //                     : () async {
    //                         final messenger = ScaffoldMessenger.of(context);
    //                         final navigator = Navigator.of(context);
    //
    //                         if (selectedCustomerId == null) {
    //                           final typedName = searchCtrl.text.trim();
    //
    //                           if (typedName.isEmpty) {
    //                             CustomDialog.showErrorSnack(
    //                               context,
    //                               "Select or enter a customer",
    //                             );
    //                             return;
    //                           }
    //
    //                           if (showCreateCustomerForm) {
    //                             final phone = _newCustomerPhoneCtrl.text.trim();
    //
    //                             if (phone.isEmpty) {
    //                               CustomDialog.showErrorSnack(
    //                                 context,
    //                                 "Enter phone number for new customer",
    //                               );
    //                               return;
    //                             }
    //
    //                             setState(() {
    //                               isCreating = true;
    //                             });
    //
    //                             try {
    //                               final newCustomer = await _createCustomer(
    //                                 name: typedName,
    //                                 phone: phone,
    //                               );
    //
    //                               if (!mounted) return;
    //
    //                               setState(() {
    //                                 selectedCustomer = newCustomer;
    //                                 selectedCustomerId = newCustomer.id;
    //                               });
    //                             } catch (e) {
    //                               if (!mounted) return;
    //
    //                               setState(() {
    //                                 isCreating = false;
    //                               });
    //
    //                               messenger.showSnackBar(
    //                                 SnackBar(
    //                                   content: Text(
    //                                     "Failed to create customer: $e",
    //                                   ),
    //                                   backgroundColor: Colors.red,
    //                                 ),
    //                               );
    //
    //                               return;
    //                             }
    //                           } else {
    //                             CustomDialog.showErrorSnack(
    //                               context,
    //                               "Select customer",
    //                             );
    //                             return;
    //                           }
    //                         }
    //
    //                         if (items.isEmpty) {
    //                           CustomDialog.showErrorSnack(
    //                             context,
    //                             "Add items first",
    //                           );
    //
    //                           if (mounted) {
    //                             setState(() {
    //                               isCreating = false;
    //                             });
    //                           }
    //
    //                           return;
    //                         }
    //
    //                         if (!isCreating) {
    //                           setState(() {
    //                             isCreating = true;
    //                           });
    //                         }
    //
    //                         try {
    //                           final purchaseItems = items.map((e) {
    //                             return PurchaseItemModel(
    //                               productId: e["productId"] ?? 0,
    //                               barcode: e["barcode"] ?? "",
    //                               name: e["name"],
    //                               price: e["price"],
    //                               quantity: e["quantity"],
    //                               gstPercent: e["gst_percent"],
    //                             );
    //                           }).toList();
    //                           // final purchaseItems = items.map((e) {
    //                           //   return PurchaseItemModel(
    //                           //     productId: e["productId"],
    //                           //     barcode: "",
    //                           //     name: e["name"],
    //                           //     price: e["price"],
    //                           //     quantity: e["quantity"],
    //                           //     gstPercent: e["gst_percent"],
    //                           //   );
    //                           // }).toList();
    //
    //                           final model = CreatePurchaseModel(
    //                             customerId: selectedCustomerId!,
    //                             businessId: businessId,
    //                             items: purchaseItems,
    //                             totalAmount: totalAmount,
    //                             paid: double.tryParse(paidCtrl.text) ?? 0,
    //                             pending: pendingAmount,
    //                             date: DateTime.now()
    //                                 .toIso8601String()
    //                                 .split("T")
    //                                 .first,
    //                           );
    //
    //                           // Read before await
    //                           final businessName = ref.read(
    //                             businessNameProvider,
    //                           );
    //                           final businessPhone = ref.read(
    //                             businessPhoneProvider,
    //                           );
    //                           final businessAddress = ref.read(
    //                             businessAddressProvider,
    //                           );
    //
    //                           debugPrint(model.toJson().toString());
    //                           debugPrint(businessName);
    //                           debugPrint(businessAddress);
    //                           debugPrint(businessPhone);
    //
    //                           final createdBill = await ref
    //                               .read(businessControllerProvider.notifier)
    //                               .createPurchase(model: model);
    //
    //                           messenger.showSnackBar(
    //                             const SnackBar(
    //                               content: Text("Purchase added successfully"),
    //                               backgroundColor: Colors.green,
    //                             ),
    //                           );
    //
    //                           if (!navigator.mounted) return;
    //                           await navigator.push(
    //                             MaterialPageRoute(
    //                               builder: (_) => ReceiptPreviewScreen(
    //                                 bill: createdBill,
    //                                 businessName: businessName,
    //                                 businessPhone: businessPhone,
    //                                 businessAddress: businessAddress,
    //                                 customerName: selectedCustomer?.name,
    //                                 isThermal: true,
    //                               ),
    //                             ),
    //                           );
    //                         } catch (e) {
    //                           if (mounted) {
    //                             CustomDialog.showErrorSnack(
    //                               context,
    //                               e.toString(),
    //                             );
    //                           }
    //                         } finally {
    //                           if (mounted) {
    //                             setState(() {
    //                               isCreating = false;
    //                             });
    //                           }
    //                         }
    //                       },
    //                 child: Text(
    //                   isCreating ? "Creating..." : "Create",
    //                   style: TextStyle(
    //                     fontWeight: FontWeight.w500,
    //                     fontSize: 16,
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    //
    //   body: isLoading
    //       ? const Center(child: CircularProgressIndicator())
    //       : SingleChildScrollView(
    //           padding: const EdgeInsets.all(14),
    //
    //           child: Column(
    //             children: [
    //               /// 🔥 CUSTOMER SEARCH / CREATE
    //               _buildCustomerSelector(
    //                 theme,
    //                 filteredCustomers,
    //                 showCreateCustomerForm,
    //               ),
    //               const SizedBox(height: 7),
    //
    //               /// 🔥 ADD ITEM — with product search + auto price fill
    //               Container(
    //                 padding: const EdgeInsets.all(14),
    //                 decoration: BoxDecoration(
    //                   color: Colors.white,
    //                   borderRadius: BorderRadius.circular(22),
    //                   boxShadow: [
    //                     BoxShadow(
    //                       blurRadius: 12,
    //                       offset: const Offset(0, 4),
    //                       color: Colors.black.withOpacity(0.03),
    //                     ),
    //                   ],
    //                 ),
    //
    //                 child: Column(
    //                   children: [
    //                     SizedBox(
    //                       height: 45,
    //                       child: TextField(
    //                         controller: itemNameCtrl,
    //                         onChanged: (v) {
    //                           setState(() {
    //                             itemSearchQuery = v;
    //
    //                             // Any manual edit after a selection
    //                             // invalidates the selected product.
    //                             if (selectedProductId != null) {
    //                               final matched = products
    //                                   .where((p) => p.id == selectedProductId)
    //                                   .toList();
    //                               if (matched.isEmpty ||
    //                                   matched.first.name != v) {
    //                                 selectedProductId = null;
    //                               }
    //                             }
    //                           });
    //                         },
    //                         decoration:
    //                             _inputDecoration(
    //                               "Search Or Enter Item/Service",
    //                             ).copyWith(
    //                               suffixIcon: selectedProductId != null
    //                                   ? const Icon(
    //                                       Icons.check_circle,
    //                                       color: Colors.green,
    //                                       size: 20,
    //                                     )
    //                                   : null,
    //                             ),
    //                       ),
    //                     ),
    //
    //                     const SizedBox(height: 6),
    //
    //                     /// SECOND ROW: PRICE AND QUANTITY
    //                     SizedBox(
    //                       height: 45,
    //                       child: Row(
    //                         children: [
    //                           Expanded(
    //                             flex: 2,
    //                             child: TextField(
    //                               controller: itemPriceCtrl,
    //                               keyboardType: TextInputType.number,
    //                               // Price locked once a catalog product is
    //                               // selected — manual items keep it editable.
    //                               readOnly: selectedProductId != null,
    //                               decoration: _inputDecoration("Price"),
    //                             ),
    //                           ),
    //
    //                           const SizedBox(width: 12),
    //
    //                           Expanded(
    //                             child: TextField(
    //                               controller: itemQtyCtrl,
    //                               keyboardType: TextInputType.number,
    //                               decoration: _inputDecoration("Qty"),
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //
    //                     /// 🔥 PRODUCT SUGGESTIONS — shown while typing and
    //                     /// nothing is selected yet.
    //                     if (itemSearchQuery.trim().isNotEmpty &&
    //                         selectedProductId == null)
    //                       _buildProductSuggestions(products, productsAsync),
    //
    //                     const SizedBox(height: 6),
    //                     SizedBox(
    //                       height: 45,
    //                       child: TextField(
    //                         controller: itemBarCodeCtrl,
    //
    //                         readOnly: selectedProductId != null,
    //
    //                         decoration: _inputDecoration(
    //                           "Product Barcode (Optional)",
    //                         ),
    //                       ),
    //                     ),
    //                     const SizedBox(height: 6),
    //                     SizedBox(
    //                       height: 45,
    //                       child: TextField(
    //                         controller: productGSTCtrl,
    //                         decoration: _inputDecoration("GST (Optional)"),
    //                       ),
    //                     ),
    //                     const SizedBox(height: 12),
    //                     Row(
    //                       children: [
    //                         Expanded(
    //                           child: SizedBox(
    //                             height: 40,
    //                             child: ElevatedButton.icon(
    //                               style: ElevatedButton.styleFrom(
    //                                 backgroundColor: theme.primaryColor,
    //                                 foregroundColor: Colors.white,
    //                                 elevation: 0,
    //                                 shape: RoundedRectangleBorder(
    //                                   borderRadius: BorderRadius.circular(16),
    //                                 ),
    //                               ),
    //                               onPressed: addItem,
    //                               icon: Icon(Icons.add, weight: 700, size: 20),
    //                               label: const Text(
    //                                 "Add Item",
    //                                 style: TextStyle(
    //                                   fontWeight: FontWeight.w500,
    //                                   fontSize: 14,
    //                                 ),
    //                               ),
    //                             ),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //
    //               const SizedBox(height: 14),
    //
    //               /// 🔥 ITEMS
    //               if (items.isEmpty)
    //                 Container(
    //                   width: double.infinity,
    //                   padding: const EdgeInsets.symmetric(vertical: 34),
    //                   decoration: BoxDecoration(
    //                     color: Colors.white,
    //                     borderRadius: BorderRadius.circular(22),
    //                     boxShadow: [
    //                       BoxShadow(
    //                         blurRadius: 12,
    //                         offset: const Offset(0, 4),
    //                         color: Colors.black.withOpacity(0.03),
    //                       ),
    //                     ],
    //                   ),
    //
    //                   child: Column(
    //                     children: [
    //                       Icon(
    //                         Icons.shopping_bag_outlined,
    //
    //                         size: 34,
    //
    //                         color: Colors.grey.shade400,
    //                       ),
    //
    //                       const SizedBox(height: 8),
    //
    //                       Text(
    //                         "No item / service added yet",
    //
    //                         style: TextStyle(
    //                           color: Colors.grey.shade600,
    //
    //                           fontSize: 13,
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 )
    //               else
    //                 Column(
    //                   children: List.generate(items.length, (i) {
    //                     final item = items[i];
    //
    //                     final subtotal = item["line_subtotal"] as double;
    //                     final gstPercent = item["gst_percent"] ?? 0;
    //                     final gstAmount = item["gst_amount"] as double;
    //
    //                     return Container(
    //                       margin: const EdgeInsets.only(bottom: 10),
    //                       padding: const EdgeInsets.all(14),
    //                       decoration: BoxDecoration(
    //                         color: Colors.white,
    //                         borderRadius: BorderRadius.circular(20),
    //                         border: Border.all(color: Colors.grey.shade200),
    //                         boxShadow: [
    //                           BoxShadow(
    //                             blurRadius: 12,
    //                             offset: const Offset(0, 4),
    //                             color: Colors.black.withOpacity(0.03),
    //                           ),
    //                         ],
    //                       ),
    //                       child: Row(
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         children: [
    //                           Expanded(
    //                             child: Column(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 Text(
    //                                   item["name"],
    //                                   style: const TextStyle(
    //                                     fontWeight: FontWeight.w600,
    //                                     fontSize: 14,
    //                                   ),
    //                                 ),
    //                                 const SizedBox(height: 4),
    //                                 Wrap(
    //                                   spacing: 6,
    //                                   runSpacing: 6,
    //                                   children: [
    //                                     _chip("₹${item["price"]}"),
    //                                     _chip("Qty ${item["quantity"]}"),
    //                                     _chip("GST $gstPercent%"),
    //                                   ],
    //                                 ),
    //                               ],
    //                             ),
    //                           ),
    //
    //                           const SizedBox(width: 12),
    //
    //                           Column(
    //                             crossAxisAlignment: CrossAxisAlignment.end,
    //                             children: [
    //                               Text(
    //                                 "₹${subtotal.toStringAsFixed(0)}",
    //                                 style: const TextStyle(
    //                                   fontWeight: FontWeight.bold,
    //                                   fontSize: 14,
    //                                 ),
    //                               ),
    //
    //                               const SizedBox(height: 4),
    //
    //                               Container(
    //                                 padding: const EdgeInsets.symmetric(
    //                                   horizontal: 6,
    //                                   vertical: 2,
    //                                 ),
    //                                 decoration: BoxDecoration(
    //                                   color: Colors.green.withOpacity(.08),
    //                                   borderRadius: BorderRadius.circular(6),
    //                                 ),
    //                                 child: Text(
    //                                   "GST ₹${gstAmount.toStringAsFixed(0)}",
    //                                   style: const TextStyle(
    //                                     fontSize: 11,
    //                                     color: Colors.green,
    //                                     fontWeight: FontWeight.w500,
    //                                   ),
    //                                 ),
    //                               ),
    //                             ],
    //                           ),
    //                           InkWell(
    //                             borderRadius: BorderRadius.circular(20),
    //                             onTap: () {
    //                               setState(() {
    //                                 items.removeAt(i);
    //                                 calculateAmounts(context);
    //                               });
    //                             },
    //                             child: Padding(
    //                               padding: const EdgeInsets.all(4),
    //                               child: Icon(
    //                                 Icons.delete_outline,
    //                                 size: 20,
    //                                 color: Colors.red.shade400,
    //                               ),
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     );
    //                   }),
    //                 ),
    //
    //               const SizedBox(height: 12),
    //
    //               /// 🔥 PAYMENT
    //               Container(
    //                 padding: const EdgeInsets.all(14),
    //
    //                 decoration: BoxDecoration(
    //                   color: Colors.white,
    //
    //                   borderRadius: BorderRadius.circular(22),
    //
    //                   boxShadow: [
    //                     BoxShadow(
    //                       blurRadius: 12,
    //
    //                       offset: const Offset(0, 4),
    //
    //                       color: Colors.black.withOpacity(0.03),
    //                     ),
    //                   ],
    //                 ),
    //
    //                 child: TextField(
    //                   controller: paidCtrl,
    //
    //                   keyboardType: TextInputType.number,
    //
    //                   // 🔥 FIXED — this must recalculate pending amount,
    //                   // not touch item-search state (that was the bug).
    //                   onChanged: (_) {
    //                     setState(() {
    //                       calculateAmounts(context);
    //                     });
    //                   },
    //
    //                   decoration: _inputDecoration("Enter Paid Amount"),
    //                 ),
    //               ),
    //
    //               const SizedBox(height: 120),
    //             ],
    //           ),
    //         ),
    // );
  }
  Widget _buildDesktopRightPanel(
      BuildContext context,
      ThemeData theme,
      ) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bill Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 24),

            // SAME TOTAL
            Text(
              "₹${totalAmount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),

            const SizedBox(height: 12),

            // SAME SUBTOTAL
            Text(
              "Subtotal ₹${subtotalAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 6),

            // SAME GST
            Text(
              "GST Total ₹${totalGstAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 6),

            // SAME PENDING
            Text(
              "Pending ₹${pendingAmount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),

            // ─────────────────────────────────────
            // PAYMENT
            // ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.03),
                  ),
                ],
              ),
              child: TextField(
                controller: paidCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {
                    calculateAmounts(context);
                  });
                },
                decoration: _inputDecoration(
                  "Enter Paid Amount",
                  "Enter Paid Amount",
                ),
              ),
            ),
            const Spacer(),

            // SAME CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isCreating
                    ? null
                    : () => _createBill(context),
                child: Text(
                  isCreating ? "Creating..." : "Create",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildBillSummary(
      BuildContext context,
      ThemeData theme,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, -2),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    "Subtotal ₹${subtotalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 11),
                  ),

                  Text(
                    "GST Total ₹${totalGstAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                    ),
                  ),

                  Text(
                    "Pending ₹${pendingAmount.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isCreating
                      ? null
                      : () => _createBill(context),
                  child: Text(
                    isCreating ? "Creating..." : "Create",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // ─────────────────────────────────────
          // CUSTOMER SEARCH / CREATE
          // ─────────────────────────────────────
          _buildCustomerSelector(
            theme,
            filteredCustomers,
            showCreateCustomerForm,
          ),

          const SizedBox(height: 7),

          // ─────────────────────────────────────
          // ADD ITEM
          // ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  color: Colors.black.withOpacity(0.03),
                ),
              ],
            ),
            child: Column(
              children: [
                // ITEM NAME / PRODUCT SEARCH
                SizedBox(
                  height: 45,
                  child: TextField(
                    controller: itemNameCtrl,
                    onChanged: (v) {
                      setState(() {
                        itemSearchQuery = v;

                        // If user changes the selected product name,
                        // remove the product selection.
                        if (selectedProductId != null) {
                          final matched = products
                              .where(
                                (p) => p.id == selectedProductId,
                          )
                              .toList();

                          if (matched.isEmpty ||
                              matched.first.name != v) {
                            selectedProductId = null;
                          }
                        }
                      });
                    },
                    decoration: _inputDecoration(
                      "Search Or Enter Item/Service",
                        "Item/Service",
                    ).copyWith(
                      suffixIcon: selectedProductId != null
                          ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // PRICE + QUANTITY
                SizedBox(
                  height: 45,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: itemPriceCtrl,
                          keyboardType: TextInputType.number,
                          readOnly: selectedProductId != null,
                          decoration: _inputDecoration("Price", "Price",),

                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextField(
                          controller: itemQtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration("Qty","Qty"),
                        ),
                      ),
                    ],
                  ),
                ),

                // PRODUCT SUGGESTIONS
                if (itemSearchQuery.trim().isNotEmpty &&
                    selectedProductId == null)
                  _buildProductSuggestions(
                    products,
                    productsAsync,
                  ),

                const SizedBox(height: 10),

                // BARCODE
                SizedBox(
                  height: 45,
                  child: TextField(
                    controller: itemBarCodeCtrl,
                    readOnly: selectedProductId != null,
                    decoration: _inputDecoration(
                      "Product Barcode (Optional)", "Product Barcode (Optional)",
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // GST
                SizedBox(
                  height: 45,
                  child: TextField(
                    controller: productGSTCtrl,
                    decoration: _inputDecoration(
                      "GST (Optional)",       "GST (Optional)",
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ADD ITEM BUTTON
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: addItem,
                          icon: const Icon(
                            Icons.add,
                            size: 20,
                          ),
                          label: const Text(
                            "Add Item",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─────────────────────────────────────
          // ITEMS
          // ─────────────────────────────────────
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 34,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.03),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 34,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "No item / service added yet",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: List.generate(
                items.length,
                    (i) {
                  final item = items[i];

                  final subtotal =
                  item["line_subtotal"] as double;

                  final gstPercent =
                      item["gst_percent"] ?? 0;

                  final gstAmount =
                  item["gst_amount"] as double;

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.03),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // ITEM INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _chip(
                                    "₹${item["price"]}",
                                  ),
                                  _chip(
                                    "Qty ${item["quantity"]}",
                                  ),
                                  _chip(
                                    "GST $gstPercent%",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // AMOUNT
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${subtotal.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                Colors.green.withOpacity(.08),
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Text(
                                "GST ₹${gstAmount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // DELETE
                        InkWell(
                          borderRadius:
                          BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              items.removeAt(i);
                              calculateAmounts(context);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (!isDesktop) ...[
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.03),
                  ),
                ],
              ),
              child: TextField(
                controller: paidCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {
                    calculateAmounts(context);
                  });
                },
                decoration: _inputDecoration(
                  "Enter Paid Amount",
                  "Enter Paid Amount",
                ),
              ),
            ),
          ],
          // Space so mobile content isn't hidden
          // behind the bottom summary.
          const SizedBox(height: 120),
        ],
      ),
    );
  }
  /// Product-suggestion dropdown shown under the item-name field while
  /// typing. Handles loading/error states from the provider and lets the
  /// user tap a product to auto-fill price + barcode.
  Widget _buildProductSuggestions(
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync,
  ) {
    if (productsAsync.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffF5F7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (productsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "Couldn't load products — added items will be manual",
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
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffF5F7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "No matching product — will be added as a manual item",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: const Color(0xffF5F7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
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
                        itemSearchQuery = "";

                        if (product.barcode != null &&
                            product.barcode!.trim().isNotEmpty) {
                          itemBarCodeCtrl.text = product.barcode!;
                        } else {
                          itemBarCodeCtrl.clear();
                        }
                      });
                    },
              child: Opacity(
                opacity: outOfStock ? 0.5 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outOfStock
                                  ? "Out of stock"
                                  : "Stock: ${product.stock}",
                              style: TextStyle(
                                fontSize: 11,
                                color: outOfStock
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${(product.price ?? 0).toStringAsFixed(((product.price ?? 0) % 1 == 0) ? 0 : 2)}",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
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

  /// Customer search/create card. No more click-to-expand — search is
  /// always visible and acts as both search box and new-customer name
  /// field.
  Widget _buildCustomerSelector(
    ThemeData theme,
    List<CustomerResponseModel> filteredCustomers,
    bool showCreateCustomerForm,
  ) {
    final type = ref.watch(appTypeProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// SEARCH / NAME FIELD — always visible, no toggle required.
          SizedBox(
            height: 45,
            child: TextField(
              controller: searchCtrl,
              readOnly: selectedCustomer != null,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: DashboardText.prsSearchCustomer(type),
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: theme.primaryColor,
                ),
                suffixIcon: selectedCustomer != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: "Remove selected customer",
                        onPressed: () {
                          setState(() {
                            selectedCustomer = null;
                            searchQuery = "";
                            searchCtrl.clear();
                          });
                        },
                      )
                    : (searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              tooltip: "Clear search",
                              onPressed: () {
                                setState(() {
                                  searchQuery = "";
                                  searchCtrl.clear();
                                });
                              },
                            )
                          : null),
                filled: true,
                fillColor: selectedCustomer != null
                    ? theme.primaryColor.withOpacity(0.06)
                    : const Color(0xffF5F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),

          /// SELECTED CUSTOMER PHONE HINT
          if (selectedCustomer != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                selectedCustomer!.phone ?? "No phone",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],

          /// LIST OR INLINE CREATE FORM (only when nothing is selected AND user has typed something)
          if (selectedCustomer == null && searchQuery.isNotEmpty) ...[
            const SizedBox(height: 14),
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
      ),
    );
  }

  /// Shown when user types but no matching customers exist
  Widget _buildNoCustomerFound(ThemeData theme) {
    return Container(
      key: const ValueKey("no_customer"),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.person_search, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            "No customer found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Create a new customer or try different search",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// CUSTOMER LIST — shown directly below the search field, no toggle.
  Widget _buildCustomerList(
    ThemeData theme,
    List<CustomerResponseModel> filteredCustomers,
  ) {
    return ConstrainedBox(
      key: const ValueKey("customer_list"),
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
            borderRadius: BorderRadius.circular(16),
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
                color: isSelected
                    ? theme.primaryColor.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primaryColor
                          : theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.primaryColor,
                        fontWeight: FontWeight.bold,
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          customer.phone ?? "No phone",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.primaryColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// INLINE "CREATE NEW CUSTOMER" HINT — just Phone + Gender.
  /// No submit button here anymore: pressing the bottom "Create" bill
  /// button now creates this customer first, then creates the bill.
  Widget _buildInlineCreateCustomerForm(ThemeData theme) {
    return Form(
      key: _customerFormKey,
      child: Container(
        key: const ValueKey("create_customer_form"),
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: const Color(0xffF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add_alt_1, color: theme.primaryColor, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "No matching customer — this will be created when you tap Create",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// PHONE
            SizedBox(
              height: 60,
              child: TextFormField(
                controller: _newCustomerPhoneCtrl,
                keyboardType: TextInputType.phone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Empty par error mat dikhao
                  }

                  // 10 digits hone se pehle error mat dikhao
                  if (value.length < 10) {
                    return null;
                  }

                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                    return "Enter a valid Indian mobile number";
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            /// GENDER CHIPS
            Row(
              children: [
                _buildGenderChip(theme, "male", "Male"),
                const SizedBox(width: 10),
                _buildGenderChip(theme, "female", "Female"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(ThemeData theme, String value, String label) {
    final isSelected = _newCustomerGender == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: () {
          setState(() {
            _newCustomerGender = value;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          padding: const EdgeInsets.symmetric(vertical: 8),

          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.white,

            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            ),
          ),

          alignment: Alignment.center,

          child: Text(
            label,

            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? theme.primaryColor : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint,String label) {
    final theme = ref.read((themeProvider));
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: TextStyle(fontSize: 14,color: Colors.grey.shade500),

      filled: true,

      fillColor: const Color(0xffF5F7FB),

      isDense: true,

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: const Color(0xffF5F7FB),

        borderRadius: BorderRadius.circular(100),
      ),

      child: Text(
        text,

        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
