import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/business_models/business_access_model.dart';
import '../../../models/super_admin_models/business_list_model.dart';
import '../../../services/business/business_access_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dialog.dart';

class BusinessDetailPage extends StatefulWidget {
  final Business business;

  const BusinessDetailPage({super.key, required this.business});

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  BusinessAccess? access;
  bool loadingAccess = true;

  final TextEditingController maxCustomerController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchAccess();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  void fetchAccess() async {
    try {
      final result = await BusinessAccessService.fetchAccess(
        widget.business.id,
      );

      setState(() {
        access = result;
        maxCustomerController.text = result.maxCustomers.toString();
        loadingAccess = false;
      });
    } catch (e) {
      loadingAccess = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final isActive = b.isActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: _topBar(context, b),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        _heroCard(b, isActive),

                        const SizedBox(height: 8),

                        /// 🔥 MERGED CARD (COMPACT)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.035),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🔥 BUSINESS INFO
                              Text(
                                "BUSINESS INFO",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              _tile("Business ID", b.id.toString(), Icons.tag),
                              _divider(),
                              _tile(
                                "Gov ID",
                                b.doc ?? "Not Provided",
                                Icons.badge,
                                copy: true,
                              ),
                              _divider(),
                              _tile("Name", b.name, Icons.store),
                              _divider(),
                              _tile("Category", b.category, Icons.category),

                              /// 🔥 LOCATION
                              Text(
                                "LOCATION",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              const SizedBox(height: 6),

                              _tile("Address", b.address, Icons.location_on),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// 🔥 ACCESS CONTROL
                        _section("ACCESS CONTROL"),

                        const SizedBox(height: 6),

                        loadingAccess
                            ? const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: CircularProgressIndicator(),
                              )
                            : _accessControls(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }

  Widget _accessControls() {
    return Column(
      children: [
        _switchTile(
          "Reminder",
          access!.reminderEnabled,
          (v) => setState(() => access!.reminderEnabled = v),
          icon: Icons.notifications_active,
        ),

        _switchTile(
          "Income",
          access!.incomeEnabled,
          (v) => setState(() => access!.incomeEnabled = v),
          icon: Icons.trending_up,
        ),
        _switchTile(
          "Expense",
          access!.expenseEnabled,
          (v) => setState(() => access!.expenseEnabled = v),
          icon: Icons.trending_down,
        ),
        _switchTile(
          "Customers",
          access!.customersEnabled,
          (v) => setState(() => access!.customersEnabled = v),
          icon: Icons.people,
        ),
        _switchTile(
          "Support",
          access!.supportQueriesEnabled,
          (v) => setState(() => access!.supportQueriesEnabled = v),
          icon: Icons.support_agent,
        ),

        const SizedBox(height: 16),

        TextField(
          controller: maxCustomerController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          cursorColor: AppColors.primary,

          decoration: InputDecoration(
            labelText: "Max Customers",

            labelStyle: TextStyle(color: Colors.grey.shade700),

            floatingLabelStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),

            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),

          onChanged: (val) {
            access!.maxCustomers = int.tryParse(val) ?? 0;
          },
        ),

        const SizedBox(height: 16),

        CustomButton(
          backgroundColor: AppColors.primary,
          label: "Save Changes",
          onTap: () async {
            final text = maxCustomerController.text.trim();

            /// 🔥 VALIDATION
            if (text.isEmpty) {
              _showError("Please enter max customers");
              return;
            }

            final parsed = int.tryParse(text);

            if (parsed == null || parsed <= 0) {
              _showError("Enter a valid number greater than 0");
              return;
            }

            /// ✅ SAFE ASSIGN
            access!.maxCustomers = parsed;

            try {
              await BusinessAccessService.updateAccess(access!);

              CustomDialog.showSuccessSnack(
                context,
                "Changes Saved Successfully!",
              );
            } catch (e) {
              _showError("Update failed. Try again.");
            }
          },
        ),
      ],
    );
  }

  void _showError(String msg) {
    CustomDialog.showErrorSnack(context, msg);
  }

  Widget _switchTile(
    String title,
    bool value,
    Function(bool) onChanged, {
    IconData? icon, // 🔥 optional icon
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          /// 🔥 ICON (if provided)
          if (icon != null) ...[
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
          ],

          /// 🔥 TITLE
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          /// 🔥 SWITCH
          Switch(
            inactiveThumbColor: AppColors.primaryDark,
            trackOutlineColor: WidgetStatePropertyAll( AppColors.primaryDark.withOpacity(0.3)),
            hoverColor: AppColors.primary,
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _topBar(BuildContext context, Business b) {
    return AppBar(
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
      ),

      titleSpacing: 0,

      title: Text(
        b.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),

      centerTitle: false,
    );
  }

  Widget _heroCard(Business b, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.store,
              color: isActive ? AppColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(b.category, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, String value, IconData icon, {bool copy = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          /// 🔥 ICON CONTAINER (UPDATED)
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),

          const SizedBox(width: 10),

          /// 🔥 TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 COPY BUTTON
          if (copy)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, size: 14, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}
