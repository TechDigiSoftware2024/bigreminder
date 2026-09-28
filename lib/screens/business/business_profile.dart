import 'package:bigreminder/providers/business/business_profile_state.dart';
import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/screens/about_app_screen.dart';
import 'package:bigreminder/screens/business/business_query_screen.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/business_models/businesss_edit_profile_model.dart';
import '../../models/super_admin_models/business_list_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/business/business_provider.dart';
import '../../services/business/business_service.dart';

class BusinessProfile extends ConsumerStatefulWidget {
  const BusinessProfile({super.key});

  @override
  ConsumerState<BusinessProfile> createState() => _BusinessProfileState();
}

class _BusinessProfileState extends ConsumerState<BusinessProfile> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController businessNameController;
  late final TextEditingController documentController;
  late final TextEditingController addressController;
  late final TextEditingController customCategoryController;

  String? selectedCategory;
  bool _initialized = false;

  final List<String> categories = const [
    'Gym',
    'Shop',
    'Institute',
    'Salon',
    'Hospital',
    'Restaurant',
    'Finance',
    'Real Estate',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    businessNameController = TextEditingController();
    documentController = TextEditingController();
    addressController = TextEditingController();
    customCategoryController = TextEditingController();
  }

  void _syncFormFromBusiness(Business? business, String businessName) {
    if (_initialized || business == null) return;
    _initialized = true;

    businessNameController.text = businessName;
    documentController.text = business.doc ?? '';
    addressController.text = business.address;

    selectedCategory =
        categories.contains(business.category) ? business.category : 'Other';

    if (selectedCategory == 'Other') {
      customCategoryController.text = business.category;
    }
  }

  void _resetFormFromBusiness(Business? business, String businessName) {
    if (business == null) return;

    setState(() {
      businessNameController.text = businessName;
      documentController.text = business.doc ?? '';
      addressController.text = business.address;
      selectedCategory =
          categories.contains(business.category) ? business.category : 'Other';
      customCategoryController.text =
          selectedCategory == 'Other' ? business.category : '';
    });
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
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final businessId = ref.read(businessIdProvider);
    final businessCategory = selectedCategory == 'Other'
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

      final profileState = ref.read(businessProfileProvider);
      if (profileState.status == BusinessProfileStatus.error) {
        throw ApiException(
          profileState.errorMessage ?? 'Failed to update profile',
        );
      }

      if (!mounted) return;

      final appType = mapStringToAppType(businessCategory);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appType', appType.name);
      ref.read(appTypeProvider.notifier).state = appType;

      final token = ref.read(tokenProvider);
      await ref
          .read(businessControllerProvider.notifier)
          .fetchMyBusinesses(token);

      if (!mounted) return;

      CustomDialog.showSuccessSnack(context, 'Profile updated successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _logout() async {
    CustomDialog.showConfirmDialog(
      context: context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to logout from Biz Reminder?',
      onConfirm: () async {
        try {
          await ref.read(authControllerProvider.notifier).logout();
          ref.invalidate(businessControllerProvider);
        } catch (e) {
          if (mounted) {
            CustomDialog.showErrorSnack(context, 'Logout failed: $e');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final businessName = ref.watch(businessNameProvider);
    final business = ref.watch(currentBusinessProvider);
    final phone = ref.watch(businessPhoneProvider);
    final profileState = ref.watch(businessProfileProvider);
    final isSaving = profileState.status == BusinessProfileStatus.loading;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    _syncFormFromBusiness(business, businessName);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: isDesktop
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _ProfileOverviewPanel(
                        businessName: businessName,
                        business: business,
                        phone: phone,
                        onSupport: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessQueryScreen(),
                            ),
                          );
                        },
                        onAbout: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutAppScreen(),
                            ),
                          );
                        },
                        onLogout: _logout,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _ProfileEditPanel(
                        formKey: _formKey,
                        businessNameController: businessNameController,
                        documentController: documentController,
                        addressController: addressController,
                        customCategoryController: customCategoryController,
                        categories: categories,
                        selectedCategory: selectedCategory,
                        isSaving: isSaving,
                        onCategoryChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                            if (value != 'Other') {
                              customCategoryController.clear();
                            }
                          });
                        },
                        onReset: () =>
                            _resetFormFromBusiness(business, businessName),
                        onSave: _saveProfile,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _ProfileOverviewPanel(
                    businessName: businessName,
                    business: business,
                    phone: phone,
                    onSupport: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusinessQueryScreen(),
                        ),
                      );
                    },
                    onAbout: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutAppScreen(),
                        ),
                      );
                    },
                    onLogout: _logout,
                  ),
                  const SizedBox(height: 14),
                  _ProfileEditPanel(
                    formKey: _formKey,
                    businessNameController: businessNameController,
                    documentController: documentController,
                    addressController: addressController,
                    customCategoryController: customCategoryController,
                    categories: categories,
                    selectedCategory: selectedCategory,
                    isSaving: isSaving,
                    onCategoryChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        if (value != 'Other') {
                          customCategoryController.clear();
                        }
                      });
                    },
                    onReset: () =>
                        _resetFormFromBusiness(business, businessName),
                    onSave: _saveProfile,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// OVERVIEW (LEFT)
