import 'package:bigreminder/services/business/business_service.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/enum_classes.dart';

class CustomerListScreen extends StatefulWidget {
  final AppType type;

  const CustomerListScreen({super.key, required this.type});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

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
    final primary = Theme.of(context).colorScheme.primary;
    final metrics = DashboardText.metrics(widget.type);
    final customerLabel = metrics[0];

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          customerLabel,
          style: const TextStyle(
            color: AppColors.appBarText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                        hintText: "Search customer...",
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
                        return _emptyState(context, customerLabel);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (_, i) {
                          final c = filteredCustomers[i];

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
                                    fontSize: 16,
                                  ),
                                ),

                                trailing:
                                    (double.tryParse(c.pendingAmount) ?? 0) > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
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
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,

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
                                    mainAxisAlignment: MainAxisAlignment.end,
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
                                              fontWeight: FontWeight.w600,
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

  Widget _emptyState(BuildContext context, String label) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 40, color: primary),
          const SizedBox(height: 12),
          Text(
            "No $label Yet",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Add your first $label",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    String selectedGender = "male";
    String pendingAmount = "0";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Add Customer",
                style: TextStyle(fontWeight: FontWeight.w700),
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
                          hintText: "Customer Name *",
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// Phone (Required)
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "Phone Number *",
                          prefixIcon: const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
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
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
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
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Cancel"),
                ),

                /// Add
                ElevatedButton(
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
              ],
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
