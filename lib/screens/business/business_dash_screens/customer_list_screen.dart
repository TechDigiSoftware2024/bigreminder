import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/services/business/business_service.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/empty_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/business_models/business_customer_req_model.dart';
import '../../../models/business_models/customer_list_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/enum_classes.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }
  final _formKey = GlobalKey<FormState>();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  Future<void> _fetchCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";
      final businessId = prefs.getInt("businessId") ?? 0;

      final data = await BusinessService().fetchCustomers(
        token: token,
        businessId: businessId,
      );

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

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(appTypeProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final metrics = DashboardText.metrics(type);
    final customerLabel = metrics[0];

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          "Add ${DashboardText.customer(type)}",
          style: const TextStyle(
            color: AppColors.appBarText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search_rounded, color: primary),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();

                                  setState(() {
                                    searchQuery = "";
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filteredCustomers = customers.where((customer) {
                        final query = searchQuery.toLowerCase().trim();

                        if (query.isEmpty) return true;

                        return customer.name.toLowerCase().contains(query) ||
                            customer.phone.toLowerCase().contains(query) ||
                            customer.gender.toLowerCase().contains(query) ||
                            customer.pendingAmount
                                .toString()
                                .toLowerCase()
                                .contains(query);
                      }).toList();

                      if (filteredCustomers.isEmpty) {
                        return CustomEmptyState(title: "No ${DashboardText.customer(type)} Yet", message:  "You haven't added any ${DashboardText.customer(type)} yet.\nCreate your first ${DashboardText.customer(type)}to get started.",icon: Icons.people_outline_rounded);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (_, i) {
                          final c = filteredCustomers[i];
                          debugPrint(c.id.toString());

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

                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),

                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primary,
                                  child: Text(
                                    c.name.isNotEmpty
                                        ? c.name[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if ((double.tryParse(c.pendingAmount) ??
                                            0) >
                                        0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Text(
                                          "₹${c.pendingAmount}",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),

                                    PopupMenuButton<String>(
                                      tooltip: "More",
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      position: PopupMenuPosition.under,
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.more_vert_rounded,
                                          size: 18,
                                        ),
                                      ),
                                      onSelected: (value) {
                                        switch (value) {
                                          case "edit":
                                            _showEditCustomerDialog(c,type);
                                            break;

                                          case "delete":
                                            final pendingAmount =
                                                double.tryParse(
                                                  c.pendingAmount,
                                                ) ??
                                                0;

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
                                              message:
                                                  "Are you sure you want to delete ${c.name}?",
                                              onConfirm: () async {
                                                try {
                                                  await ref
                                                      .read(
                                                        businessRepositoryProvider,
                                                      )
                                                      .deleteCustomer(c.id);

                                                  await _fetchCustomers();

                                                  if (context.mounted) {
                                                    CustomDialog.showSuccessSnack(
                                                      context,
                                                      "Customer deleted successfully.",
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    CustomDialog.showErrorSnack(
                                                      context,
                                                      e.toString(),
                                                    );
                                                  }
                                                }
                                              },
                                            );
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem<String>(
                                          value: "edit",
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.edit_rounded,
                                                  color: Colors.blue,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                "Edit",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        PopupMenuDivider(),

                                        PopupMenuItem<String>(
                                          value: "delete",
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                    ),
                                  ],
                                ),

                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),

                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(c.phone),
                                    ],
                                  ),

                                  if (c.email.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(c.email)),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (c.gender.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            c.gender.toUpperCase(),
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

      // ✅ FAB is preserved and correctly wired
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showEditCustomerDialog(CustomerResponseModel customer, AppType type) async {
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final emailCtrl = TextEditingController(text: customer.email);

    final _formKey = GlobalKey<FormState>();

    String selectedGender = customer.gender;
    bool isLoading = false;

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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: DashboardText.customerName(type),
                            labelStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
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
                            final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                            if (cleaned.length != 10) {
                              return "Must be 10 digits";
                            }
                            if (!phoneRegex.hasMatch(cleaned)) {
                              return "Invalid Indian number";
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            counterText: "",
                            labelText: "Phone Number",
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: "Email",
                            labelStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedGender = "male";
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: selectedGender == "male"
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Male",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: selectedGender == "male"
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                      selectedGender = "female";
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: selectedGender == "female"
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Female",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: selectedGender == "female"
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text("Cancel"),
                              ),

                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : () async {
                                    try {
                                      if (nameCtrl.text.trim().isEmpty) {
                                        CustomDialog.showErrorSnack(
                                          context,
                                          "Customer name required",
                                        );
                                        return;
                                      }

                                      setDialogState(() {
                                        isLoading = true;
                                      });

                                      final request = UpdateCustomerRequestModel(
                                        name: nameCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                        gender: selectedGender,
                                        email: emailCtrl.text.trim(),
                                        fcmToken: "",
                                        pendingAmount:
                                        double.tryParse(
                                          customer.pendingAmount,
                                        ) ??
                                            0,
                                      );

                                      await ref
                                          .read(businessRepositoryProvider)
                                          .updateCustomer(
                                        customerId: customer.id,
                                        request: request,
                                      );

                                      await _fetchCustomers();

                                      if (!context.mounted) return;

                                      Navigator.pop(dialogContext);

                                      CustomDialog.showSuccessSnack(
                                        this.context,
                                        "Customer updated successfully",
                                      );
                                    } catch (e) {
                                      setDialogState(() {
                                        isLoading = false;
                                      });

                                      CustomDialog.showErrorSnack(
                                        context,
                                        e.toString(),
                                      );
                                    }
                                  },
                                  child: isLoading
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
            );
          },
        );
      },
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    String selectedGender = "male";
    String pendingAmount = "0";

    final type = ref.watch(appTypeProvider);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: _formKey,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title:  Text(
                  "Add ${DashboardText.customer(type)}",
                  style: TextStyle(fontWeight: FontWeight.w700,fontSize: 16),
                ),

                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Name (Required)
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: DashboardText.customerName(type),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "Phone Number *",
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.phone_outlined, size: 20,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// Email (Optional)
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email (Optional)",
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// Gender Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              /// Male
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedGender = "male";
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              /// Female
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedGender = "female";
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                              : Colors.black87,
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
                    ),
                  ),
                ),

                actions: [
                  /// Cancel
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 10,),

                      /// Add
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            final email = emailController.text.trim();

                            if (name.isEmpty || phone.isEmpty) {
                              CustomDialog.showErrorSnack(
                                dialogContext,
                                "Please enter required fields",
                              );
                              return;
                            }

                            // ✅ Capture navigator BEFORE any async call
                            final rootNav = Navigator.of(context, rootNavigator: true);

                            Navigator.pop(dialogContext);

                            showLoadingDialog(context);

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
                                pendingAmount: pendingAmount.toString(),
                              );

                              await _fetchCustomers();

                              // ✅ Use pre-captured navigator — no mounted check needed
                              rootNav.pop(); // close loader

                              if (context.mounted) {
                                CustomDialog.showSuccessSnack(
                                  context,
                                  "Customer added successfully",
                                );
                              }
                            } catch (e) {
                              rootNav.pop(); // close loader

                              if (context.mounted) {
                                CustomDialog.showErrorSnack(
                                  context,
                                  e.toString().replaceFirst("Exception: ", ""),
                                );
                              }
                            }
                          },
                          child: const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}
