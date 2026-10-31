import 'dart:convert';

import 'package:bigreminder/screens/business/receipt_preview_screen.dart';
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

enum _BillLineEditor { hidden, manual, catalog, edit }

/// Survives leaving the billing tab. Cleared only by the X button or a saved bill.
class _BillDraftStore {
  static String name = '';
  static String phone = '';
  static String? gender;
  static int? customerId;
  static List<Map<String, dynamic>> items = [];
  static String paid = '';
  static bool paidManuallyEdited = false;
  static bool billWithoutSavingCustomer = false;
  static String? unsavedBillCustomerName;

  static bool get hasContent =>
      name.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      items.isNotEmpty ||
      paid.trim().isNotEmpty ||
      customerId != null;

  static void clear() {
    name = '';
    phone = '';
    gender = null;
    customerId = null;
    items = [];
    paid = '';
    paidManuallyEdited = false;
    billWithoutSavingCustomer = false;
    unsavedBillCustomerName = null;
  }

  static void save(_CreatePurchaseScreenState state) {
    name = state.customerNameCtrl.text;
    phone = state._newCustomerPhoneCtrl.text;
    gender = state._newCustomerGender;
    customerId = state.selectedCustomerId;
    items = state.items.map((item) => Map<String, dynamic>.from(item)).toList();
    paid = state.paidCtrl.text;
    paidManuallyEdited = state._paidManuallyEdited;
    billWithoutSavingCustomer = state._billWithoutSavingCustomer;
    unsavedBillCustomerName = state._unsavedBillCustomerName;
  }

  static void restore(_CreatePurchaseScreenState state) {
    state.itemQtyCtrl.text = '1';
    if (!hasContent) return;
    state.customerNameCtrl.text = name;
    state._newCustomerPhoneCtrl.text = phone;
    state._newCustomerGender = gender;
    state.selectedCustomerId = customerId;
    state.items = items.map((item) => Map<String, dynamic>.from(item)).toList();
    state.paidCtrl.text = paid;
    state._paidManuallyEdited = paidManuallyEdited;
    state._billWithoutSavingCustomer = billWithoutSavingCustomer;
    state._unsavedBillCustomerName = unsavedBillCustomerName;
    if (state.items.isNotEmpty) {
      state._selectedLineIndex = state.items.length - 1;
    }
  }
}

class _BillColumn {
  final String label;
  final int flex;
  final TextAlign align;

