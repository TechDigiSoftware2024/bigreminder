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

  Future<void> _fetchCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";
      final businessId = prefs.getInt("businessId") ?? 0;

      final data = await BusinessService()
          .fetchCustomers(
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

      CustomDialog.showErrorSnack(
        context,
        e.toString(),
      );
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
          : customers.isEmpty
          ? _emptyState(context, customerLabel)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (_, i) {
          final c = customers[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: primary,
                  child: Text(
                    c.name.isNotEmpty
                        ? c.name[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                /// Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Name
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// Phone
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.phone,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),

                      /// Email
                      if ((c.email ?? "").isNotEmpty) ...[
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),

                            Expanded(
                              child: Text(
                                c.email ?? "",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      /// Gender Chip
                      if ((c.gender ?? "").isNotEmpty) ...[
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            c.gender!.toUpperCase(),
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
        },
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
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
                          prefixIcon:
                          const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(14),
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
                          prefixIcon:
                          const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(14),
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
                          prefixIcon:
                          const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(14),
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
                          borderRadius:
                          BorderRadius.circular(14),
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
                                  duration: const Duration(
                                      milliseconds: 220),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    selectedGender == "male"
                                        ? primary
                                        : Colors.transparent,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Male",
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.w600,
                                        color:
                                        selectedGender ==
                                            "male"
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
                                  duration: const Duration(
                                      milliseconds: 220),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    selectedGender ==
                                        "female"
                                        ? primary
                                        : Colors.transparent,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Female",
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.w600,
                                        color:
                                        selectedGender ==
                                            "female"
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
                      CustomDialog.showErrorSnack(dialogContext, "Please enter required fields");
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
                      );

                      await _fetchCustomers();

                      // ✅ Use pre-captured navigator — no mounted check needed
                      rootNav.pop(); // close loader

                      if (context.mounted) {
                        CustomDialog.showSuccessSnack(context, "Customer added successfully");
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