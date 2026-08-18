import 'package:bigreminder/providers/business/business_profile_state.dart';
import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/business_models/businesss_edit_profile_model.dart';
import '../../providers/business/business_provider.dart';
import '../../services/business/business_service.dart';

class EditBusinessProfileScreen extends ConsumerStatefulWidget {
  final String businessName;
  final String category;
  final String doc;
  final String address;

  const EditBusinessProfileScreen({
    super.key,
    required this.businessName,
    required this.category,
    required this.doc,
    required this.address,
  });

  @override
  ConsumerState<EditBusinessProfileScreen> createState() =>
      _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState
    extends ConsumerState<EditBusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController businessNameController;
  late final TextEditingController documentController;
  late final TextEditingController addressController;
  late final TextEditingController customCategoryController;

  String? selectedCategory;

  final List<String> categories = [
    "Gym",
    "Shop",
    "Institute",
    "Salon",
    "Hospital",
    "Restaurant",
    "Finance",
    "Real Estate",
    "Other",
  ];

  @override
  void initState() {
    super.initState();

    businessNameController =
        TextEditingController(text: widget.businessName);

    documentController =
        TextEditingController(text: widget.doc);

    addressController =
        TextEditingController(text: widget.address);

    customCategoryController =
        TextEditingController();

    selectedCategory = categories.contains(widget.category)
        ? widget.category
        : "Other";

    if (selectedCategory == "Other") {
      customCategoryController.text = widget.category;
    }
  }

