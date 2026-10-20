import 'dart:convert';

import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/services/business/business_service.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/empty_screen.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/business_models/business_customer_req_model.dart';
import '../../../models/business_models/customer_list_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../services/business/business_access_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/enum_classes.dart';
import '../../../utils/formatters.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  // ---------------------------------------------------------------------------
  // EXISTING CUSTOMER DATA
  // ---------------------------------------------------------------------------

  List<dynamic> customers = [];

  bool isLoading = true;
  bool isAddingCustomer = false;
  bool isImportingCustomers = false;
  final ValueNotifier<_CsvImportProgress> _importProgress =
      ValueNotifier(const _CsvImportProgress());

  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  // ---------------------------------------------------------------------------
  // ADD CUSTOMER FORM
  // ---------------------------------------------------------------------------

  final GlobalKey<FormState> _addCustomerFormKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  String selectedGender = "male";

  String pendingAmount = "0";

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = ref.read(customerProvider).asData?.value;
      if (cached != null) {
        setState(() {
          customers = cached;
          isLoading = false;
        });
      } else {
        _fetchCustomers();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    _importProgress.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // FETCH CUSTOMERS
  // ---------------------------------------------------------------------------

  Future<void> _fetchCustomers() async {
    try {
      setState(() => isLoading = customers.isEmpty);

      ref.invalidate(customerProvider);
      final data = await ref.read(customerProvider.future);

      if (!mounted) return;

      setState(() {
        customers = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());

      CustomDialog.showErrorSnack(context, e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // RESET ADD CUSTOMER FORM
  // ---------------------------------------------------------------------------

  void _resetAddCustomerForm() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();

    selectedGender = "male";
    pendingAmount = "0";

    _addCustomerFormKey.currentState?.reset();
  }

  // ---------------------------------------------------------------------------
  // ADD CUSTOMER - COMMON BACKEND METHOD
  // ---------------------------------------------------------------------------

  Future<void> _addCustomer({
    required BuildContext feedbackContext,
    required bool closeDialog,
  }) async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      CustomDialog.showErrorSnack(feedbackContext, "Customer name required");
      return;
    }

    if (phone.isEmpty) {
      CustomDialog.showErrorSnack(feedbackContext, "Phone number is required");
      return;
    }

    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (phone.length != 10) {
      CustomDialog.showErrorSnack(feedbackContext, "Must be 10 digits");
      return;
    }

    if (!phoneRegex.hasMatch(phone)) {
      CustomDialog.showErrorSnack(feedbackContext, "Invalid Indian number");
      return;
    }

    setState(() {
      isAddingCustomer = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final businessId = prefs.getInt("businessId") ?? 0;
      final token = prefs.getString("token") ?? "";

      await BusinessService().addCustomer(
        name: name,
        phone: phone,
        token: token,
        businessId: businessId,
        email: email,
        gender: selectedGender,
        fcmToken: '',
        pendingAmount: pendingAmount,
      );

      await _fetchCustomers();

      if (!mounted) return;

      setState(() {
        isAddingCustomer = false;
      });

      if (closeDialog) {
        Navigator.pop(feedbackContext);
      }

      _resetAddCustomerForm();

      CustomDialog.showSuccessSnack(context, "Customer added successfully");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAddingCustomer = false;
      });

      CustomDialog.showErrorSnack(
        feedbackContext,
        e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CSV UPLOAD — only up to this business customer limit
  // ---------------------------------------------------------------------------

  Future<void> _showImportCustomersCsv() async {
    if (isImportingCustomers) return;

    final type = ref.read(appTypeProvider);
    final primary = Theme.of(context).colorScheme.primary;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _CustomerCsvUploadDialog(
          title: "Upload ${DashboardText.customer(type)} CSV",
          primary: primary,
          onCancel: () => Navigator.pop(dialogContext),
          onChooseFile: () {
            Navigator.pop(dialogContext);
            _pickAndImportCustomers();
          },
        );
      },
    );
  }

  void _showImportProgressDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _CustomerImportProgressDialog(
          primary: Theme.of(dialogContext).colorScheme.primary,
          progress: _importProgress,
        );
      },
    );
  }

  Future<void> _pickAndImportCustomers() async {
    if (isImportingCustomers) return;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );

    if (!mounted || picked == null || picked.files.isEmpty) return;

    final bytes = picked.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      CustomDialog.showErrorSnack(context, "Could not read the CSV file");
      return;
    }

    final content = utf8.decode(bytes, allowMalformed: true);
    final parsed = _parseCustomerCsv(content);

    if (parsed.error != null) {
      CustomDialog.showErrorSnack(context, parsed.error!);
      return;
    }

    if (parsed.rows.isEmpty) {
      final hasSkips = parsed.invalidRows > 0 || parsed.duplicateRows > 0;
      CustomDialog.showErrorSnack(
        context,
        hasSkips
            ? _csvImportSummary(
                added: 0,
                invalid: parsed.invalidRows,
                duplicate: parsed.duplicateRows,
                failed: 0,
                overLimit: 0,
                maxCustomers: null,
              )
            : "CSV file has no customers",
      );
      return;
    }

    setState(() => isImportingCustomers = true);

    var added = 0;
    var failed = 0;
    var overLimit = 0;
    int? maxCustomers;
    final duplicate = parsed.duplicateRows;
    Object? importError;
    var progressVisible = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getInt("businessId") ?? 0;
      final token = prefs.getString("token") ?? "";
      // Access-control is an admin API. A business owner gets 403 here,
      // so a failed lookup must not block the import.
      try {
        final access = await BusinessAccessService.fetchAccess(businessId);
        maxCustomers = access.maxCustomers;
      } catch (_) {
        maxCustomers = null;
      }

      final knownLimit = maxCustomers;
      var remaining = knownLimit == null
          ? parsed.rows.length
          : knownLimit - customers.length;
      if (remaining < 0) remaining = 0;

      if (remaining == 0) {
        overLimit = parsed.rows.length;
      } else {
        final toAdd = parsed.rows.length > remaining
            ? parsed.rows.sublist(0, remaining)
            : parsed.rows;
        overLimit = parsed.rows.length - toAdd.length;
        String? firstFailure;

        if (toAdd.isNotEmpty && mounted) {
          _importProgress.value = _CsvImportProgress(
            done: 0,
            total: toAdd.length,
            label: "Preparing customers",
          );
          _showImportProgressDialog();
          progressVisible = true;
        }

        for (var index = 0; index < toAdd.length; index++) {
          final row = toAdd[index];
          _importProgress.value = _CsvImportProgress(
            done: index,
            total: toAdd.length,
            label: "Adding ${row.name}",
          );
          try {
            await BusinessService().addCustomer(
              name: row.name,
              phone: row.phone,
              token: token,
              businessId: businessId,
              email: row.email,
              gender: row.gender,
              fcmToken: '',
              pendingAmount: row.pendingAmount,
            );
            added++;
            _importProgress.value = _CsvImportProgress(
              done: index + 1,
              total: toAdd.length,
              label: "Added ${row.name}",
            );
          } catch (e) {
            final message = e.toString().replaceFirst("Exception: ", "");
            final limitReached = _isCustomerLimitError(message);
            if (!limitReached) failed++;
            _importProgress.value = _CsvImportProgress(
              done: added + failed,
              total: toAdd.length,
              label: limitReached ? "Customer limit reached" : row.name,
            );
            if (limitReached) {
              overLimit += toAdd.length - added - failed;
              maxCustomers ??= customers.length + added;
              break;
            }
            firstFailure ??= message;
            if (_isForbiddenError(message)) break;
          }
        }

        if (added == 0 && failed > 0 && firstFailure != null) {
          throw Exception(firstFailure);
        }
      }

      await _fetchCustomers();
    } catch (e) {
      importError = e;
    } finally {
      if (progressVisible && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        setState(() => isImportingCustomers = false);
      }
    }

    if (!mounted) return;

    if (importError != null) {
      CustomDialog.showErrorSnack(
        context,
        importError.toString().replaceFirst("Exception: ", ""),
      );
      return;
    }

    final summary = _csvImportSummary(
      added: added,
      invalid: parsed.invalidRows,
      duplicate: duplicate,
      failed: failed,
      overLimit: overLimit,
      maxCustomers: maxCustomers,
    );

    if (added > 0) {
      CustomDialog.showSuccessSnack(context, summary);
    } else {
      CustomDialog.showErrorSnack(context, summary);
    }
  }

  String _csvImportSummary({
    required int added,
    required int invalid,
    required int duplicate,
    required int failed,
    required int overLimit,
    required int? maxCustomers,
  }) {
    final parts = <String>[
      added > 0
          ? "Added $added customer${added == 1 ? '' : 's'}"
          : "No customers added",
    ];

    if (invalid > 0) {
      parts.add("$invalid invalid row${invalid == 1 ? '' : 's'} skipped");
    }
    if (duplicate > 0) {
      parts.add("$duplicate duplicate${duplicate == 1 ? '' : 's'} skipped");
    }
    if (failed > 0) {
      parts.add("$failed failed");
    }
    if (overLimit > 0) {
      parts.add(
        maxCustomers == null
            ? "$overLimit not added because the customer limit is full"
            : "$overLimit not added. Limit is $maxCustomers customers",
      );
    }

    return parts.join(". ");
  }

  _CustomerCsvParseResult _parseCustomerCsv(String content) {
    final table = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    final rows = table.where((row) {
      return row.any((cell) => cell.toString().trim().isNotEmpty);
    }).toList();

    if (rows.isEmpty) {
      return _CustomerCsvParseResult.error("CSV file is empty");
    }

    final headers = rows.first
        .map((cell) => cell.toString().replaceAll('\uFEFF', '').trim().toLowerCase())
        .toList();

    int? column(List<String> aliases) {
      for (final alias in aliases) {
        final index = headers.indexOf(alias);
        if (index != -1) return index;
      }
      return null;
    }

    final nameIndex = column(const [
      "name",
      "customer name",
      "customer_name",
      "full name",
      "fullname",
    ]);
    final phoneIndex = column(const [
      "phone",
      "phone number",
      "phone_number",
      "mobile",
      "mobile number",
      "mobile_number",
      "contact",
      "contact number",
    ]);

    if (nameIndex == null || phoneIndex == null) {
      return _CustomerCsvParseResult.error(
        "CSV must include name and phone columns",
      );
    }

    final emailIndex = column(const ["email", "e-mail", "email address"]);
    final genderIndex = column(const ["gender", "sex"]);
    final pendingIndex = column(const [
      "pending_amount",
      "pending amount",
      "pending",
      "due",
      "due amount",
    ]);

    String cellAt(List<dynamic> row, int? index) {
      if (index == null || index < 0 || index >= row.length) return "";
      return row[index].toString().trim();
    }

    final existingPhones = customers
        .map((customer) => _normalizeIndianPhone(customer.phone.toString()))
        .whereType<String>()
        .toSet();
    final seenPhones = <String>{...existingPhones};

    final parsedRows = <_CsvCustomerRow>[];
    var invalidRows = 0;
    var duplicateRows = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = cellAt(row, nameIndex);
      final phone = _normalizeIndianPhone(cellAt(row, phoneIndex));

      if (name.isEmpty || phone == null) {
        invalidRows++;
        continue;
      }

      if (!seenPhones.add(phone)) {
        duplicateRows++;
        continue;
      }

      final genderRaw = cellAt(row, genderIndex).toLowerCase();
      final gender = genderRaw.startsWith("f") ? "female" : "male";
      final pendingRaw = cellAt(row, pendingIndex).replaceAll(RegExp(r'[^0-9.]'), '');

      parsedRows.add(
        _CsvCustomerRow(
          name: name,
          phone: phone,
          email: cellAt(row, emailIndex),
          gender: gender,
          pendingAmount: pendingRaw.isEmpty ? "0" : pendingRaw,
        ),
      );
    }

    return _CustomerCsvParseResult(
      rows: parsedRows,
      invalidRows: invalidRows,
      duplicateRows: duplicateRows,
    );
  }

  bool _isCustomerLimitError(String message) {
    final text = message.toLowerCase();
    return text.contains("limit") ||
        text.contains("maximum") ||
        text.contains("max customer") ||
        text.contains("quota");
  }

  bool _isForbiddenError(String message) {
    final text = message.toLowerCase();
    return text.contains("403") ||
        text.contains("forbidden") ||
        text.contains("permission") ||
        text.contains("not authorized");
  }

  String? _normalizeIndianPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return null;
    return digits;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(appTypeProvider);
    // Stay subscribed so bill-payment invalidation refreshes pending amounts.
    ref.watch(customerProvider);

    ref.listen(customerProvider, (previous, next) {
      next.when(
        data: (data) {
          if (!mounted) return;
          setState(() {
            customers = data;
            isLoading = false;
          });
        },
        loading: () {
          if (!mounted) return;
          if (customers.isEmpty) {
            setState(() => isLoading = true);
          }
        },
        error: (e, _) {
          if (!mounted) return;
          setState(() => isLoading = false);
        },
      );
    });

    final primary = Theme.of(context).colorScheme.primary;

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: _buildAppBar(type: type, primary: primary),

      floatingActionButton: isDesktop
          ? null
          : _buildMobileFab(type: type, primary: primary),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isDesktop
          ? _buildDesktopLayout(type: type, primary: primary)
          : _buildMobileLayout(type: type, primary: primary),
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================

  PreferredSizeWidget _buildAppBar({
    required AppType type,
    required Color primary,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return AppBar(
      backgroundColor: primary,
      title: Text(
        "Add ${DashboardText.customer(type)}",
        style: const TextStyle(
          color: AppColors.appBarText,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      actions: isDesktop
          ? null
          : [
              IconButton(
                tooltip: "Upload CSV",
                onPressed: isImportingCustomers ? null : _showImportCustomersCsv,
                icon: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.white,
                ),
              ),
            ],
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================

  Widget _buildMobileLayout({required AppType type, required Color primary}) {
    return Column(
      children: [
        _buildSearchBar(type: type, primary: primary),

        Expanded(
          child: _buildCustomerList(type: type, primary: primary),
        ),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP LAYOUT
  // ===========================================================================

  Widget _buildDesktopLayout({required AppType type, required Color primary}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------------------------------------------------------
        // LEFT - CUSTOMER LIST
        // ---------------------------------------------------------------------
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              50, // left space
              10,
              50, // right space before panel
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopHeader(type: type),

                const SizedBox(height: 18),

                _buildSearchBar(type: type, primary: primary, desktop: true),

                const SizedBox(height: 12),

                Expanded(
                  child: _buildCustomerList(
                    type: type,
                    primary: primary,
                    desktop: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // RIGHT - ADD CUSTOMER PANEL
        // ---------------------------------------------------------------------
        SizedBox(
          width: 390,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            child: _buildDesktopAddCustomerPanel(type: type, primary: primary),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP HEADER
  // ===========================================================================

  Widget _buildDesktopHeader({required AppType type}) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Customers",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(width: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${customers.length}",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),

        const Spacer(),

        OutlinedButton.icon(
          onPressed: isImportingCustomers ? null : _showImportCustomersCsv,
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text("Upload CSV"),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar({
    required AppType type,
    required Color primary,
    bool desktop = false,
  }) {
    return Padding(
      padding: desktop
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(desktop ? 14 : 18),
          border: Border.all(color: primary.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,

          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase().trim();
            });
          },

          decoration: InputDecoration(
            hintText: DashboardText.searchBarTitle(type),

            hintStyle: TextStyle(
              color: Colors.grey.shade500,
            ),

            prefixIcon: Icon(
              Icons.search_rounded,
              color: primary,
            ),

            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
              onPressed: () {
                searchController.clear();

                setState(() {
                  searchQuery = "";
                });
              },
              icon: const Icon(
                Icons.close_rounded,
              ),
            )
                : null,

            filled: true,

            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.12),
                width: 1.5,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.12),
                width: 0.2,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: primary.withOpacity(0.45),
                width: 1.5,
              ),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CUSTOMER LIST
  // ===========================================================================

  Widget _buildCustomerList({
    required AppType type,
    required Color primary,
    bool desktop = false,
  }) {
    final query = searchQuery.toLowerCase().trim();

    final filteredCustomers = customers.where((customer) {
      if (query.isEmpty) return true;

      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.gender.toLowerCase().contains(query) ||
          customer.pendingAmount.toString().toLowerCase().contains(query);
    }).toList();

    if (filteredCustomers.isEmpty) {
      return _buildEmptyCustomerState(type: type);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: desktop ? 4 : 12,
        left: desktop ? 0 : 12,
        right: desktop ? 0 : 12,
        bottom: desktop ? 20 : 100,
      ),
      itemCount: filteredCustomers.length,
      itemBuilder: (_, index) {
        final customer = filteredCustomers[index];

        return _buildCustomerCard(
          customer: customer,
          type: type,
          primary: primary,
        );
      },
    );
  }

  // ===========================================================================
  // CUSTOMER CARD
  // ===========================================================================

  Widget _buildCustomerCard({
    required dynamic customer,
    required AppType type,
    required Color primary,
  }) {
    final pendingAmount = double.tryParse(customer.pendingAmount) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

          leading: CircleAvatar(
            radius: 24,
            backgroundColor: primary,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          title: Text(
            customer.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pendingAmount > 0)
                _buildPendingAmount(customer.pendingAmount),

              _buildCustomerMenu(customer: customer, type: type),
            ],
          ),

          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

          children: [
            _buildCustomerDetails(customer: customer, primary: primary),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PENDING AMOUNT
  // ===========================================================================

  Widget _buildPendingAmount(String amount) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        AppFormatters.currencyOf(amount),
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  // ===========================================================================
  // CUSTOMER MENU
  // ===========================================================================

  Widget _buildCustomerMenu({
    required dynamic customer,
    required AppType type,
  }) {
    return PopupMenuButton<String>(
      tooltip: "More",
      elevation: 8,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      position: PopupMenuPosition.under,

      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.more_vert_rounded, size: 18),
      ),

      onSelected: (value) {
        switch (value) {
          case "edit":
            _showEditCustomerDialog(customer, type);
            break;

          case "delete":
            _deleteCustomer(customer);
            break;
        }
      },

      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: "edit",
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.blue,
                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              const Text("Edit", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        const PopupMenuDivider(),

        PopupMenuItem<String>(
          value: "delete",
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              const Text(
                "Delete",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DELETE CUSTOMER
  // ===========================================================================

  void _deleteCustomer(dynamic customer) {
    final pendingAmount = double.tryParse(customer.pendingAmount) ?? 0;

    if (pendingAmount > 0) {
      CustomDialog.showErrorSnack(
        context,
        "Clear pending amount first before deleting customer.",
      );

      return;
    }

    CustomDialog.showConfirmDialog(
      context: context,
      title: "Delete Customer",
      message: "Are you sure you want to delete ${customer.name}?",
      onConfirm: () async {
        try {
          await ref
              .read(businessRepositoryProvider)
              .deleteCustomer(customer.id);

          await _fetchCustomers();

          if (!context.mounted) return;

          CustomDialog.showSuccessSnack(
            context,
            "Customer deleted successfully.",
          );
        } catch (e) {
          if (!context.mounted) return;

          CustomDialog.showErrorSnack(context, e.toString());
        }
      },
    );
  }

  // ===========================================================================
  // CUSTOMER DETAILS
  // ===========================================================================

  Widget _buildCustomerDetails({
    required dynamic customer,
    required Color primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),

            const SizedBox(width: 8),

            Text(customer.phone),
          ],
        ),

        if (customer.email.isNotEmpty) ...[
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),

              const SizedBox(width: 8),

              Expanded(child: Text(customer.email)),
            ],
          ),
        ],

        const SizedBox(height: 12),

        if (customer.gender.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              customer.gender.toUpperCase(),
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // EMPTY CUSTOMER STATE
  // ===========================================================================

  Widget _buildEmptyCustomerState({required AppType type}) {
    return CustomEmptyState(
      title: "No ${DashboardText.customer(type)} Yet",
      message:
          "You haven't added any ${DashboardText.customer(type)} yet.\nCreate your first ${DashboardText.customer(type)} to get started.",
      icon: Icons.people_outline_rounded,
    );
  }

  // ===========================================================================
  // MOBILE FAB
  // ===========================================================================

  Widget _buildMobileFab({required AppType type, required Color primary}) {
    return FloatingActionButton(
      backgroundColor: primary,
      onPressed: () {
        _showAddCustomerDialog(context);
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // ===========================================================================
  // MOBILE ADD CUSTOMER DIALOG
  // ===========================================================================

  void _showAddCustomerDialog(BuildContext screenContext) {
    _resetAddCustomerForm();

    final type = ref.read(appTypeProvider);

    showDialog(
      context: screenContext,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 620,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      16,
                    ),
                    child: Form(
                      key: _addCustomerFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -----------------------------------------------------
                          // HEADER
                          // -----------------------------------------------------

                          Text(
                            "Add ${DashboardText.customer(type)}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // -----------------------------------------------------
                          // FIELDS
                          // -----------------------------------------------------

                          _buildAddCustomerFields(
                            type: type,
                            primary: theme.colorScheme.primary,
                            onGenderChanged: (gender) {
                              setDialogState(() {
                                selectedGender = gender;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // -----------------------------------------------------
                          // ACTIONS
                          // -----------------------------------------------------

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isAddingCustomer
                                      ? null
                                      : () {
                                    Navigator.pop(dialogContext);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      44,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isAddingCustomer
                                      ? null
                                      : () async {
                                    final valid =
                                        _addCustomerFormKey
                                            .currentState
                                            ?.validate() ??
                                            false;

                                    if (!valid) {
                                      return;
                                    }

                                    final rootNav =
                                    Navigator.of(
                                      screenContext,
                                      rootNavigator: true,
                                    );

                                    Navigator.pop(
                                      dialogContext,
                                    );

                                    showLoadingDialog(
                                      screenContext,
                                    );

                                    await _addCustomer(
                                      feedbackContext:
                                      screenContext,
                                      closeDialog: false,
                                    );

                                    if (screenContext.mounted) {
                                      rootNav.pop();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(
                                      double.infinity,
                                      44,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isAddingCustomer
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text(
                                    "Add",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
  // ===========================================================================
  // DESKTOP ADD CUSTOMER PANEL
  // ===========================================================================

  Widget _buildDesktopAddCustomerPanel({
    required AppType type,
    required Color primary,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(28),

        child: Form(
          key: _addCustomerFormKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ---------------------------------------------------------------
              // PANEL HEADER
              // ---------------------------------------------------------------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded, color: primary),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add ${DashboardText.customer(type)}",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          "Add a new customer to your business",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------------
              // FORM
              // ---------------------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  child: _buildAddCustomerFields(
                    type: type,
                    primary: primary,
                    onGenderChanged: (gender) {
                      setState(() {
                        selectedGender = gender;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ---------------------------------------------------------------
              // DESKTOP ADD BUTTON
              // ---------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isAddingCustomer
                      ? null
                      : () async {
                          final valid =
                              _addCustomerFormKey.currentState?.validate() ??
                              false;

                          if (!valid) {
                            return;
                          }

                          await _addCustomer(
                            feedbackContext: context,
                            closeDialog: false,
                          );
                        },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.colorScheme.onSurface
                        .withOpacity(0.12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: isAddingCustomer
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Add Customer",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD CUSTOMER FIELDS
  // ===========================================================================

  Widget _buildAddCustomerFields({
    required AppType type,
    required Color primary,
    required ValueChanged<String> onGenderChanged,
  }) {
    final theme = Theme.of(context);

    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: theme.colorScheme.outline.withOpacity(0.12),
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primary.withOpacity(0.45), width: 1.5),
    );

    return Column(
      children: [
        // ---------------------------------------------------------------------
        // NAME
        // ---------------------------------------------------------------------
        TextFormField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,

          decoration: InputDecoration(
            hintText: DashboardText.customerName(type),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.person_outline, size: 20),

            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.3,
            ),

            border: normalBorder,
            enabledBorder: normalBorder,
            focusedBorder: focusedBorder,
          ),

          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Customer name is required";
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // PHONE
        // ---------------------------------------------------------------------
        TextFormField(
          controller: phoneController,

          keyboardType: TextInputType.number,

          maxLength: 10,

          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],

          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Phone number is required";
            }

            final phoneRegex = RegExp(r'^[6-9]\d{9}$');

            if (value.length != 10) {
              return "Must be 10 digits";
            }

            if (!phoneRegex.hasMatch(value)) {
              return "Invalid Indian number";
            }

            return null;
          },

          autovalidateMode: AutovalidateMode.onUserInteraction,

          decoration: InputDecoration(
            counterText: "",

            hintText: "Phone Number *",

            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),

            prefixIcon: const Icon(Icons.phone_outlined, size: 20),

            filled: true,

            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.3,
            ),

            border: normalBorder,
            enabledBorder: normalBorder,
            focusedBorder: focusedBorder,
          ),
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // EMAIL
        // ---------------------------------------------------------------------
        TextFormField(
          controller: emailController,

          keyboardType: TextInputType.emailAddress,

          decoration: InputDecoration(
            hintText: "Email (Optional)",

            hintStyle: TextStyle(color: Colors.grey.shade500),

            prefixIcon: const Icon(Icons.email_outlined, size: 20),

            filled: true,

            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.3,
            ),

            border: normalBorder,
            enabledBorder: normalBorder,
            focusedBorder: focusedBorder,
          ),
        ),

        const SizedBox(height: 18),

        // ---------------------------------------------------------------------
        // GENDER
        // ---------------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(4),

          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),

            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.08),
              width: 1,
            ),
          ),

          child: Row(
            children: [
              // -----------------------------------------------------------------
              // MALE
              // -----------------------------------------------------------------
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    onGenderChanged("male");
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),

                    padding: const EdgeInsets.symmetric(vertical: 12),

                    decoration: BoxDecoration(
                      color: selectedGender == "male"
                          ? primary
                          : Colors.transparent,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Center(
                      child: Text(
                        "Male",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,

                          color: selectedGender == "male"
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // FEMALE
              // -----------------------------------------------------------------
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    onGenderChanged("female");
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),

                    padding: const EdgeInsets.symmetric(vertical: 12),

                    decoration: BoxDecoration(
                      color: selectedGender == "female"
                          ? primary
                          : Colors.transparent,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Center(
                      child: Text(
                        "Female",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,

                          color: selectedGender == "female"
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // EDIT CUSTOMER
  // ===========================================================================

  Future<void> _showEditCustomerDialog(
    CustomerResponseModel customer,
    AppType type,
  ) async {
    final nameCtrl = TextEditingController(text: customer.name);

    final phoneCtrl = TextEditingController(text: customer.phone);

    final emailCtrl = TextEditingController(text: customer.email);

    String editGender = customer.gender;

    bool editLoading = false;

    final formKey = GlobalKey<FormState>();
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .colorScheme
            .outline
            .withOpacity(0.12),
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.45),
        width: 1.5,
      ),
    );
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),

              child: SizedBox(
                width: 400,

                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Form(
                      key: formKey,

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.1),
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : "?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Edit ${DashboardText.customer(type)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: DashboardText.customerName(type),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                              ),
                              border: normalBorder,
                              enabledBorder: normalBorder,
                              focusedBorder: focusedBorder,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Phone number is required";
                              }

                              final cleaned = value.replaceAll(' ', '');

                              final regex = RegExp(r'^[6-9]\d{9}$');

                              if (cleaned.length != 10) {
                                return "Must be 10 digits";
                              }

                              if (!regex.hasMatch(cleaned)) {
                                return "Invalid Indian number";
                              }

                              return null;
                            },

                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Phone Number",
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                              ),
                              border: normalBorder,
                              enabledBorder: normalBorder,
                              focusedBorder: focusedBorder,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                              ),
                              border: normalBorder,
                              enabledBorder: normalBorder,
                              focusedBorder: focusedBorder,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        editGender = "male";
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      decoration: BoxDecoration(
                                        color: editGender == "male"
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Male",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: editGender == "male"
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        editGender = "female";
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      decoration: BoxDecoration(
                                        color: editGender == "female"
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Female",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: editGender == "female"
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 42,
                            child: Row(
                              children: [
                                OutlinedButton(
                                  onPressed: editLoading
                                      ? null
                                      : () {
                                          Navigator.pop(dialogContext);
                                        },
                                  child: const Text("Cancel"),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: editLoading
                                        ? null
                                        : () async {
                                            if (nameCtrl.text.trim().isEmpty) {
                                              CustomDialog.showErrorSnack(
                                                context,
                                                "Customer name required",
                                              );
                                              return;
                                            }

                                            setDialogState(() {
                                              editLoading = true;
                                            });

                                            try {
                                              final request =
                                                  UpdateCustomerRequestModel(
                                                    name: nameCtrl.text.trim(),
                                                    phone: phoneCtrl.text
                                                        .trim(),
                                                    gender: editGender,
                                                    email: emailCtrl.text
                                                        .trim(),
                                                    fcmToken: "",
                                                    pendingAmount:
                                                        double.tryParse(
                                                          customer
                                                              .pendingAmount,
                                                        ) ??
                                                        0,
                                                  );

                                              await ref
                                                  .read(
                                                    businessRepositoryProvider,
                                                  )
                                                  .updateCustomer(
                                                    customerId: customer.id,
                                                    request: request,
                                                  );

                                              await _fetchCustomers();

                                              if (!context.mounted) {
                                                return;
                                              }

                                              Navigator.pop(dialogContext);

                                              CustomDialog.showSuccessSnack(
                                                this.context,
                                                "Customer updated successfully",
                                              );
                                            } catch (e) {
                                              setDialogState(() {
                                                editLoading = false;
                                              });

                                              CustomDialog.showErrorSnack(
                                                context,
                                                e.toString(),
                                              );
                                            }
                                          },

                                    child: editLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text("Update"),
                                  ),
                                ),
                              ],
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

    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
  }
}

// =============================================================================
// LOADING DIALOG
// =============================================================================

class _CsvImportProgress {
  final int done;
  final int total;
  final String label;

  const _CsvImportProgress({
    this.done = 0,
    this.total = 0,
    this.label = "",
  });

  double get value => total == 0 ? 0 : done / total;
}

class _CustomerCsvUploadDialog extends StatelessWidget {
  final String title;
  final Color primary;
  final VoidCallback onCancel;
  final VoidCallback onChooseFile;

  const _CustomerCsvUploadDialog({
    required this.title,
    required this.primary,
    required this.onCancel,
    required this.onChooseFile,
  });

  static const _headers = [
    "name*",
    "phone*",
    "email",
    "gender",
    "pending_amount",
  ];

  static const _sampleRows = [
    ["Amit Sharma", "9876543210", "amit@email.com", "male", "0"],
    ["Neha Singh", "9123456789", "neha@email.com", "female", "150"],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.upload_file_rounded, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Match the sample columns, then choose a file.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.62,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                "Sample format",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "* name and phone are required. Other columns are optional.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _sampleTable(theme),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Customers are added only until this business limit is full. Extra rows are skipped.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onChooseFile,
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text("Choose CSV"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sampleTable(ThemeData theme) {
    Widget cell(String text, {bool header = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: header ? 14 : 15,
            fontWeight: header ? FontWeight.w800 : FontWeight.w600,
            height: 1.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        verticalInside: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
          ),
          children: [for (final header in _headers) cell(header, header: true)],
        ),
        for (final row in _sampleRows)
          TableRow(children: [for (final value in row) cell(value)]),
      ],
    );
  }
}

class _CustomerImportProgressDialog extends StatelessWidget {
  final Color primary;
  final ValueNotifier<_CsvImportProgress> progress;

  const _CustomerImportProgressDialog({
    required this.primary,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: ValueListenableBuilder<_CsvImportProgress>(
              valueListenable: progress,
              builder: (context, value, _) {
                final percent = (value.value * 100).round();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Adding customers",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: value.total == 0 ? null : value.value,
                        minHeight: 8,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value.total == 0
                          ? "Preparing"
                          : "${value.done} of ${value.total}  ·  $percent%",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CsvCustomerRow {
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String pendingAmount;

  const _CsvCustomerRow({
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.pendingAmount,
  });
}

class _CustomerCsvParseResult {
  final List<_CsvCustomerRow> rows;
  final int invalidRows;
  final int duplicateRows;
  final String? error;

  const _CustomerCsvParseResult({
    this.rows = const [],
    this.invalidRows = 0,
    this.duplicateRows = 0,
    this.error,
  });

  factory _CustomerCsvParseResult.error(String message) {
    return _CustomerCsvParseResult(error: message);
  }
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) {
      return const Center(child: CircularProgressIndicator());
    },
  );
}
