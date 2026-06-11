import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/business_models/create_item_model.dart';
import '../../models/business_models/create_purchase_model.dart';
import '../../models/business_models/customer_list_model.dart';
import '../../providers/business/business_provider.dart';
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
  final itemPriceCtrl = TextEditingController();
  final itemQtyCtrl = TextEditingController(text: "1");

  final searchCtrl = TextEditingController();

  List<CustomerResponseModel> customers = [];

  List<Map<String, dynamic>> items = [];

  bool isLoading = true;
  bool isCreating = false;

  bool isCustomerExpanded = false;

  CustomerResponseModel? selectedCustomer;

  int businessId = 0;

  int? selectedCustomerId;

  String searchQuery = "";

  double totalAmount = 0;
  double pendingAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
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

  void calculateAmounts() {
    totalAmount = items.fold(
      0,
      (sum, e) => sum + ((e["price"] as double) * (e["quantity"] as int)),
    );

    final paid = double.tryParse(paidCtrl.text) ?? 0;

    pendingAmount = totalAmount - paid;
  }

  void addItem() {
    if (itemNameCtrl.text.trim().isEmpty) {
      return;
    }

    final price = double.tryParse(itemPriceCtrl.text) ?? 0;

    final qty = int.tryParse(itemQtyCtrl.text) ?? 1;

    setState(() {
      items.add({
        "name": itemNameCtrl.text.trim(),
        "price": price,
        "quantity": qty,
      });

      calculateAmounts();
    });

    itemNameCtrl.clear();
    itemPriceCtrl.clear();
    itemQtyCtrl.text = "1";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredCustomers = customers.where((customer) {
      final q = searchQuery.toLowerCase();

      return customer.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Create Purchase",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

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
                      "₹$totalAmount",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      "Pending ₹$pendingAmount",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 50,
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
                        : () async {
                            if (selectedCustomerId == null) {
                              CustomDialog.showErrorSnack(
                                context,
                                "Select customer",
                              );

                              return;
                            }

                            if (items.isEmpty) {
                              CustomDialog.showErrorSnack(
                                context,
                                "Add items first",
                              );

                              return;
                            }

                            setState(() {
                              isCreating = true;
                            });

                            try {
                              final purchaseItems = items.map((e) {
                                return PurchaseItemModel(
                                  name: e["name"],
                                  price: e["price"],
                                  quantity: e["quantity"],
                                );
                              }).toList();

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

                              await ref
                                  .read(businessControllerProvider.notifier)
                                  .createPurchase(model: model);

                              if (context.mounted) {
                                CustomDialog.showSuccessSnack(
                                  context,
                                  "Purchase created",
                                );

                                Navigator.pop(context);
                              }
                            } catch (e) {
                              CustomDialog.showErrorSnack(
                                context,
                                e.toString(),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isCreating = false;
                                });
                              }
                            }
                          },

                    child: Text(isCreating ? "Creating..." : "Create"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),

              child: Column(
                children: [
                  /// 🔥 CUSTOMER SELECT DROPDOWN
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
                        /// SELECT BUTTON
                        InkWell(
                          borderRadius: BorderRadius.circular(16),

                          onTap: () {
                            setState(() {
                              isCustomerExpanded = !isCustomerExpanded;
                            });
                          },

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),

                              border: Border.all(color: Colors.grey.shade300),
                            ),

                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: theme.primaryColor,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    selectedCustomer != null
                                        ? selectedCustomer!.name
                                        : "Select Customer",

                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: selectedCustomer != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),

                                AnimatedRotation(
                                  turns: isCustomerExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 250),

                                  child: const Icon(Icons.keyboard_arrow_down),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isCustomerExpanded) ...[
                          const SizedBox(height: 14),

                          /// SEARCH
                          TextField(
                            controller: searchCtrl,

                            onChanged: (v) {
                              setState(() {
                                searchQuery = v;
                              });
                            },

                            decoration: InputDecoration(
                              hintText: "Search customer",

                              prefixIcon: const Icon(Icons.search),

                              filled: true,

                              fillColor: const Color(0xffF5F7FB),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),

                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// ADD NEW CUSTOMER BUTTON
                          InkWell(
                            borderRadius: BorderRadius.circular(16),

                            onTap: () {
                              _showAddCustomerDialog(context);
                            },

                            child: Container(
                              width: double.infinity,

                              padding: const EdgeInsets.symmetric(vertical: 14),

                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.08),

                                borderRadius: BorderRadius.circular(16),

                                border: Border.all(
                                  color: theme.primaryColor.withOpacity(0.15),
                                ),
                              ),

                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Icon(Icons.add, color: theme.primaryColor),

                                  const SizedBox(width: 8),

                                  Text(
                                    "Add New Customer",

                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// CUSTOMER LIST
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),

                            child: ListView.separated(
                              shrinkWrap: true,

                              physics: const BouncingScrollPhysics(),

                              itemCount: filteredCustomers.length,

                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),

                              itemBuilder: (_, i) {
                                final customer = filteredCustomers[i];

                                final isSelected =
                                    selectedCustomerId == customer.id;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),

                                  onTap: () {
                                    setState(() {
                                      selectedCustomer = customer;

                                      selectedCustomerId = customer.id;

                                      isCustomerExpanded = false;
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
                                        color: isSelected
                                            ? theme.primaryColor
                                            : Colors.grey.shade200,
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
                                                : theme.primaryColor
                                                      .withOpacity(0.1),

                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),

                                          alignment: Alignment.center,

                                          child: Text(
                                            customer.name[0].toUpperCase(),

                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : theme.primaryColor,

                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              Text(
                                                customer.name,

                                                maxLines: 1,

                                                overflow: TextOverflow.ellipsis,

                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

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
                                          Icon(
                                            Icons.check_circle,
                                            color: theme.primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  /// 🔥 ADD ITEM
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
                        Row(
                          children: [
                            Expanded(
                              flex: 2,

                              child: TextField(
                                controller: itemNameCtrl,

                                decoration: _inputDecoration("Item"),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: TextField(
                                controller: itemPriceCtrl,

                                keyboardType: TextInputType.number,

                                decoration: _inputDecoration("Price"),
                              ),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              width: 68,

                              child: TextField(
                                controller: itemQtyCtrl,

                                keyboardType: TextInputType.number,

                                decoration: _inputDecoration("Qty"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 48,

                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,

                              backgroundColor: theme.primaryColor,

                              foregroundColor: Colors.white,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),

                            onPressed: addItem,

                            icon: const Icon(Icons.add),

                            label: const Text("Add Item"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// 🔥 ITEMS
                  if (items.isEmpty)
                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.symmetric(vertical: 34),

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
                            "No items added yet",

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
                      children: List.generate(items.length, (i) {
                        final item = items[i];

                        final total =
                            (item["price"] as double) *
                            (item["quantity"] as int);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),

                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius: BorderRadius.circular(20),

                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,

                                offset: const Offset(0, 4),

                                color: Colors.black.withOpacity(0.03),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      item["name"],

                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,

                                        fontSize: 14,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Wrap(
                                      spacing: 6,

                                      children: [
                                        _chip("₹${item["price"]}"),

                                        _chip("Qty ${item["quantity"]}"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,

                                children: [
                                  Text(
                                    "₹$total",

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,

                                      fontSize: 15,
                                    ),
                                  ),

                                  IconButton(
                                    visualDensity: VisualDensity.compact,

                                    padding: EdgeInsets.zero,

                                    onPressed: () {
                                      setState(() {
                                        items.removeAt(i);

                                        calculateAmounts();
                                      });
                                    },

                                    icon: Icon(
                                      Icons.delete_outline,

                                      size: 20,

                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                  const SizedBox(height: 14),

                  /// 🔥 PAYMENT
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
                          calculateAmounts();
                        });
                      },

                      decoration: _inputDecoration("Paid Amount"),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,

      filled: true,

      fillColor: const Color(0xffF5F7FB),

      isDense: true,

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: BorderSide.none,
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) async {
    final theme = Theme.of(context);

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    String selectedGender = "male";

    showDialog(
      context: context,

      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),

              title: const Text(
                "Add Customer",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,

                      decoration: _inputDecoration("Customer Name *"),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,

                      decoration: _inputDecoration("Phone Number *"),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: emailController,

                      decoration: _inputDecoration("Email (Optional)"),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedGender = "male";
                              });
                            },

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),

                              padding: const EdgeInsets.symmetric(vertical: 14),

                              decoration: BoxDecoration(
                                color: selectedGender == "male"
                                    ? theme.primaryColor
                                    : const Color(0xffF5F7FB),

                                borderRadius: BorderRadius.circular(14),
                              ),

                              alignment: Alignment.center,

                              child: Text(
                                "Male",

                                style: TextStyle(
                                  color: selectedGender == "male"
                                      ? Colors.white
                                      : Colors.black87,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedGender = "female";
                              });
                            },

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),

                              padding: const EdgeInsets.symmetric(vertical: 14),

                              decoration: BoxDecoration(
                                color: selectedGender == "female"
                                    ? theme.primaryColor
                                    : const Color(0xffF5F7FB),

                                borderRadius: BorderRadius.circular(14),
                              ),

                              alignment: Alignment.center,

                              child: Text(
                                "Female",

                                style: TextStyle(
                                  color: selectedGender == "female"
                                      ? Colors.white
                                      : Colors.black87,

                                  fontWeight: FontWeight.w600,
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

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),

                  onPressed: () async {
                    final name = nameController.text.trim();

                    final phone = phoneController.text.trim();

                    final email = emailController.text.trim();

                    if (name.isEmpty || phone.isEmpty) {
                      CustomDialog.showErrorSnack(
                        context,
                        "Please enter required fields",
                      );

                      return;
                    }

                    try {
                      final prefs = await SharedPreferences.getInstance();

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

                      final newCustomer = customers.last;

                      setState(() {
                        selectedCustomer = newCustomer;

                        selectedCustomerId = newCustomer.id;
                      });

                      Navigator.pop(context);

                      CustomDialog.showSuccessSnack(
                        this.context,
                        "Customer Added",
                      );
                    } catch (e) {
                      CustomDialog.showErrorSnack(context, e.toString());
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