// ============================================================================

class _ProfileOverviewPanel extends StatelessWidget {
  final String businessName;
  final Business? business;
  final String phone;
  final VoidCallback onSupport;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const _ProfileOverviewPanel({
    required this.businessName,
    required this.business,
    required this.phone,
    required this.onSupport,
    required this.onAbout,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        businessName.trim().isNotEmpty ? businessName.trim()[0].toUpperCase() : 'B';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            business?.category.isNotEmpty == true
                                ? business!.category
                                : 'Business',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (business?.isActive ?? false)
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (business?.isActive ?? false) ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Business Details',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick view of your business info',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Business ID',
                value: business?.id.toString() ?? 'N/A',
              ),
              _InfoRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: business?.category.isNotEmpty == true
                    ? business!.category
                    : 'N/A',
              ),
              _InfoRow(
                icon: Icons.description_outlined,
                label: 'Document',
                value: (business?.doc?.isNotEmpty == true)
                    ? business!.doc!
                    : 'Not added',
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: business?.address.isNotEmpty == true
                    ? business!.address
                    : 'N/A',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & More',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.support_agent_rounded,
                title: 'Support Center',
                subtitle: 'Ask questions & get help',
                onTap: onSupport,
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                subtitle: 'Version & app information',
                onTap: onAbout,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD64545),
                    side: BorderSide(
                      color: const Color(0xFFD64545).withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xffFAFBFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: cs.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EDIT (RIGHT)
// ============================================================================

class _ProfileEditPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController businessNameController;
  final TextEditingController documentController;
  final TextEditingController addressController;
  final TextEditingController customCategoryController;
  final List<String> categories;
  final String? selectedCategory;
  final bool isSaving;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _ProfileEditPanel({
    required this.formKey,
    required this.businessNameController,
    required this.documentController,
    required this.addressController,
    required this.customCategoryController,
    required this.categories,
    required this.selectedCategory,
    required this.isSaving,
    required this.onCategoryChanged,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit_outlined, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Update your business details here',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _fieldLabel('Business Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: businessNameController,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                if (value.trim().length < 2) {
                  return 'Enter a valid business name';
                }
                return null;
              },
              decoration: _inputDecoration(
                context,
                hint: 'Enter business name',
                icon: Icons.storefront_outlined,
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Business Category'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedCategory ?? 'none'),
              initialValue: selectedCategory,
              isExpanded: true,
              onChanged: isSaving ? null : onCategoryChanged,
              decoration: _inputDecoration(
                context,
                hint: 'Select category',
                icon: Icons.category_outlined,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select business category';
                }
                return null;
              },
            ),
            if (selectedCategory == 'Other') ...[
              const SizedBox(height: 12),
              _fieldLabel('Specific Business Type'),
              const SizedBox(height: 6),
              TextFormField(
                controller: customCategoryController,
                enabled: !isSaving,
                textInputAction: TextInputAction.next,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                validator: (value) {
                  if (selectedCategory == 'Other' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter your business type';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  context,
                  hint: 'e.g. Pharmacy, Coaching',
                  icon: Icons.auto_awesome_outlined,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Theme will match your business type automatically.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.75),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _fieldLabel('Business Document'),
            const SizedBox(height: 6),
            TextFormField(
              controller: documentController,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              validator: (value) {
                // if (value == null || value.trim().isEmpty) {
                //   return 'Document is required';
                // }
                return null;
              },
              decoration: _inputDecoration(
                context,
                hint: 'PAN / Aadhaar / registration',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Business Address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: addressController,
              enabled: !isSaving,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
              decoration: _inputDecoration(
                context,
                hint: 'Enter complete address',
                icon: Icons.location_on_outlined,
                alignTop: true,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : onReset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey,width: 0.6)
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: cs.primary,
                      disabledBackgroundColor:
                          cs.primary.withValues(alpha: 0.55),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
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
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    bool alignTop = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: alignTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Icon(icon, color: cs.primary, size: 20),
            )
          : Icon(icon, color: cs.primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }
}