  @override
  void dispose() {
    businessNameController.dispose();
    documentController.dispose();
    addressController.dispose();
    customCategoryController.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final businessId = ref.read(businessIdProvider);

    final businessCategory = selectedCategory == "Other"
        ? customCategoryController.text.trim()
        : selectedCategory!;

    final model = BusinessProfileEditModel(
      name: businessNameController.text.trim(),
      category: businessCategory,
      doc: documentController.text.trim(),
      address: addressController.text.trim(),
    );

    try {
      await ref.read(businessProfileProvider.notifier).updateProfile(
        businessId: businessId,
        model: model,
      );

      if (!mounted) return;

      // ---------------------------------------------------------
      // APP TYPE / THEME
      // ---------------------------------------------------------

      final appType = mapStringToAppType(businessCategory);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'appType',
        appType.name,
      );

      // Immediately update theme
      ref.read(appTypeProvider.notifier).state = appType;

      // ---------------------------------------------------------
      // REFRESH BUSINESS STATE
      // ---------------------------------------------------------

      final token = ref.read(tokenProvider);

      await ref
          .read(businessControllerProvider.notifier)
          .fetchMyBusinesses(token);

      if (!mounted) return;

      CustomDialog.showSuccessSnack(
        context,
        "Profile updated successfully",
      );

      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;

      CustomDialog.showErrorSnack(
        context,
        e.message,
      );
    } catch (e) {
      if (!mounted) return;

      CustomDialog.showErrorSnack(
        context,
        "Something went wrong. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final profileState = ref.watch(businessProfileProvider);

    final isLoading =
        profileState.status == BusinessProfileStatus.loading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // =====================================================
      // FIXED APP BAR
      // =====================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,

        leading: IconButton(
          onPressed: isLoading
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 1),

            Text(
              "Update your business",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // BUSINESS INFORMATION
              // =================================================

              _sectionTitle(
                context,
                icon: Icons.business_outlined,
                title: "Business Information",
                subtitle: "Update your basic business details",
              ),

              const SizedBox(height: 6),

              _card(
                context,
                child: Column(
                  children: [
                    _buildTextField(
                      context,
                      controller: businessNameController,
                      label: "Business Name",
                      hint: "Enter your business name",
                      icon: Icons.storefront_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return "Business name is required";
                        }

                        if (value.trim().length < 2) {
                          return "Enter a valid business name";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildCategoryDropdown(context),
                  ],
                ),
              ),

              // =================================================
              // OTHER BUSINESS TYPE
              // =================================================

              if (selectedCategory == "Other") ...[
                const SizedBox(height: 10),

                _card(
                  context,
                  child: _buildTextField(
                    context,
                    controller: customCategoryController,
                    label: "Specific Business Type",
                    hint:
                    "e.g. Pharmacy, Dental Clinic, Coaching",
                    icon: Icons.category_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (selectedCategory == "Other" &&
                          (value == null ||
                              value.trim().isEmpty)) {
                        return "Please enter your business type";
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 10),

                _infoMessage(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  text:
                  "We'll automatically select the most suitable theme for your business.",
                ),
              ],

              const SizedBox(height: 10),

              // =================================================
              // DOCUMENT
              // =================================================

              _sectionTitle(
                context,
                icon: Icons.verified_outlined,
                title: "Business Verification",
                subtitle: "Update your business document",
              ),

              const SizedBox(height: 14),

              _card(
                context,
                child: _buildTextField(
                  context,
                  controller: documentController,
                  label: "Business Document",
                  hint:
                  "PAN / Aadhaar / registration document",
                  icon: Icons.description_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Document is required";
                    }

                    return null;
                  },
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // ADDRESS
              // =================================================

              _sectionTitle(
                context,
                icon: Icons.location_on_outlined,
                title: "Business Location",
                subtitle: "Where your business operates",
              ),

              const SizedBox(height: 10),

              _card(
                context,
                child: _buildTextField(
                  context,
                  controller: addressController,
                  label: "Business Address",
                  hint: "Enter complete business address",
                  icon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.newline,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Address is required";
                    }

                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // SAVE BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 45,

                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : _saveProfile,

                  style: ElevatedButton.styleFrom(
                    elevation: 0,

                    backgroundColor:
                    theme.primaryColor,

                    disabledBackgroundColor:
                    theme.primaryColor.withOpacity(0.55),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                  ),

                  child: AnimatedSwitcher(
                    duration:
                    const Duration(milliseconds: 200),

                    child: isLoading
                        ? const Row(
                      key: ValueKey("loading"),
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                              Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(width: 12),

                        Text(
                          "Saving Changes...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                        : const Row(
                      key: ValueKey("save"),
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        ),

                        SizedBox(width: 8),

                        Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "Your changes will be saved securely",
                  style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // SECTION TITLE
  // ===============================================================

  Widget _sectionTitle(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,

          decoration: BoxDecoration(
            color:
            theme.primaryColor.withOpacity(0.10),
            borderRadius:
            BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: theme.primaryColor,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style:
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14
                ),
              ),
   
              Text(
                subtitle,
                style:
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // CARD
  // ===============================================================

  Widget _card(
      BuildContext context, {
        required Widget child,
      }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color:
          theme.dividerColor.withOpacity(0.08),
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),

      child: child,
    );
  }

  // ===============================================================
  // TEXT FIELD
  // ===============================================================

  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        required String hint,
        required IconData icon,
        required TextInputAction textInputAction,
        String? Function(String?)? validator,
        int maxLines = 1,
      }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,

      maxLines: maxLines,

      textInputAction: textInputAction,

      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      validator: validator,

      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400,fontWeight: FontWeight.w400),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400,fontWeight: FontWeight.w400),

        prefixIcon: Icon(
          icon,
          size: 21,
        ),

        filled: true,

        fillColor:
        theme.scaffoldBackgroundColor
            .withOpacity(0.55),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide(
            color:
            theme.dividerColor.withOpacity(0.10),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // CATEGORY DROPDOWN
  // ===============================================================

  Widget _buildCategoryDropdown(
      BuildContext context,
      ) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: selectedCategory,

      isExpanded: true,

      decoration: InputDecoration(
        labelText: "Business Category",

        prefixIcon: Icon(
          Icons.category_outlined,
          color: theme.primaryColor,
        ),

        filled: true,

        fillColor:
        theme.scaffoldBackgroundColor
            .withOpacity(0.55),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide(
            color:
            theme.dividerColor.withOpacity(0.10),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 1.5,
          ),
        ),
      ),

      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
      ),

      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,

          child: Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedCategory = value;

          // If user leaves Other,
          // clear the custom category.
          if (value != "Other") {
            customCategoryController.clear();
          }
        });
      },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select business category";
        }

        return null;
      },
    );
  }

  // ===============================================================
  // INFO MESSAGE
  // ===============================================================

  Widget _infoMessage(
      BuildContext context, {
        required IconData icon,
        required String text,
      }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color:
        theme.primaryColor.withOpacity(0.07),

        borderRadius:
        BorderRadius.circular(14),

        border: Border.all(
          color:
          theme.primaryColor.withOpacity(0.12),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 18,
            color: theme.primaryColor,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style:
              theme.textTheme.bodySmall?.copyWith(
                color:
                theme.textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}