  const _BillColumn(
    this.label,
    this.flex, {
    this.align = TextAlign.left,
  });
}

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

  final customerNameCtrl = TextEditingController();
  final _newCustomerPhoneCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _itemFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _barcodeFocus = FocusNode();
  final _gstFocus = FocusNode();
  final _paidFocus = FocusNode();
  final _createBillFocus = FocusNode(debugLabel: 'create-bill');
  final _tableFocus = FocusNode(debugLabel: 'bill-lines');
  final _deleteFocus = FocusNode(debugLabel: 'bill-line-delete');
  final _clearFocus = FocusNode(debugLabel: 'bill-clear');
  final _catalogFocus = FocusNode(debugLabel: 'catalog-list');
  final List<GlobalKey> _rowKeys = [];
  final List<GlobalKey> _catalogRowKeys = [];
  final _catalogKey = GlobalKey();
  final _customerPortal = OverlayPortalController();
  final _customerLink = LayerLink();
  final _uiTick = ValueNotifier<int>(0);
  final Map<int, int> _catalogQty = {};
  int? _catalogIndex;
  bool _lineDialogOpen = false;

  List<CustomerResponseModel> customers = [];

  List<Map<String, dynamic>> items = [];

  /// Product search & selection state. The actual product list itself
  /// comes from `productProvider` (watched in build) — not stored here.
  String itemSearchQuery = "";
  int? selectedProductId;
  int? _selectedLineIndex;
  _BillLineEditor _lineEditor = _BillLineEditor.hidden;

  bool isLoading = true;
  bool isCreating = false;
  bool _paidExceedsTotal = false;
  bool _paidManuallyEdited = false;

  /// Set when a new customer could not be saved because the plan limit is full.
  /// The bill still uses their typed name.
  bool _billWithoutSavingCustomer = false;
  bool _skippedCustomerBecauseNoPhone = false;
  String? _unsavedBillCustomerName;
  bool _billSaved = false;

  /// Optional. Stays empty until Male or Female is chosen.
  String? _newCustomerGender;

  static const String _unnamedCustomerName = 'Unnamed Customer';

  CustomerResponseModel? selectedCustomer;

  int businessId = 0;

  int? selectedCustomerId;

  double totalAmount = 0;
  double pendingAmount = 0;
  double subtotalAmount = 0;
  double totalGstAmount = 0;

  @override
  void initState() {
    super.initState();
    _BillDraftStore.restore(this);
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
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_lineDialogOpen) _uiTick.value++;
  }

  @override
  void dispose() {
    if (!_billSaved) _BillDraftStore.save(this);
    if (_customerPortal.isShowing) _customerPortal.hide();
    _uiTick.dispose();
    paidCtrl.dispose();
    itemNameCtrl.dispose();
    itemBarCodeCtrl.dispose();
    itemPriceCtrl.dispose();
    itemQtyCtrl.dispose();
    customerNameCtrl.dispose();
    _newCustomerPhoneCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _itemFocus.dispose();
    _priceFocus.dispose();
    _qtyFocus.dispose();
    _barcodeFocus.dispose();
    _gstFocus.dispose();
    _paidFocus.dispose();
    _createBillFocus.dispose();
    _tableFocus.dispose();
    _deleteFocus.dispose();
    _clearFocus.dispose();
    _catalogFocus.dispose();
    super.dispose();
  }

  void _moveTo(FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  /// Visible fields, in the order Down / Up should walk them.
  List<FocusNode> _keyboardFields() {
    final editing = _lineEditor == _BillLineEditor.manual ||
        _lineEditor == _BillLineEditor.edit;
    final nodes = <FocusNode>[
      _nameFocus,
      _phoneFocus,
      _clearFocus,
      if (editing) ...[
        _itemFocus,
        _priceFocus,
        _qtyFocus,
        _barcodeFocus,
        _gstFocus,
      ],
      _paidFocus,
      _createBillFocus,
    ];
    return [
      for (final node in nodes)
        if (node.context != null) node,
    ];
  }

  Widget _arrowField({required FocusNode node, required Widget child}) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _stepField(node, 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _stepField(node, -1),
      },
      child: child,
    );
  }

  void _stepField(FocusNode current, int delta) {
    final fields = _keyboardFields();
    final index = fields.indexOf(current);
    if (index == -1) return;

    final catalog = _visibleCatalogProducts();
    final catalogOpen =
        _lineEditor == _BillLineEditor.catalog && catalog.isNotEmpty;
    if (catalogOpen && delta > 0 && current == _clearFocus) {
      _focusCatalogRow(_catalogIndex ?? 0);
      return;
    }
    if (catalogOpen && delta < 0 && current == _paidFocus) {
      _focusCatalogRow(_catalogIndex ?? catalog.length - 1);
      return;
    }

    final next = index + delta;
    if (next >= 0 && next < fields.length) {
      _moveTo(fields[next]);
      return;
    }
    if (delta > 0 && items.isNotEmpty) {
      _focusTableRow(_selectedLineIndex ?? 0);
    }
  }

  List<ProductModel> _visibleCatalogProducts() {
    return _currentProducts()
        .where((product) => _productMatchesQuery(product, itemSearchQuery))
        .toList();
  }

  void _syncCatalogKeys(int count) {
    while (_catalogRowKeys.length < count) {
      _catalogRowKeys.add(GlobalKey());
    }
    if (_catalogRowKeys.length > count) {
      _catalogRowKeys.removeRange(count, _catalogRowKeys.length);
    }
  }

  void _focusCatalogRow(int index) {
    final products = _visibleCatalogProducts();
    if (products.isEmpty) return;
    final safe = index.clamp(0, products.length - 1);
    setState(() => _catalogIndex = safe);
    _catalogFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || safe < 0 || safe >= _catalogRowKeys.length) return;
      final rowContext = _catalogRowKeys[safe].currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  KeyEventResult _onCatalogArrow(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final products = _visibleCatalogProducts();
    if (products.isEmpty) return KeyEventResult.ignored;
    final current = _catalogIndex ?? 0;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (current >= products.length - 1) {
        if (_paidFocus.context != null) {
          _moveTo(_paidFocus);
        } else if (items.isNotEmpty) {
          _focusTableRow(_selectedLineIndex ?? 0);
        }
        return KeyEventResult.handled;
      }
      _focusCatalogRow(current + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (current <= 0) {
        _moveTo(_clearFocus.context != null ? _clearFocus : _phoneFocus);
        return KeyEventResult.handled;
      }
      _focusCatalogRow(current - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final product = products[current.clamp(0, products.length - 1)];
      if (product.stock > 0) _addCatalogProduct(product);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onClearKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _resetBillForm();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _stepField(_clearFocus, 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _stepField(_clearFocus, -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onCreateBillKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (!isCreating) _createBill(context);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _stepField(_createBillFocus, -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _stepField(_createBillFocus, 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onDeleteKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _deleteSelectedLine();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _tableFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final current = _selectedLineIndex ?? 0;
      final next = event.logicalKey == LogicalKeyboardKey.arrowDown
          ? (current + 1).clamp(0, items.length - 1).toInt()
          : (current - 1).clamp(0, items.length - 1).toInt();
      if (next != current) {
        setState(() => _selectedLineIndex = next);
        _revealRow(next);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _deleteFocus.requestFocus();
        });
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _syncRowKeys() {
    while (_rowKeys.length < items.length) {
      _rowKeys.add(GlobalKey());
    }
    if (_rowKeys.length > items.length) {
      _rowKeys.removeRange(items.length, _rowKeys.length);
    }
  }

  void _focusTableRow(int index) {
    if (items.isEmpty) return;
    final safe = index.clamp(0, items.length - 1);
    setState(() => _selectedLineIndex = safe);
    _tableFocus.requestFocus();
    _revealRow(safe);
  }

  void _revealRow(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _rowKeys.length) return;
      final rowContext = _rowKeys[index].currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        alignment: 0.4,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  KeyEventResult _onTableArrow(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (items.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final current = _selectedLineIndex ?? -1;
      _focusTableRow((current + 1).clamp(0, items.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final current = _selectedLineIndex ?? 0;
      if (current <= 0) {
        final fields = _keyboardFields();
        if (fields.isNotEmpty) _moveTo(fields.last);
        return KeyEventResult.handled;
      }
      _focusTableRow(current - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_selectedLineIndex == null) return KeyEventResult.ignored;
      _deleteFocus.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get _typedCustomerName => customerNameCtrl.text.trim();

  /// Name on the bill: typed name, otherwise the full phone, otherwise unnamed.
  String _resolvedCustomerName(String name, String phone) {
    if (name.isNotEmpty) return name;
    if (phone.isNotEmpty) return phone;
    return _unnamedCustomerName;
  }

  String get _billCustomerLabel =>
      _resolvedCustomerName(_typedCustomerName, _typedCustomerPhone);

  String get _typedCustomerPhone => _newCustomerPhoneCtrl.text.trim();

  bool get _customerFieldsEmpty =>
      _typedCustomerName.isEmpty &&
      _typedCustomerPhone.isEmpty &&
      (_newCustomerGender == null || _newCustomerGender!.isEmpty);

  List<CustomerResponseModel> _matchingCustomers() {
    final name = _typedCustomerName.toLowerCase();
    final phone = _typedCustomerPhone;
    if (name.isEmpty && phone.isEmpty) return [];

    return customers.where((customer) {
      final nameMatches =
          name.isEmpty || customer.name.toLowerCase().contains(name);
      final phoneMatches = phone.isEmpty || customer.phone.contains(phone);
      if (name.isNotEmpty && phone.isNotEmpty) {
        return nameMatches && phoneMatches;
      }
      return name.isNotEmpty ? nameMatches : phoneMatches;
    }).toList();
  }

  CustomerResponseModel? _exactCustomerMatch(String name, String phone) {
    if (phone.isNotEmpty) {
      final byPhone =
          customers.where((customer) => customer.phone.trim() == phone).toList();
      if (name.isNotEmpty) {
        final both = byPhone
            .where(
              (customer) => customer.name.trim().toLowerCase() == name.toLowerCase(),
            )
            .toList();
        if (both.length == 1) return both.first;
      }
      if (byPhone.length == 1) return byPhone.first;
      return null;
    }

    if (name.isEmpty) return null;
    final byName = customers
        .where(
          (customer) => customer.name.trim().toLowerCase() == name.toLowerCase(),
        )
        .toList();
    if (byName.length == 1) return byName.first;
    return null;
  }

  void _selectExistingCustomer(CustomerResponseModel customer) {
    customerNameCtrl.text = customer.name;
    _newCustomerPhoneCtrl.text = customer.phone;
    final gender = customer.gender.trim().toLowerCase();
    _newCustomerGender =
        gender == 'male' || gender == 'female' ? gender : null;
    selectedCustomer = customer;
    selectedCustomerId = customer.id;
  }

  void _onCustomerFieldChanged() {
    if (selectedCustomer == null) {
      setState(() {});
      return;
    }

    final sameName = _typedCustomerName == selectedCustomer!.name.trim();
    final samePhone = _typedCustomerPhone == selectedCustomer!.phone.trim();
    final savedGender = selectedCustomer!.gender.trim().toLowerCase();
    final sameGender = (_newCustomerGender ?? '') ==
        ((savedGender == 'male' || savedGender == 'female') ? savedGender : '');

    setState(() {
      if (!sameName || !samePhone || !sameGender) {
        selectedCustomer = null;
        selectedCustomerId = null;
      }
    });
  }

  Future<bool> _ensureCustomer(BuildContext context) async {
    if (selectedCustomerId != null) return true;

    final name = _typedCustomerName;
    final phone = _typedCustomerPhone;

    if (phone.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showError('Enter a 10-digit mobile number, or leave it blank.');
      return false;
    }

    final exact = _exactCustomerMatch(name, phone);
    if (exact != null) {
      setState(() => _selectExistingCustomer(exact));
      return true;
    }

    if (_customerFieldsEmpty) {
      final demos = customers
          .where(
            (customer) =>
                customer.name.trim().toLowerCase() ==
                _unnamedCustomerName.toLowerCase(),
          )
          .toList();
      if (demos.isNotEmpty) {
        setState(() {
          selectedCustomer = demos.last;
          selectedCustomerId = demos.last.id;
        });
        return true;
      }
    }

    setState(() => isCreating = true);

    try {
      final created = await _createCustomer(
        name: _resolvedCustomerName(name, phone),
        phone: phone,
      );
      if (!mounted) return false;
      setState(() {
        selectedCustomer = created;
        selectedCustomerId = created.id;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      final message = _errorText(e);
      if (message.toLowerCase().contains('already exists')) {
        await _fetchCustomers();
        final existing = _exactCustomerMatch(
          _resolvedCustomerName(name, phone),
          phone,
        );
        if (existing != null) {
          setState(() => _selectExistingCustomer(existing));
          return true;
        }
      }
      if (_isCustomerLimitError(message) &&
          _continueBillWithoutNewCustomer(name, phone)) {
        return true;
      }
      if (_isPhoneRequiredError(message) &&
          _continueBillWithoutNewCustomer(
            name,
            phone,
            missingPhone: true,
          )) {
        return true;
      }
      _showApiNotice(message);
      return false;
    }
  }

  Future<void> _createBill(BuildContext context) async {
    final navigator = Navigator.of(context);
    _skippedCustomerBecauseNoPhone = false;

    final customerReady = await _ensureCustomer(context);
    if (!customerReady || !mounted) {
      if (mounted) {
        setState(() => isCreating = false);
      }
      return;
    }

    // ─────────────────────────────────────
    // ITEM VALIDATION
    // ─────────────────────────────────────
    if (items.isEmpty) {
      _showError('Add at least one item before creating the bill.');

      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }

      return;
    }

    final paidNow = double.tryParse(paidCtrl.text) ?? 0;
    if (paidNow - totalAmount > 0.01) {
      _showError('Paid amount cannot be more than the bill total.');
      if (mounted) {
        setState(() => isCreating = false);
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

      _billSaved = true;
      _BillDraftStore.clear();

      // ─────────────────────────────────────
      // SUCCESS
      // ─────────────────────────────────────
      if (mounted) {
        _showSuccess(_billCreatedMessage());
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
              customerName: _unsavedBillCustomerName ??
                  _resolvedCustomerName(
                    selectedCustomer?.name.trim() ?? '',
                    selectedCustomer?.phone.trim() ?? '',
                  ),
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
        _showApiNotice(_errorText(e));
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
        final savedId = selectedCustomerId;
        if (savedId != null) {
          final match = customers.where((customer) => customer.id == savedId);
          if (match.isNotEmpty) selectedCustomer = match.first;
        }
        if (items.isNotEmpty || paidCtrl.text.trim().isNotEmpty) {
          calculateAmounts(context);
        }
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showApiNotice(_errorText(e));
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

    if (!_paidManuallyEdited) {
      final prefilled = totalAmount <= 0 ? '' : totalAmount.toStringAsFixed(2);
      if (paidCtrl.text != prefilled) {
        paidCtrl.text = prefilled;
      }
    }

    final paid = double.tryParse(paidCtrl.text) ?? 0;

    // Allow tiny floating-point precision differences.
    // Keep the typed amount so the last digit can be corrected.
    if (paid - totalAmount > 0.01) {
      if (!_paidExceedsTotal) {
        _paidExceedsTotal = true;
        _showError('Paid amount cannot be more than the bill total.');
      }
      pendingAmount = 0;
      return;
    }

    _paidExceedsTotal = false;
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
      _showError('Enter the item name.');
      return;
    }

    final price = double.tryParse(itemPriceCtrl.text.trim()) ?? 0;
    final qty = int.tryParse(itemQtyCtrl.text.trim()) ?? 1;

    if (price <= 0) {
      _showError('Enter a price greater than zero.');
      return;
    }

    if (qty <= 0) {
      _showError('Enter a quantity of at least 1.');
      return;
    }

    final products = _currentProducts();

    double? gstPercent = 0;

    // Product selected from catalog
    if (selectedProductId != null) {
      final product = products.firstWhere((p) => p.id == selectedProductId);

      if (qty > product.stock) {
        _showError('Only ${product.stock} left in stock.');
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

    final line = {
      "productId": selectedProductId ?? 0,
      "name": itemNameCtrl.text.trim(),
      "price": price,
      "quantity": qty,
      "barcode": itemBarCodeCtrl.text.trim(),
      "gst_percent": gstPercent,
      "gst_amount": gstAmount,
      "line_subtotal": lineSubtotal,
      "line_total": lineTotal,
    };

    final closeDialog = _lineDialogOpen;
    setState(() {
      final editing = _lineEditor == _BillLineEditor.edit &&
          _selectedLineIndex != null &&
          _selectedLineIndex! >= 0 &&
          _selectedLineIndex! < items.length;
      if (editing) {
        items[_selectedLineIndex!] = line;
      } else {
        items.add(line);
        _selectedLineIndex = items.length - 1;
      }

      calculateAmounts(context);
      _clearItemFields();
      _lineEditor = _BillLineEditor.hidden;
      if (closeDialog) _lineDialogOpen = false;
    });
    if (closeDialog && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _clearItemFields() {
    itemNameCtrl.clear();
    itemPriceCtrl.clear();
    itemQtyCtrl.text = "1";
    itemBarCodeCtrl.clear();
    productGSTCtrl.clear();
    itemSearchQuery = "";
    selectedProductId = null;
  }

  void _beginManualLine() {
    _clearItemFields();
    setState(() => _lineEditor = _BillLineEditor.manual);
    _presentLineDialog(focusItem: true);
  }

  void _beginCatalogLine() {
    setState(() {
      itemSearchQuery = "";
      _catalogIndex = 0;
      _lineEditor = _BillLineEditor.catalog;
    });
    _presentLineDialog();
  }

  void _beginEditLine() {
    final index = _selectedLineIndex;
    if (index == null || index < 0 || index >= items.length) {
      _showError('Select an item before editing.');
      return;
    }

    final item = items[index];
    itemNameCtrl.text = item["name"]?.toString() ?? "";
    itemPriceCtrl.text = item["price"].toString();
    itemQtyCtrl.text = item["quantity"].toString();
    itemBarCodeCtrl.text = item["barcode"]?.toString() ?? "";
    productGSTCtrl.text = "${item["gst_percent"] ?? 0}";
    final productId = item["productId"];
    selectedProductId = productId is int && productId > 0 ? productId : null;
    itemSearchQuery = "";
    setState(() => _lineEditor = _BillLineEditor.edit);
    _presentLineDialog(focusItem: true);
  }

  Future<void> _presentLineDialog({bool focusItem = false}) async {
    if (_lineDialogOpen || !mounted) return;
    _lineDialogOpen = true;
    if (focusItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _itemFocus.requestFocus();
      });
    }
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final productsAsync = ref.watch(productProvider);
            return ValueListenableBuilder<int>(
              valueListenable: _uiTick,
              builder: (_, __, ___) {
                final products =
                    productsAsync.asData?.value ?? <ProductModel>[];
                return _lineDialog(dialogContext, products, productsAsync);
              },
            );
          },
        );
      },
    );
    if (!mounted) return;
    _lineDialogOpen = false;
    if (_lineEditor != _BillLineEditor.hidden) {
      setState(() => _lineEditor = _BillLineEditor.hidden);
    }
  }

  void _deleteSelectedLine() {
    final index = _selectedLineIndex;
    if (index == null || index < 0 || index >= items.length) {
      _showError('Select an item before deleting.');
      return;
    }

    setState(() {
      items.removeAt(index);
      _selectedLineIndex =
          items.isEmpty ? null : index.clamp(0, items.length - 1);
      if (_lineEditor == _BillLineEditor.edit) {
        _lineEditor = _BillLineEditor.hidden;
        _clearItemFields();
      }
      calculateAmounts(context);
    });
    if (items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tableFocus.requestFocus();
      });
    }
  }

  bool _productMatchesQuery(ProductModel product, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final barcode = (product.barcode ?? '').toLowerCase();
    if (product.name.toLowerCase().contains(q) || barcode.contains(q)) {
      return true;
    }

    final digits = q.replaceAll(RegExp(r'[^0-9.]'), '');
    if (digits.isEmpty) return false;
    final plain = AppFormatters.plain(product.price).toLowerCase();
    return product.price.toString().contains(digits) ||
        plain.contains(q) ||
        plain.replaceAll(',', '').contains(digits) ||
        AppFormatters.currency(product.price).toLowerCase().contains(q);
  }

  void _addCatalogProduct(ProductModel product) {
    if (product.stock <= 0) {
      _showError('This product is out of stock.');
      return;
    }

    final id = product.id ?? 0;
    final qty = (_catalogQty[id] ?? 1).clamp(1, product.stock).toInt();

    final gstPercent = product.gst_percent?.toDouble() ?? 0;
    final lineSubtotal = product.price * qty;
    final gstAmount = lineSubtotal * gstPercent / 100;
    final closeDialog = _lineDialogOpen;

    setState(() {
      items.add({
        "productId": id,
        "name": product.name,
        "price": product.price,
        "quantity": qty,
        "barcode": product.barcode?.trim() ?? "",
        "gst_percent": gstPercent,
        "gst_amount": gstAmount,
        "line_subtotal": lineSubtotal,
        "line_total": lineSubtotal + gstAmount,
      });
      _selectedLineIndex = items.length - 1;
      _catalogQty[id] = 1;
      calculateAmounts(context);
      if (closeDialog) {
        _lineDialogOpen = false;
        _lineEditor = _BillLineEditor.hidden;
      }
    });
    if (closeDialog && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _changeCatalogQty(ProductModel product, int delta) {
    if (product.stock <= 0) return;
    final id = product.id ?? 0;
    final current = _catalogQty[id] ?? 1;
    final next = (current + delta).clamp(1, product.stock).toInt();
    setState(() => _catalogQty[id] = next);
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

  /// Clears customer, cart, paid amount, and item-entry fields after a
  /// successful bill (called when user returns from the receipt screen).
  void _resetBillForm() {
    _BillDraftStore.clear();
    _billSaved = false;
    setState(() {
      selectedCustomer = null;
      selectedCustomerId = null;
      customerNameCtrl.clear();
      _newCustomerPhoneCtrl.clear();
      _newCustomerGender = null;

      items = [];
      totalAmount = 0;
      pendingAmount = 0;
      subtotalAmount = 0;
      totalGstAmount = 0;
      paidCtrl.clear();
      _paidExceedsTotal = false;
      _paidManuallyEdited = false;
      _billWithoutSavingCustomer = false;
      _skippedCustomerBecauseNoPhone = false;
      _unsavedBillCustomerName = null;

      itemNameCtrl.clear();
      itemPriceCtrl.clear();
      itemQtyCtrl.text = "1";
      itemBarCodeCtrl.clear();
      productGSTCtrl.clear();
      itemSearchQuery = "";
      selectedProductId = null;
      _selectedLineIndex = null;
      _lineEditor = _BillLineEditor.hidden;
    });
  }

  String _errorText(Object error) {
    var text = error.toString().trim();
    text = text.replaceFirst(RegExp(r'^(?:Exception:\s*)+'), '').trim();
    final fromBody = _messageFromBody(text);
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;
    return text.isEmpty ? 'Something went wrong' : text;
  }

  String? _messageFromBody(String text) {
    if (text.startsWith('{') || text.startsWith('[')) {
      try {
        final pulled = _messageFromDynamic(jsonDecode(text));
        if (pulled != null && pulled.isNotEmpty) return pulled;
      } catch (_) {}
    }
    final match = RegExp(
      r'''["']?(?:message|msg|detail|error)["']?\s*[:=]\s*["']?([^"',}\]]+)''',
      caseSensitive: false,
    ).firstMatch(text);
    final picked = match?.group(1)?.trim();
    if (picked == null || picked.isEmpty) return null;
    if (picked.startsWith('{') || picked.startsWith('[')) return null;
    return picked;
  }

  String? _messageFromDynamic(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is List) {
      return _joinMessages(value.map(_messageFromDynamic));
    }
    if (value is Map) {
      return _joinMessages([
        for (final key in ['message', 'msg', 'detail', 'error', 'reason'])
          if (value.containsKey(key)) _messageFromDynamic(value[key]),
      ]);
    }
    return null;
  }

  String? _joinMessages(Iterable<String?> parts) {
    final unique = <String>[];
    for (final part in parts) {
      final trimmed = part?.trim() ?? '';
      if (trimmed.isEmpty) continue;
      for (final line in trimmed.split('\n')) {
        final piece = line.trim();
        if (piece.isEmpty) continue;
        final exists = unique.any(
          (item) => item.toLowerCase() == piece.toLowerCase(),
        );
        if (!exists) unique.add(piece);
      }
    }
    if (unique.isEmpty) return null;
    return unique.join('\n');
  }

  bool _isCustomerLimitError(String message) {
    final text = message.toLowerCase();
    return text.contains('limit') ||
        text.contains('maximum') ||
        text.contains('max customer') ||
        text.contains('quota');
  }

  bool _isPhoneRequiredError(String message) {
    final text = message.toLowerCase();
    final aboutNumber = text.contains('phone') ||
        text.contains('mobile') ||
        text.contains('number');
    final required = text.contains('required') ||
        text.contains('mandatory') ||
        text.contains('must') ||
        text.contains('missing');
    return aboutNumber && required;
  }

  void _showError(String message) {
    if (!mounted) return;
    CustomDialog.showErrorSnack(context, _friendlyMessage(message));
  }

  void _showApiNotice(String raw) {
    if (!mounted) return;
    final notice = _apiNotice(raw);
    CustomDialog.showNotice(
      context: context,
      title: notice.$1,
      message: notice.$2,
    );
  }

  (String, String) _apiNotice(String raw) {
    final cleaned = _cleanErrorText(raw);
    final lower = cleaned.toLowerCase();
    if (_isCustomerLimitError(lower)) {
      return (
        'Limit reached',
        'Customer creation limit reached. Please contact admin.',
      );
    }
    if (lower.contains('customer not found') ||
        lower.contains('not found for this business')) {
      return (
        'Customer not saved',
        'This customer is not saved for your business. Please contact admin.',
      );
    }
    if (_isOnlyPhoneRequired(lower)) {
      return (
        'Mobile number needed',
        'A mobile number is required to save this customer.',
      );
    }
    if (_isOnlyConnection(lower)) {
      return (
        'No internet',
        'Check your connection and try again.',
      );
    }
    if (_isOnlySession(lower)) {
      return (
        'Session expired',
        'Please log in again.',
      );
    }
    final plain = _plainApiLine(cleaned);
    if (plain == null) {
      return (
        'Could not create bill',
        'Something went wrong. Please try again.',
      );
    }
    return ('Could not create bill', plain);
  }

  String? _plainApiLine(String cleaned) {
    final lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_looksTechnical(line))
        .toList();
    if (lines.isEmpty) return null;
    var text = lines.first;
    if (text.length > 140) text = '${text.substring(0, 137).trim()}...';
    return text;
  }

  bool _looksTechnical(String line) {
    final lower = line.toLowerCase();
    return lower.contains('_') ||
        lower.contains('exception') ||
        lower.contains('traceback') ||
        lower.contains('null') ||
        lower.contains('status') ||
        lower.contains('customer_id') ||
        lower.contains('not found for this business') ||
        line.contains('{') ||
        line.contains('[');
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    CustomDialog.showSuccessSnack(context, _friendlyMessage(message));
  }

  String _billCreatedMessage() {
    final who = _unsavedBillCustomerName ?? 'this customer';
    if (_skippedCustomerBecauseNoPhone) {
      return 'Bill created for $who. A mobile number is required to save this customer.';
    }
    if (_billWithoutSavingCustomer) {
      return 'Bill created for $who. Customer creation limit reached. Please contact admin.';
    }
    return 'Bill created successfully.';
  }

  String _friendlyMessage(String raw) {
    final cleaned = _cleanErrorText(raw);
    final lower = cleaned.toLowerCase();
    if (lower.isEmpty || lower == 'null' || _isOnlyTechnical(lower)) {
      return 'Something went wrong. Please try again.';
    }
    if (lower.startsWith('bill created')) return cleaned;
    if (_isOnlyPhoneRequired(lower)) {
      return 'A mobile number is required to save this customer. The bill will still be created.';
    }
    if (_isOnlyConnection(lower)) {
      return 'No internet connection. Check your network and try again.';
    }
    if (_isOnlySession(lower)) {
      return 'Your session has expired. Please log in again.';
    }
    return cleaned;
  }

  String _cleanErrorText(String raw) {
    var text = raw.trim();
    text = text.replaceFirst(RegExp(r'^(?:Exception:\s*)+', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'\bSocketException\b:?\s*', caseSensitive: false), '');
    text = text.replaceAll(
      RegExp(
        r'\b(?:https?|http|status(?:\s*code)?|error(?:\s*code)?|code)\s*[:#-]?\s*[1-5]\d{2}\b',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'[\(\[\{]\s*[1-5]\d{2}\s*[\)\]\}]'), '');
    text = text.replaceAll(
      RegExp(
        r'\b(?:internal server error|bad request|unprocessable entity|http error)\b',
        caseSensitive: false,
      ),
      '',
    );
    final lines = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s{2,}'), ' ').trim())
        .map((line) => line.replaceAll(RegExp(r'^[\s\-:.,|]+|[\s\-:.,|]+$'), ''))
        .where((line) => line.isNotEmpty)
        .where((line) => !_isOnlyTechnical(line.toLowerCase()))
        .toList();
    final unique = <String>[];
    for (final line in lines) {
      final exists = unique.any(
        (item) => item.toLowerCase() == line.toLowerCase(),
      );
      if (!exists) unique.add(line);
    }
    return unique.join('\n');
  }

  bool _isOnlyTechnical(String lower) {
    final letters = lower.replaceAll(RegExp(r'[^a-z]'), '');
    if (letters.isEmpty) return true;
    const technical = {
      'error',
      'failed',
      'failedtocreatepurchase',
      'failedtoaddcustomer',
      'servererror',
      'null',
      'exception',
      'badrequest',
      'internalservererror',
    };
    return technical.contains(letters);
  }

  bool _isOnlyPhoneRequired(String lower) {
    return _isPhoneRequiredError(lower) &&
        !lower.contains('customer not found') &&
        !lower.contains('limit') &&
        !lower.contains('quota');
  }

  bool _isOnlyConnection(String lower) {
    final aboutLink = lower.contains('socket') ||
        lower.contains('failed host lookup') ||
        lower.contains('no internet');
    if (!aboutLink) return false;
    return !lower.contains('customer') && !lower.contains('limit');
  }

  bool _isOnlySession(String lower) {
    final aboutSession = lower.contains('session expired') ||
        lower.contains('unauthorized') ||
        lower.contains('login again');
    if (!aboutSession) return false;
    return !lower.contains('customer') && !lower.contains('limit');
  }

  /// The new customer is not saved. The bill still goes through in their
  /// name, linked to the existing walk-in customer record when one exists.
  bool _continueBillWithoutNewCustomer(
    String name,
    String phone, {
    bool missingPhone = false,
  }) {
    final walkIn = customers
        .where(
          (customer) =>
              customer.name.trim().toLowerCase() ==
              _unnamedCustomerName.toLowerCase(),
        )
        .toList();
    final displayName = _resolvedCustomerName(name, phone);
    final shown = phone.isNotEmpty &&
            displayName.toLowerCase() != phone.toLowerCase()
        ? '$displayName ($phone)'
        : displayName;

    if (walkIn.isEmpty) return false;

    setState(() {
      selectedCustomer = walkIn.last;
      selectedCustomerId = walkIn.last.id;
      _billWithoutSavingCustomer = true;
      _skippedCustomerBecauseNoPhone = missingPhone;
      _unsavedBillCustomerName = shown;
    });
    return true;
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
      gender: _newCustomerGender ?? '',
      fcmToken: '',
      pendingAmount: pendingAmount.toString(),
    );

    await _fetchCustomers();

    final named = customers.where((customer) {
      final sameName =
          customer.name.trim().toLowerCase() == name.trim().toLowerCase();
      if (!sameName) return false;
      if (phone.isEmpty) return customer.phone.trim().isEmpty;
      return customer.phone.trim() == phone;
    }).toList();
    if (named.isNotEmpty) return named.last;

    if (phone.isNotEmpty) {
      final byPhone =
          customers.where((customer) => customer.phone.trim() == phone).toList();
      if (byPhone.isNotEmpty) return byPhone.last;
    }

    return customers.last;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : isDesktop
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    children: [
                      _buildCustomerBar(theme),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _buildItemsWorkspace(
                          theme,
                          products,
                          productsAsync,
                          fill: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildPosTotalsBar(context, theme),
                    ],
                  ),
                )
              : _buildBillContent(
                  context,
                  theme,
                  products,
                  productsAsync,
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
    double? height,
    Key? measureKey,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: height != null ? Alignment.topLeft : null,
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
      child: KeyedSubtree(
        key: measureKey,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    bool compact = false,
  }) {
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 14),
      child: Row(
        children: [
          Container(
            height: compact ? 22 : 40,
            width: compact ? 22 : 40,
            decoration: BoxDecoration(
              color: _softPrimary(theme),
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
            ),
            child: Icon(icon, color: cs.primary, size: compact ? 14 : 20),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                if (!compact) ...[
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
    bool dense = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 1 : 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: dense ? 12 : 13,
                color: _muted(theme),
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: dense ? (bold ? 13 : 12) : (bold ? 15 : 13),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Desktop summary panel ────────────────────────────────────────────────

  Widget _buildCreateBillButton(
    BuildContext context,
    ThemeData theme, {
    required double height,
    required double width,
    required double fontSize,
    required FontWeight fontWeight,
    required double radius,
    required double spinner,
  }) {
    final cs = theme.colorScheme;
    return Focus(
      focusNode: _createBillFocus,
      onKeyEvent: _onCreateBillKey,
      descendantsAreFocusable: false,
      child: ListenableBuilder(
        listenable: _createBillFocus,
        builder: (context, _) {
          final armed = _createBillFocus.hasPrimaryFocus;
          return SizedBox(
            height: height,
            width: width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: armed ? const Color(0xFF1B8F4A) : cs.primary,
                foregroundColor: armed ? Colors.white : cs.onPrimary,
                disabledBackgroundColor: cs.primary.withValues(alpha: 0.55),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              onPressed: isCreating ? null : () => _createBill(this.context),
              child: isCreating
                  ? SizedBox(
                      height: spinner,
                      width: spinner,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      'Create Bill',
                      style: TextStyle(
                        fontWeight: fontWeight,
                        fontSize: fontSize,
                        color: armed ? Colors.white : cs.onPrimary,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosTotalsBar(BuildContext context, ThemeData theme) {
    final cs = theme.colorScheme;
    final paid = double.tryParse(paidCtrl.text) ?? 0;

    Widget metric(String label, String value, Color valueColor) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: _muted(theme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: valueColor,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line(theme)),
      ),
      child: Row(
        children: [
          Expanded(
            child: metric(
              'Subtotal',
              AppFormatters.currency(subtotalAmount),
              cs.onSurface,
            ),
          ),
          Expanded(
            child: metric(
              'GST',
              AppFormatters.currency(totalGstAmount),
              AppColors.credit,
            ),
          ),
          Expanded(
            child: metric(
              'Paid',
              AppFormatters.currency(paid),
              cs.primary,
            ),
          ),
          Expanded(
            child: metric(
              'Pending',
              AppFormatters.currency(pendingAmount),
              pendingAmount > 0 ? AppColors.warning : AppColors.credit,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 176,
            height: 48,
            child: _arrowField(
              node: _paidFocus,
              child: TextField(
                controller: paidCtrl,
                focusNode: _paidFocus,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 16, height: 1.1, fontWeight: FontWeight.w700),
                textInputAction: TextInputAction.done,
                onEditingComplete: _paidFocus.unfocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  _paidManuallyEdited = true;
                  setState(() => calculateAmounts(context));
                },
                decoration: _inputDecoration(
                  theme,
                  '0.00',
                  'Paid amount',
                  dense: true,
                ).copyWith(
                  constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    maxWidth: 32,
                    minHeight: 48,
                    maxHeight: 48,
                  ),
                  prefixIcon: SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        '₹',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            height: 48,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        height: 1,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(totalAmount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildCreateBillButton(
            context,
            theme,
            height: 48,
            width: 148,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            radius: 12,
            spinner: 16,
          ),
        ],
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
            _buildCreateBillButton(
              context,
              theme,
              height: 46,
              width: 148,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              radius: 14,
              spinner: 18,
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
  ) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return SingleChildScrollView(
      primary: false,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        isDesktop ? 20 : 120,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerSelector(theme),
            const SizedBox(height: 14),
            _buildItemsWorkspace(theme, products, productsAsync),
            if (!isDesktop) ...[
              const SizedBox(height: 14),
              _sectionCard(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      theme: theme,
                      title: 'Payment',
                      subtitle: 'How much did the customer pay?',
                      icon: Icons.payments_outlined,
                    ),
                    _arrowField(
                      node: _paidFocus,
                      child: SizedBox(
                        height: 46,
                        child: TextField(
                      controller: paidCtrl,
                      focusNode: _paidFocus,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 14, height: 1.1),
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _paidFocus.unfocus,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        _paidManuallyEdited = true;
                        setState(() => calculateAmounts(context));
                      },
                      decoration: _inputDecoration(theme, '0.00', 'Paid amount')
                          .copyWith(
                        prefixIcon: SizedBox(
                          width: 28,
                          child: Center(
                            child: Text(
                              '₹',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
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
    );
  }

  Widget _dialogHeading(BuildContext dialogContext, String title) {
    final cs = Theme.of(dialogContext).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(dialogContext).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _lineDialog(
    BuildContext dialogContext,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync,
  ) {
    final theme = Theme.of(dialogContext);
    final cs = theme.colorScheme;
    final catalog = _lineEditor == _BillLineEditor.catalog;
    final size = MediaQuery.sizeOf(dialogContext);
    final width =
        (size.width - 48).clamp(320.0, catalog ? 760.0 : 520.0).toDouble();

    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: width,
        height: catalog
            ? (size.height * 0.72).clamp(420.0, 640.0).toDouble()
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: catalog
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dialogHeading(dialogContext, 'Add item from list'),
                    TextField(
                      onChanged: (value) =>
                          setState(() => itemSearchQuery = value),
                      decoration: _inputDecoration(
                        theme,
                        'Search name or price',
                        'Catalog',
                        dense: true,
                      ).copyWith(
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: cs.primary,
                          size: 18,
                        ),
                        isDense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: KeyedSubtree(
                        key: _catalogKey,
                        child: _buildCatalogList(
                          theme,
                          products,
                          productsAsync,
                          expand: true,
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeading(
                        dialogContext,
                        _lineEditor == _BillLineEditor.edit
                            ? 'Edit line'
                            : 'Add new line',
                      ),
                      _buildManualLineFields(theme, products, productsAsync),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildManualLineFields(
    ThemeData theme,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync,
  ) {
    final cs = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _arrowField(
          node: _itemFocus,
          child: TextField(
            controller: itemNameCtrl,
            focusNode: _itemFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _moveTo(_priceFocus),
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
              dense: true,
            ).copyWith(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.primary,
                size: 18,
              ),
              suffixIcon: selectedProductId != null
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.credit,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
        if (itemSearchQuery.trim().isNotEmpty && selectedProductId == null)
          _buildProductSuggestions(theme, products, productsAsync),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _arrowField(
                node: _priceFocus,
                child: TextField(
                  controller: itemPriceCtrl,
                  focusNode: _priceFocus,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13, height: 1.1),
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _moveTo(_qtyFocus),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  readOnly: selectedProductId != null,
                  decoration: _lineBox(
                    theme,
                    '0.00',
                    'Price',
                    fill: true,
                    icon: Icons.currency_rupee,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _arrowField(
                node: _qtyFocus,
                child: TextField(
                  controller: itemQtyCtrl,
                  focusNode: _qtyFocus,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13, height: 1.1),
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _moveTo(_barcodeFocus),
                  keyboardType: TextInputType.number,
                  decoration: _lineBox(
                    theme,
                    '1',
                    'Qty',
                    fill: true,
                    icon: Icons.numbers,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _arrowField(
                node: _barcodeFocus,
                child: TextField(
                  controller: itemBarCodeCtrl,
                  focusNode: _barcodeFocus,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13, height: 1.1),
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _moveTo(_gstFocus),
                  readOnly: selectedProductId != null,
                  decoration: _lineBox(
                    theme,
                    'Optional',
                    'Barcode',
                    fill: true,
                    icon: Icons.qr_code_2_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _arrowField(
                node: _gstFocus,
                child: TextField(
                  controller: productGSTCtrl,
                  focusNode: _gstFocus,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13, height: 1.1),
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _moveTo(_paidFocus),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  readOnly: selectedProductId != null,
                  decoration: _lineBox(
                    theme,
                    '0',
                    'GST %',
                    fill: true,
                    icon: Icons.percent_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 168,
            height: 34,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: addItem,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                _lineEditor == _BillLineEditor.edit ? 'Update line' : 'Add to bill',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsWorkspace(
    ThemeData theme,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync, {
    bool fill = false,
  }) {
    final cs = theme.colorScheme;

    final card = _sectionCard(
      theme: theme,
      padding: fill
          ? const EdgeInsets.fromLTRB(6, 4, 6, 4)
          : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            theme: theme,
            title: 'Items',
            subtitle: 'Add a line, then review it in the table',
            icon: Icons.receipt_long_outlined,
            compact: fill,
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: fill ? 8 : 10,
                vertical: fill ? 2 : 5,
              ),
              decoration: BoxDecoration(
                color: _softPrimary(theme),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Line count  ${items.length}',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: fill ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Wrap(
            spacing: fill ? 6 : 8,
            runSpacing: fill ? 4 : 8,
            children: [
              _lineToolButton(
                theme,
                icon: Icons.add_rounded,
                label: 'Add new line',
                compact: fill,
                active: _lineEditor == _BillLineEditor.manual,
                onTap: _beginManualLine,
              ),
              _lineToolButton(
                theme,
                icon: Icons.playlist_add_rounded,
                label: 'Add item from list',
                compact: fill,
                active: _lineEditor == _BillLineEditor.catalog,
                onTap: _beginCatalogLine,
              ),
              _lineToolButton(
                theme,
                icon: Icons.edit_outlined,
                label: 'Edit selected line',
                compact: fill,
                active: _lineEditor == _BillLineEditor.edit,
                onTap: _beginEditLine,
              ),
            ],
          ),
          SizedBox(height: fill ? 8 : 14),
          if (fill)
            Expanded(
              child: _buildBillTable(theme, expand: true),
            )
          else
            _buildBillTable(theme),
        ],
      ),
    );
    return fill ? SizedBox.expand(child: card) : card;
  }

  Widget _lineToolButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    bool compact = false,
  }) {
    final cs = theme.colorScheme;
    final color = cs.primary;

    return Material(
      color: active ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 14 : 16, color: active ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillTable(ThemeData theme, {bool expand = false}) {
    final cs = theme.colorScheme;
    _syncRowKeys();
    const columns = [
      _BillColumn('SKU', 2),
      _BillColumn('Item', 4),
      _BillColumn('Qty', 1, align: TextAlign.center),
      _BillColumn('Price', 2, align: TextAlign.right),
      _BillColumn('GST %', 1, align: TextAlign.center),
      _BillColumn('GST', 2, align: TextAlign.right),
      _BillColumn('Total', 2, align: TextAlign.right),
    ];
    const rowHeight = 32.0;
    const deleteWidth = 40.0;

    Widget deleteSlot(int index, bool selected) {
      if (!selected) return const SizedBox(width: deleteWidth);
      return SizedBox(
        width: deleteWidth,
        child: Focus(
          focusNode: _deleteFocus,
          onKeyEvent: _onDeleteKey,
          child: ListenableBuilder(
            listenable: _deleteFocus,
            builder: (context, _) {
              final armed = _deleteFocus.hasPrimaryFocus;
              return Center(
                child: Tooltip(
                  message: 'Delete line',
                  child: Material(
                    color: armed ? const Color(0xFFC62828) : const Color(0xFFFFEBEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                      side: BorderSide(
                        color: armed ? const Color(0xFFC62828) : const Color(0xFFFFCDD2),
                      ),
                    ),
                    child: InkWell(
                      onTap: _deleteSelectedLine,
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox(
                        width: 26,
                        height: 22,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 15,
                          color: armed ? Colors.white : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    Widget cell(String text, int flex, {bool header = false, bool strong = false, Color? color, TextAlign align = TextAlign.left}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            fontSize: header ? 10 : 11.5,
            fontWeight: header || strong ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (header ? _muted(theme) : cs.onSurface),
          ),
        ),
      );
    }

    Widget line(List<Widget> children, {Color? color, bool selected = false}) {
      return SizedBox(
        height: rowHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border(
              bottom: BorderSide(color: _line(theme)),
              left: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 10),
            child: Row(children: children),
          ),
        ),
      );
    }

    Widget dataRow(int index) {
      final item = items[index];
      final selected = _selectedLineIndex == index;
      final gstPercent = item['gst_percent'] ?? 0;
      final gstAmount = (item['gst_amount'] as num?)?.toDouble() ?? 0;
      final lineTotal = (item['line_total'] as num?)?.toDouble() ??
          ((item['line_subtotal'] as num?)?.toDouble() ?? 0) + gstAmount;
      final barcode = (item['barcode']?.toString() ?? '').trim();

      return GestureDetector(
        key: _rowKeys[index],
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusTableRow(index),
        child: line(
          [
            cell(barcode.isEmpty ? '—' : barcode, 2),
            cell(item['name']?.toString() ?? '', 4, strong: true),
            cell('${item['quantity']}', 1, align: TextAlign.center),
            cell(AppFormatters.currencyOf(item['price']), 2, align: TextAlign.right),
            cell('$gstPercent%', 1, align: TextAlign.center),
            cell(
              AppFormatters.currency(gstAmount),
              2,
              align: TextAlign.right,
              color: AppColors.credit,
            ),
            cell(
              AppFormatters.currency(lineTotal),
              2,
              strong: true,
              align: TextAlign.right,
            ),
            deleteSlot(index, selected),
          ],
          selected: selected,
          color: selected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
        ),
      );
    }

    Widget filledRows(double minHeight) {
      final used = items.length * rowHeight;
      final extra = minHeight > used ? minHeight - used : 0.0;
      return Column(
        children: [
          for (var index = 0; index < items.length; index++) dataRow(index),
          if (extra > 0)
            SizedBox(
              height: extra,
              width: double.infinity,
              child: CustomPaint(
                painter: _BillGridPainter(
                  lineColor: _line(theme),
                  rowHeight: rowHeight,
                  fill: cs.surface,
                ),
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No lines yet. Use Add new line or Add item from list.',
                          style: TextStyle(fontSize: 12, color: _muted(theme)),
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ),
        ],
      );
    }

    final header = ColoredBox(
      color: const Color(0xffF3F5F8),
      child: line(
        [
          for (final column in columns)
            cell(column.label, column.flex, header: true, align: column.align),
          const SizedBox(width: deleteWidth),
        ],
        color: const Color(0xffF3F5F8),
      ),
    );

    Widget table(Widget content) {
      return Focus(
        focusNode: _tableFocus,
        onKeyEvent: _onTableArrow,
        child: ListenableBuilder(
          listenable: _tableFocus,
          builder: (context, child) {
            final focused = _tableFocus.hasFocus;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: focused ? cs.primary : _line(theme),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: child,
              ),
            );
          },
          child: content,
        ),
      );
    }

    if (!expand) {
      return table(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No lines yet. Use Add new line or Add item from list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _muted(theme)),
                ),
              )
            else
              ...[for (var index = 0; index < items.length; index++) dataRow(index)],
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: table(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    primary: false,
                    child: filledRows(constraints.maxHeight),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogQtyStepper(
    ThemeData theme,
    ProductModel product,
    bool outOfStock,
  ) {
    final cs = theme.colorScheme;
    final qty = _catalogQty[product.id ?? 0] ?? 1;
    final canDecrease = !outOfStock && qty > 1;
    final canIncrease = !outOfStock && qty < product.stock;

    Widget button(IconData icon, bool enabled, VoidCallback onTap) {
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 22,
          width: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? cs.primary.withValues(alpha: 0.1)
                : theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: enabled ? cs.primary : _muted(theme),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {},
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove, canDecrease, () => _changeCatalogQty(product, -1)),
        SizedBox(
          width: 22,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ),
        button(Icons.add, canIncrease, () => _changeCatalogQty(product, 1)),
      ],
      ),
    );
  }

  Widget _buildCatalogList(
    ThemeData theme,
    List<ProductModel> products,
    AsyncValue<List<ProductModel>> productsAsync, {
    bool expand = false,
  }) {
    final cs = theme.colorScheme;
    if (productsAsync.isLoading && products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final query = itemSearchQuery.trim();
    final matches = products
        .where((product) => _productMatchesQuery(product, query))
        .toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          'No products found',
          style: TextStyle(fontSize: 12, color: _muted(theme)),
        ),
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final listHeight = expand
        ? double.infinity
        : (screenHeight * 0.58).clamp(280.0, 640.0);
    _syncCatalogKeys(matches.length);
    final highlighted = _catalogIndex;

    return Padding(
      padding: EdgeInsets.only(top: expand ? 0 : 10),
      child: Focus(
        focusNode: _catalogFocus,
        onKeyEvent: _onCatalogArrow,
        onFocusChange: (_) {
          if (mounted) setState(() {});
        },
        child: Container(
        height: listHeight,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _catalogFocus.hasFocus ? cs.primary : _line(theme),
            width: _catalogFocus.hasFocus ? 1.6 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            primary: false,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: matches.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: _line(theme),
            ),
            itemBuilder: (_, index) {
              final product = matches[index];
              final outOfStock = product.stock <= 0;
              final selected = highlighted == index;
              return InkWell(
                key: _catalogRowKeys[index],
                onTap: () {
                  _focusCatalogRow(index);
                  if (!outOfStock) _addCatalogProduct(product);
                },
                child: Opacity(
                  opacity: outOfStock ? 0.45 : 1,
                  child: Container(
                    color: selected
                        ? cs.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: expand ? 8 : 14,
                      vertical: expand ? 4 : 11,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: expand ? 12 : 13,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          outOfStock
                              ? 'Out of stock'
                              : 'Stock ${product.stock}',
                          style: TextStyle(
                            fontSize: expand ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: outOfStock
                                ? Colors.red.shade600
                                : _muted(theme),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: expand ? 64 : 72,
                          child: Text(
                            AppFormatters.currency(product.price),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: expand ? 12 : 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _catalogQtyStepper(theme, product, outOfStock),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
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

    final query = itemSearchQuery.trim();
    final matches = products
        .where((product) => _productMatchesQuery(product, query))
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
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 112),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line(theme)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: matches.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: _line(theme),
          ),
          itemBuilder: (_, i) {
            final product = matches[i];
            final outOfStock = product.stock <= 0;

            return InkWell(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          outOfStock ? 'Out' : 'Stock ${product.stock}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: outOfStock ? Colors.red : _muted(theme),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          AppFormatters.currency(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
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

  Widget _buildCustomerBar(ThemeData theme) {
    final cs = theme.colorScheme;
    final matches = selectedCustomerId == null
        ? _matchingCustomers()
        : <CustomerResponseModel>[];
    final searching =
        _typedCustomerName.isNotEmpty || _typedCustomerPhone.isNotEmpty;
    final open = matches.isNotEmpty;
    if (open != _customerPortal.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (open && !_customerPortal.isShowing) {
          _customerPortal.show();
        } else if (!open && _customerPortal.isShowing) {
          _customerPortal.hide();
        }
      });
    }

    return OverlayPortal(
      controller: _customerPortal,
      overlayChildBuilder: (overlayContext) {
        final overlayTheme = Theme.of(overlayContext);
        final found = selectedCustomerId == null
            ? _matchingCustomers()
            : <CustomerResponseModel>[];
        if (found.isEmpty) return const SizedBox.shrink();
        return CompositedTransformFollower(
          link: _customerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(140, 6),
          child: Align(
            alignment: Alignment.topLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: SizedBox(
              width: 240,
              child: Material(
                elevation: 8,
                color: overlayTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: _line(overlayTheme)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildCustomerList(
                    overlayTheme,
                    found,
                    maxHeight: 84,
                    snug: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _customerLink,
        child: _sectionCard(
              theme: theme,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: cs.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                          height: 42,
                          child: _arrowField(
                            node: _nameFocus,
                            child: TextField(
                              controller: customerNameCtrl,
                              focusNode: _nameFocus,
                              textAlignVertical: TextAlignVertical.center,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => _moveTo(_phoneFocus),
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => _onCustomerFieldChanged(),
                              style: const TextStyle(fontSize: 14, height: 1.1, fontWeight: FontWeight.w600),
                              decoration: _inputDecoration(
                                theme,
                                'Search or enter name',
                                'Name',
                                dense: true,
                              ).copyWith(
                                constraints: const BoxConstraints(
                                  minHeight: 42,
                                  maxHeight: 42,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 34,
                                  maxWidth: 34,
                                  minHeight: 42,
                                  maxHeight: 42,
                                ),
                                hintStyle: TextStyle(fontSize: 14, color: _muted(theme)),
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: cs.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: SizedBox(
                          height: 42,
                          child: _arrowField(
                            node: _phoneFocus,
                            child: TextField(
                              controller: _newCustomerPhoneCtrl,
                              focusNode: _phoneFocus,
                              textAlignVertical: TextAlignVertical.center,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => _moveTo(_itemFocus),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              onChanged: (_) => _onCustomerFieldChanged(),
                              style: const TextStyle(fontSize: 14, height: 1.1, fontWeight: FontWeight.w600),
                              decoration: _inputDecoration(
                                theme,
                                'Search or enter number',
                                'Number',
                                dense: true,
                              ).copyWith(
                                constraints: const BoxConstraints(
                                  minHeight: 42,
                                  maxHeight: 42,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 34,
                                  maxWidth: 34,
                                  minHeight: 42,
                                  maxHeight: 42,
                                ),
                                hintStyle: TextStyle(fontSize: 14, color: _muted(theme)),
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  color: cs.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildGenderChip(theme, 'male', 'Male', compact: true),
                      const SizedBox(width: 6),
                      _buildGenderChip(theme, 'female', 'Female', compact: true),
                      const SizedBox(width: 6),
                      _buildClearBillButton(theme),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _customerStatusText(searching, matches),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selectedCustomerId != null
                          ? cs.primary
                          : _muted(theme),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildCustomerSelector(
    ThemeData theme, {
    bool compact = false,
    double? height,
    Key? measureKey,
  }) {
    final cs = theme.colorScheme;
    final matches = selectedCustomerId == null ? _matchingCustomers() : <CustomerResponseModel>[];
    final searching = _typedCustomerName.isNotEmpty || _typedCustomerPhone.isNotEmpty;

    return _sectionCard(
      theme: theme,
      height: height,
      padding: compact
          ? const EdgeInsets.fromLTRB(8, 10, 8, 10)
          : const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: measureKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 4 : 14),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, color: cs.primary, size: compact ? 16 : 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _buildGenderChip(theme, 'male', 'Male', compact: compact),
                const SizedBox(width: 6),
                _buildGenderChip(theme, 'female', 'Female', compact: compact),
                const SizedBox(width: 6),
                _buildClearBillButton(theme),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _arrowField(
                  node: _nameFocus,
                  child: TextField(
                    controller: customerNameCtrl,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _moveTo(_phoneFocus),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => _onCustomerFieldChanged(),
                    decoration: _inputDecoration(
                      theme,
                      'Search or enter name',
                      'Name',
                      dense: compact,
                    ).copyWith(
                      prefixIcon: Icon(Icons.badge_outlined, color: cs.primary, size: compact ? 16 : 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _arrowField(
                  node: _phoneFocus,
                  child: TextField(
                    controller: _newCustomerPhoneCtrl,
                    focusNode: _phoneFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _moveTo(_itemFocus),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) => _onCustomerFieldChanged(),
                    decoration: _inputDecoration(
                      theme,
                      'Search or enter number',
                      'Number',
                      dense: compact,
                    ).copyWith(
                      prefixIcon: Icon(Icons.phone_outlined, color: cs.primary, size: compact ? 16 : 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 2 : 6),
          Text(
            _customerStatusText(searching, matches),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selectedCustomerId != null ? cs.primary : _muted(theme),
            ),
          ),
              ],
            ),
          ),
          if (matches.isNotEmpty) ...[
            SizedBox(height: compact ? 4 : 8),
            if (height != null)
              Expanded(
                child: _buildCustomerList(theme, matches, fill: true),
              )
            else
              _buildCustomerList(
                theme,
                matches,
                maxHeight: compact ? 60 : 160,
              ),
          ],
        ],
      ),
    );
  }
  String _customerStatusText(
    bool searching,
    List<CustomerResponseModel> matches,
  ) {
    if (selectedCustomerId != null) {
      return 'This customer is linked to the bill.';
    }
    if (!searching) {
      return 'Name and mobile number are optional.';
    }
    if (_typedCustomerName.isNotEmpty && _typedCustomerPhone.isEmpty) {
      return 'A mobile number is required to save this customer. The bill will still be created.';
    }
    if (matches.isEmpty) {
      return 'New customer. These details are saved with the bill.';
    }
    return 'Customer found. Select one to use it.';
  }

  Widget _buildCustomerList(
    ThemeData theme,
    List<CustomerResponseModel> filteredCustomers, {
    double maxHeight = 250,
    bool fill = false,
    bool snug = false,
  }) {
    final cs = theme.colorScheme;

    final list = ListView.separated(
      shrinkWrap: !fill,
      primary: false,
      padding: EdgeInsets.symmetric(vertical: snug ? 2 : 4),
      physics: const ClampingScrollPhysics(),
      itemCount: filteredCustomers.length,
      separatorBuilder: (_, __) => SizedBox(height: snug ? 2 : 4),
        itemBuilder: (_, i) {
          final customer = filteredCustomers[i];
          final isSelected = selectedCustomerId == customer.id;
          final label = _resolvedCustomerName(customer.name, customer.phone);
          final phone = customer.phone.trim();

          return Material(
            color: isSelected ? _softPrimary(theme) : cs.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() => _selectExistingCustomer(customer));
              },
              child: Container(
                height: snug ? 26 : 34,
                padding: EdgeInsets.symmetric(horizontal: snug ? 8 : 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.primary : _line(theme),
                  ),
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted(theme),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );

    if (fill) return list;
    return ConstrainedBox(
      key: const ValueKey('customer_list'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: list,
    );
  }

  Widget _buildClearBillButton(ThemeData theme) {
    final cs = theme.colorScheme;
    return Focus(
      focusNode: _clearFocus,
      onKeyEvent: _onClearKey,
      descendantsAreFocusable: false,
      child: ListenableBuilder(
        listenable: _clearFocus,
        builder: (context, _) {
          final armed = _clearFocus.hasPrimaryFocus;
          return Tooltip(
            message: 'Clear bill',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _resetBillForm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: armed ? cs.error : cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: armed ? cs.error : _line(theme),
                    width: armed ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: armed ? cs.onError : cs.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: armed ? cs.onError : cs.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderChip(
    ThemeData theme,
    String value,
    String label, {
    bool compact = false,
  }) {
    final isSelected = _newCustomerGender == value;
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _newCustomerGender = isSelected ? null : value;
        });
        _onCustomerFieldChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
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
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 14 : 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? cs.primary : _muted(theme),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _lineBox(
    ThemeData theme,
    String hint,
    String label, {
    required bool fill,
    required IconData icon,
  }) {
    final iconSize = fill ? 16.0 : 18.0;
    return _inputDecoration(theme, hint, label, dense: fill).copyWith(
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: const BoxConstraints(minHeight: 36, maxHeight: 48),
      prefixIcon: Icon(icon, size: iconSize),
      prefixIconConstraints: BoxConstraints(
        minWidth: fill ? 32 : 36,
        maxWidth: fill ? 32 : 36,
        minHeight: 0,
        maxHeight: 48,
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    String hint,
    String label, {
    bool dense = false,
  }) {
    final cs = theme.colorScheme;
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: TextStyle(fontSize: dense ? 12 : 14, color: _muted(theme)),
      labelStyle: TextStyle(fontSize: dense ? 11 : 13, color: _muted(theme)),
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      visualDensity: VisualDensity.standard,
      prefixIconConstraints: BoxConstraints(
        minWidth: dense ? 32 : 40,
        minHeight: dense ? 34 : 46,
        maxHeight: dense ? 34 : 46,
      ),
      constraints: BoxConstraints(
        minHeight: dense ? 34 : 46,
        maxHeight: dense ? 34 : 46,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: dense ? 14 : 16,
        vertical: 0,
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

class _BillGridPainter extends CustomPainter {
  const _BillGridPainter({
    required this.lineColor,
    required this.rowHeight,
    required this.fill,
  });

  final Color lineColor;
  final double rowHeight;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double y = rowHeight; y < size.height; y += rowHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _BillGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.fill != fill;
  }
}
