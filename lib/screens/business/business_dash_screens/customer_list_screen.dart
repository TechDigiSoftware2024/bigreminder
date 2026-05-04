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

      final data = await BusinessService().fetchCustomers(
        token: token,
        businessId: businessId, // ✅ PASS HERE
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
          : customers.isEmpty
          ? _emptyState(context, customerLabel)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (_, i) {
          final c = customers[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Text(
                    c.name.isNotEmpty
                        ? c.name[0].toUpperCase()
                        : "?",
                    style: TextStyle(color: primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.phone,
                        style: const TextStyle(color: Colors.grey),
                      ),
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        // ✅ Use dialogContext so we can safely pop the dialog independently
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Add Customer"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Customer Name",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Phone Number",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  CustomDialog.showErrorSnack(
                      dialogContext, "Please enter all fields");
                  return;
                }

                // ✅ STEP 1: Close the add-customer dialog FIRST
                Navigator.pop(dialogContext);

                // ✅ STEP 2: Show loading on the ROOT navigator (uses outer `context`)
                showLoadingDialog(context);

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final businessId = prefs.getInt("businessId") ?? 0;
                  final token = prefs.getString("token") ?? "";

                  await BusinessService().addCustomer(
                    name: name,
                    phone: phone,
                    businessId: businessId,
                    token: token,
                    fcmToken: '',
                  );

                  // ✅ STEP 3: Dismiss loading dialog
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    CustomDialog.showSuccessSnack(
                        context, "Customer added successfully");

                    // ✅ STEP 4: Refresh the list
                    _fetchCustomers();
                  }
                } catch (e) {
                  // ✅ STEP 3 (error): Dismiss loading dialog
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    CustomDialog.showErrorSnack(context, e.toString());
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
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