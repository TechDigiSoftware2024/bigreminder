import 'package:bigreminder/providers/auth/auth_provider.dart';
import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/screens/auth/location_picker_screen.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:bigreminder/widgets/custom_button.dart';
import 'package:bigreminder/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:bigreminder/theme/super_admin_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../providers/business/business_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../business/business_main.dart';
import '../../providers/auth/auth_state.dart';
import '../../widgets/custom_dropdown.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final bool isFromAdmin;

  const SignupScreen({
    super.key,
    this.isFromAdmin = false,
  });

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final businessNameController = TextEditingController();
  final categoryController = TextEditingController();
  final addressController = TextEditingController();
  String? docFilePath; // image/file optional
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  String? selectedRole;
  late final finalCategory = selectedCategory == "Other"
      ? otherCategoryController.text.trim()
      : selectedCategory;

  String? selectedCategory;
  bool showOtherField = false;

  final TextEditingController otherCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  final List<String> businessCategories = [
    "General Store",
    "Gym",
    "Medical",
    "Salon",
    "Restaurant",
    "Clothing",
    "Other",
  ];

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    businessNameController.dispose();
    categoryController.dispose();
    addressController.dispose();
    super.dispose();
  }

  String _formatError(String? error) {
    if (error == null || error.isEmpty) return '';
    final lower = error.toLowerCase();
    if (lower.contains('email-already-in-use') ||
        lower.contains('already exists'))
      return 'An account with this email already exists.';
    if (lower.contains('invalid-email'))
      return 'Please enter a valid email address.';
    if (lower.contains('weak-password') || lower.contains('password'))
      return 'Password must be at least 6 characters.';
    if (lower.contains('too-many-requests'))
      return 'Too many attempts. Please wait a moment and try again.';
    if (lower.contains('network')) return 'Network error. Check your connection.';
    final cleaned = error.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    return cleaned.isNotEmpty
        ? cleaned
        : 'Something went wrong. Please try again.';
  }

  Future<void> _pickAddressOnMap() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: addressController.text.trim().isEmpty
              ? null
              : addressController.text.trim(),
        ),
      ),
    );
    if (selected == null || selected.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => addressController.text = selected.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    // Errors only — success navigation is handled in the Create Account button
    // so Super Admin create does not race AuthGate into BusinessMain.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        if (!context.mounted) return;
        CustomDialog.showErrorSnack(
          context,
          _formatError(next.error!),
        );
      }
    });
    final size = MediaQuery.of(context).size;
    return SuperAdminTheme.wrap(
      Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: context.brand.white,
            body: isDesktop
                ? _buildDesktopLayout(context)
                : _buildMobileLayout(context),
          );
        },
      ),
    );
    // return Scaffold(
    //   backgroundColor: context.brand.background,
    //   body: Form(
    //     key: _formKey,
    //     child: Container(
    //       width: double.infinity,
    //       height: double.infinity,
    //       decoration: BoxDecoration(
    //         color: context.brand.background,
    //       ),
    //       child: Stack(
    //         children: [
    //           // ── Main content ──
    //           SafeArea(
    //             child: SingleChildScrollView(
    //               padding: const EdgeInsets.symmetric(horizontal: 24),
    //               child: Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   const SizedBox(height: 40),
    //
    //                   // Headline with primary dark color
    //                   const Text(
    //                     "Create an Account",
    //                     style: TextStyle(
    //                       fontSize: 36,
    //                       fontWeight: FontWeight.w800,
    //                       color: context.brand.primaryDark,
    //                       height: 1.15,
    //                       letterSpacing: -0.5,
    //                     ),
    //                   ),
    //                   const SizedBox(height: 8),
    //                   Text(
    //                     "Start your productivity journey today",
    //                     style: TextStyle(
    //                       color: context.brand.textSecondary,
    //                       fontSize: 14.5,
    //                     ),
    //                   ),
    //
    //                   const SizedBox(height: 36),
    //
    //                   // ── Form card with blue border ──
    //                   Container(
    //                     decoration: BoxDecoration(
    //                       color: context.brand.background,
    //                       borderRadius: BorderRadius.circular(16),
    //                       border: Border.all(
    //                         color: context.brand.border,
    //                         width: 1.5,
    //                       ),
    //                       boxShadow: [
    //                         BoxShadow(
    //                           color: context.colors.primary.withOpacity(0.08),
    //                           blurRadius: 20,
    //                           offset: const Offset(0, 4),
    //                         ),
    //                       ],
    //                     ),
    //                     child: Padding(
    //                       padding: const EdgeInsets.all(20),
    //                       child: Column(
    //                         children: [
    //                           CustomTextField(
    //                             controller: nameController,
    //                             hint: "Full Name",
    //                             icon: Icons.person_outline_rounded,
    //                             keyboardType: TextInputType.name,
    //                             validator: (value){
    //                               if(value == null || value.isEmpty){
    //                                 return "Name is required";
    //                               }
    //                               final name = value.trim();
    //
    //                               if(name.length < 2){
    //                                 return "Name must be at least 2 characters";
    //                               }
    //                               if(!RegExp(r"^[a-z A-z]+$").hasMatch(name)){
    //                                 return "Only letters are allowed";
    //                               }
    //                               return null;
    //                             },
    //                           ),
    //                           const SizedBox(height: 6),
    //                           CustomTextField(
    //                             controller: businessNameController,
    //                             hint: "Business Name",
    //                             icon: Icons.storefront_outlined,
    //                             validator: (value) {
    //                               if (value == null || value.isEmpty) {
    //                                 return "Business name required";
    //                               }
    //                               return null;
    //                             },
    //                           ),
    //
    //                           const SizedBox(height: 6),
    //
    //                           Column(
    //                             crossAxisAlignment: CrossAxisAlignment.start,
    //                             children: [
    //                               /// ===== CATEGORY DROPDOWN =====
    //                               CustomDropdown(
    //                                 roles: businessCategories,
    //                                 selectedRole: selectedCategory,
    //                                 hint: "Select Business Category",
    //                                 onChanged: (value) {
    //                                   setState(() {
    //                                     selectedCategory = value;
    //
    //                                     // 🔥 CORE LOGIC
    //                                     showOtherField = value == "Other";
    //
    //                                     // optional reset
    //                                     if (!showOtherField) {
    //                                       otherCategoryController.clear();
    //                                     }
    //                                   });
    //                                 },
    //                                 validator: (value) =>
    //                                 value == null ? "Please select category" : null,
    //                               ),
    //
    //                               /// ===== OTHER FIELD =====
    //                               if (showOtherField)
    //                                 Padding(
    //                                   padding: const EdgeInsets.only(top: 12),
    //                                   child: TextFormField(
    //                                     controller: otherCategoryController,
    //                                     style: TextStyle(
    //                                       color: context.colors.onSurface,
    //                                     ),
    //                                     decoration: InputDecoration(
    //                                       hintText: "Enter your business category",
    //                                       hintStyle: TextStyle(
    //                                         color: context.brand.textHint,
    //                                       ),
    //                                       filled: true,
    //                                       fillColor: context.colors.primary.withOpacity(0.03),
    //                                       border: OutlineInputBorder(
    //                                         borderRadius: BorderRadius.circular(12),
    //                                         borderSide: BorderSide(
    //                                           color: context.brand.border,
    //                                         ),
    //                                       ),
    //                                       enabledBorder: OutlineInputBorder(
    //                                         borderRadius: BorderRadius.circular(12),
    //                                         borderSide: BorderSide(
    //                                           color: context.brand.border,
    //                                         ),
    //                                       ),
    //                                       focusedBorder: OutlineInputBorder(
    //                                         borderRadius: BorderRadius.circular(12),
    //                                         borderSide: BorderSide(
    //                                           color: context.colors.primary,
    //                                           width: 2,
    //                                         ),
    //                                       ),
    //                                       errorBorder: OutlineInputBorder(
    //                                         borderRadius: BorderRadius.circular(12),
    //                                         borderSide: BorderSide(
    //                                           color: context.colors.error,
    //                                         ),
    //                                       ),
    //                                       focusedErrorBorder: OutlineInputBorder(
    //                                         borderRadius: BorderRadius.circular(12),
    //                                         borderSide: BorderSide(
    //                                           color: context.colors.error,
    //                                           width: 2,
    //                                         ),
    //                                       ),
    //                                     ),
    //                                     validator: (value) {
    //                                       if (showOtherField && (value == null || value.trim().isEmpty)) {
    //                                         return "Please enter your business type";
    //                                       }
    //                                       return null;
    //                                     },
    //                                   ),
    //                                 ),
    //                             ],
    //                           ),
    //
    //                           const SizedBox(height: 6),
    //
    //                           CustomTextField(
    //                             controller: addressController,
    //                             hint: "Address",
    //                             icon: Icons.location_on_outlined,
    //                           ),
    //                           const SizedBox(height: 6),
    //                           CustomTextField(
    //                             controller: phoneController,
    //                             hint: "Phone number",
    //                             icon: Icons.phone_outlined,
    //                             keyboardType: TextInputType.phone,
    //                             digitsOnly: true,
    //                             inputFormatters: [
    //                               LengthLimitingTextInputFormatter(10)
    //                             ],
    //                             validator: (value) {
    //                               if (value == null || value.trim().isEmpty) {
    //                                 return "Phone is required";
    //                               }
    //
    //                               final regex = RegExp(r'^[6-9]\d{9}$');
    //
    //                               if (!regex.hasMatch(value.trim())) {
    //                                 return "Enter a valid 10-digit phone number";
    //                               }
    //
    //                               return null;
    //                             },
    //                           ),
    //                           const SizedBox(height: 6),
    //                           CustomTextField(
    //                             controller: passwordController,
    //                             hint: "Password",
    //                             icon: Icons.lock_outline_rounded,
    //                             obscure: _obscurePassword,
    //                             validator: (value){
    //                               if(value == null || value.isEmpty){
    //                                 return "Password is required";
    //                               }
    //                               if(value.length < 6){
    //                                 return "Password must be at least 6 characters";
    //                               }
    //                               if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@]{6,}$')
    //                                   .hasMatch(value)) {
    //                                 return "Password must contain letters and numbers";
    //                               }
    //                               return null;
    //                             },
    //                             trailing: GestureDetector(
    //                               onTap: () => setState(
    //                                       () => _obscurePassword = !_obscurePassword),
    //                               child: Icon(
    //                                 _obscurePassword
    //                                     ? Icons.visibility_off_outlined
    //                                     : Icons.visibility_outlined,
    //                                 color: context.colors.primary,
    //                                 size: 20,
    //                               ),
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                   ),
    //
    //                   const SizedBox(height: 20),
    //
    //                   // ── Signup Button with primary color ──
    //                   Consumer(
    //                     builder: (context, ref, _) {
    //                       final state = ref.watch(authControllerProvider);
    //
    //                       return CustomButton(
    //                         backgroundColor: context.colors.primary,
    //                         label: "Create Account",
    //                         isLoading: state.isLoading,
    //                         onTap: state.isLoading
    //                             ? null
    //                             : () async {
    //                           if (!_formKey.currentState!.validate()) return;
    //
    //                           final authController =
    //                           ref.read(authControllerProvider.notifier);
    //
    //                           final businessController =
    //                           ref.read(businessControllerProvider.notifier);
    //
    //                           /// ================= STEP 1: SIGNUP =================
    //                           await authController.signup(
    //                             ownerName: nameController.text.trim(),
    //                             phone: phoneController.text.trim(),
    //                             password: passwordController.text.trim(),
    //                             businessName: businessNameController.text.trim(),
    //                             businessCategory: finalCategory ?? "general",
    //                             address: addressController.text.trim(),
    //                             doc: docFilePath ?? "",
    //                           );
    //
    //                           final authState = ref.read(authControllerProvider);
    //
    //                           if (authState.user == null || authState.token == null) {
    //                             ScaffoldMessenger.of(context).showSnackBar(
    //                               SnackBar(
    //                                 content: const Text("Signup failed"),
    //                                 backgroundColor: context.colors.error,
    //                                 behavior: SnackBarBehavior.floating,
    //                                 shape: RoundedRectangleBorder(
    //                                   borderRadius: BorderRadius.circular(10),
    //                                 ),
    //                               ),
    //                             );
    //                             return;
    //                           }
    //
    //                           final token = authState.token!;
    //
    //                           /// ================= STEP 2: CHECK EXISTING BUSINESS =================
    //                           await businessController.fetchMyBusinesses(token);
    //
    //                           final businessState = ref.read(businessControllerProvider);
    //
    //                           /// 🔥 PREVENT DUPLICATE (CORE FIX)
    //                           if (businessState.businesses.isNotEmpty) {
    //                             print("⚠️ Business already exists, skipping creation");
    //                           } else {
    //                             /// ================= CREATE ONLY IF NOT EXISTS =================
    //                             await businessController.createBusiness(
    //                               name: businessNameController.text.trim(),
    //                               category: finalCategory ?? "general",
    //                               address: addressController.text.trim(),
    //                               doc: docFilePath ?? "",
    //                               userId: int.parse(authState.user!.userId),
    //                               planId: 1,
    //                             );
    //
    //                             /// fetch again after create
    //                             await businessController.fetchMyBusinesses(token);
    //                           }
    //
    //                           final updatedState = ref.read(businessControllerProvider);
    //
    //                           if (updatedState.businesses.isEmpty) {
    //                             ScaffoldMessenger.of(context).showSnackBar(
    //                               SnackBar(
    //                                 content: const Text("Business setup failed"),
    //                                 backgroundColor: context.colors.error,
    //                                 behavior: SnackBarBehavior.floating,
    //                                 shape: RoundedRectangleBorder(
    //                                   borderRadius: BorderRadius.circular(10),
    //                                 ),
    //                               ),
    //                             );
    //                             return;
    //                           }
    //
    //                           final business = updatedState.businesses.first;
    //
    //                           final appType =
    //                           mapStringToAppType(business.category ?? "General");
    //
    //                           /// ================= SAVE =================
    //                           final prefs = await SharedPreferences.getInstance();
    //
    //                           await prefs.setString("appType", appType.name);
    //                           await prefs.setString(
    //                               "businessCategory", business.category ?? "General");
    //
    //                           ref.read(appTypeProvider.notifier).state = appType;
    //
    //                           if (!context.mounted) return;
    //
    //                           /// ================= NAVIGATE =================
    //                           if (widget.isFromAdmin) {
    //                             /// 🔥 ADMIN FLOW
    //                             ScaffoldMessenger.of(context).showSnackBar(
    //                               SnackBar(
    //                                 content: const Text("Business account created successfully ✅"),
    //                                 backgroundColor: context.colors.primary,
    //                                 behavior: SnackBarBehavior.floating,
    //                                 shape: RoundedRectangleBorder(
    //                                   borderRadius: BorderRadius.circular(10),
    //                                 ),
    //                               ),
    //                             );
    //
    //                             Navigator.pop(context, true); // 🔥 go back to admin
    //                           } else {
    //                             /// 🔥 NORMAL USER FLOW
    //                             Navigator.pushAndRemoveUntil(
    //                               context,
    //                               MaterialPageRoute(builder: (_) => const BusinessMain()),
    //                                   (route) => false,
    //                             );
    //                           }
    //                         },
    //                       );
    //                     },
    //                   ),
    //
    //                   const SizedBox(height: 10),
    //
    //                   // Terms hint with primary color
    //                   Center(
    //                     child: Text(
    //                       "By signing up, you agree to our Terms & Privacy Policy",
    //                       textAlign: TextAlign.center,
    //                       style: TextStyle(
    //                         color: context.brand.textHint,
    //                         fontSize: 11.5,
    //                       ),
    //                     ),
    //                   ),
    //
    //                   const SizedBox(height: 10),
    //
    //                   // Navigate to Login with primary color
    //                   Center(
    //                     child: GestureDetector(
    //                       onTap: () => Navigator.push(
    //                         context,
    //                         MaterialPageRoute(
    //                             builder: (_) => LoginScreen()),
    //                       ),
    //                       child: RichText(
    //                         text: TextSpan(
    //                           text: "Already have an account? ",
    //                           style: TextStyle(
    //                             color: context.brand.textSecondary,
    //                             fontSize: 14,
    //                           ),
    //                           children: const [
    //                             TextSpan(
    //                               text: "Sign In",
    //                               style: TextStyle(
    //                                 color: context.colors.primary,
    //                                 fontWeight: FontWeight.bold,
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                       ),
    //                     ),
    //                   ),
    //                   const SizedBox(height: 32),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
  Widget _buildMobileLayout(BuildContext context) {
    return Form(
      key: _formKey,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Text(
                "Create an Account",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: context.brand.primaryDark,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Start your productivity journey today",
                style: TextStyle(
                  color: context.brand.textSecondary,
                  fontSize: 14.5,
                ),
              ),

              const SizedBox(height: 36),

              Container(
                decoration: BoxDecoration(
                  color: context.brand.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.brand.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: _buildSignupFields(context),
              ),

              const SizedBox(height: 20),

              _buildSignupButton(),

              const SizedBox(height: 10),

              _buildTerms(context),

              const SizedBox(height: 10),

              _buildLoginLink(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1150,
          maxHeight: 760,
        ),
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: context.brand.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.brand.border,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withOpacity(0.08),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // ================= LEFT =================

              Expanded(
                flex: 4,
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.all(55),
                  color: context.colors.primary.withOpacity(0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.business_center_rounded,
                          color: context.brand.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        "Biz Reminder",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: context.brand.primaryDark,
                          letterSpacing: -1,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        "Everything you need to\nmanage your business smarter.",
                        style: TextStyle(
                          fontSize: 19,
                          height: 1.45,
                          color: context.brand.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 38),

                      _desktopFeature(
                        context,
                        Icons.notifications_active_outlined,
                        "Remind customers at the right time",
                      ),

                      const SizedBox(height: 16),

                      _desktopFeature(
                        context,
                        Icons.receipt_long_outlined,
                        "Make billing simple and easy",
                      ),

                      const SizedBox(height: 16),

                      _desktopFeature(
                        context,
                        Icons.campaign_outlined,
                        "Keep customers updated with offers",
                      ),

                      const SizedBox(height: 16),

                      _desktopFeature(
                        context,
                        Icons.payments_outlined,
                        "Follow up on pending payments",
                      ),
                    ],
                  ),
                ),
              ),

              // ================= RIGHT =================

              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 55,
                    vertical: 35,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create an Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: context.brand.primaryDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Start your productivity journey today",
                          style: TextStyle(
                            color: context.brand.textSecondary,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _buildSignupFields(context),

                        const SizedBox(height: 20),

                        _buildSignupButton(),

                        const SizedBox(height: 10),

                        _buildTerms(context),

                        const SizedBox(height: 10),

                        _buildLoginLink(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupFields(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: nameController,
          hint: "Full Name",
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Name is required";
            }

            final name = value.trim();

            if (name.length < 2) {
              return "Name must be at least 2 characters";
            }

            if (!RegExp(r"^[a-z A-z]+$").hasMatch(name)) {
              return "Only letters are allowed";
            }

            return null;
          },
        ),

        const SizedBox(height: 6),

        CustomTextField(
          controller: businessNameController,
          hint: "Business Name",
          icon: Icons.storefront_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Business name required";
            }

            return null;
          },
        ),

        const SizedBox(height: 6),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdown(
              roles: businessCategories,
              selectedRole: selectedCategory,
              hint: "Select Business Category",
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                  showOtherField = value == "Other";

                  if (!showOtherField) {
                    otherCategoryController.clear();
                  }
                });
              },
              validator: (value) {
                return value == null
                    ? "Please select category"
                    : null;
              },
            ),

            if (showOtherField)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextFormField(
                  controller: otherCategoryController,
                  style: TextStyle(
                    color: context.colors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter your business category",
                    hintStyle: TextStyle(
                      color: context.brand.textHint,
                    ),
                    filled: true,
                    fillColor: context.colors.primary.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.brand.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.brand.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colors.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (showOtherField &&
                        (value == null || value.trim().isEmpty)) {
                      return "Please enter your business type";
                    }

                    return null;
                  },
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        CustomTextField(
          controller: addressController,
          hint: "Address",
          icon: Icons.location_on_outlined,
          trailing: GestureDetector(
            onTap: _pickAddressOnMap,
            child: Icon(
              Icons.map_outlined,
              color: context.colors.primary,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 6),

        CustomTextField(
          controller: phoneController,
          hint: "Phone number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          digitsOnly: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Phone is required";
            }

            final regex = RegExp(r'^[6-9]\d{9}$');

            if (!regex.hasMatch(value.trim())) {
              return "Enter a valid 10-digit phone number";
            }

            return null;
          },
        ),

        const SizedBox(height: 6),

        CustomTextField(
          controller: passwordController,
          hint: "Password",
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Password is required";
            }

            if (value.length < 6) {
              return "Password must be at least 6 characters";
            }

            if (!RegExp(
              r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@]{6,}$',
            ).hasMatch(value)) {
              return "Password must contain letters and numbers";
            }

            return null;
          },
          trailing: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: context.colors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(authControllerProvider);

        return SizedBox(
          width: double.infinity,
          child: CustomButton(
            backgroundColor: context.colors.primary,
            label: "Create Account",
            isLoading: state.isLoading,
            onTap: state.isLoading
                ? null
                : () async {
              // ================= VALIDATION =================

              if (!_formKey.currentState!.validate()) {
                return;
              }

              final authController =
              ref.read(authControllerProvider.notifier);

              final businessController =
              ref.read(businessControllerProvider.notifier);

              // ================= STEP 1: SIGNUP =================
              // Super Admin create keeps admin logged in (AuthGate stays on
              // SuperAdminMain). Normal signup replaces session → BusinessMain.

              final createdUser = await authController.signup(
                ownerName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                password: passwordController.text.trim(),
                businessName: businessNameController.text.trim(),
                businessCategory: finalCategory ?? "general",
                address: addressController.text.trim(),
                doc: docFilePath ?? "",
                replaceSession: !widget.isFromAdmin,
              );

              final authState = ref.read(authControllerProvider);

              if (authState.error != null || createdUser == null) {
                return;
              }

              if (createdUser.accessToken == null ||
                  createdUser.accessToken!.isEmpty) {
                return;
              }

              final token = createdUser.accessToken!;
              final ownerUserId = createdUser.userId;

              // ================= STEP 2: FETCH BUSINESS =================

              await businessController.fetchMyBusinesses(token);

              final businessState =
                  ref.read(businessControllerProvider);

              if (businessState.businesses.isNotEmpty) {
                debugPrint(
                  "Business already exists, skipping creation",
                );
              } else {
                await businessController.createBusiness(
                  name: businessNameController.text.trim(),
                  category: finalCategory ?? "general",
                  address: addressController.text.trim(),
                  doc: docFilePath ?? "",
                  userId: int.parse(ownerUserId),
                  planId: 1,
                );

                await businessController.fetchMyBusinesses(token);
              }

              final updatedState =
                  ref.read(businessControllerProvider);

              if (updatedState.businesses.isEmpty) {
                if (widget.isFromAdmin) {
                  await authController.persistCurrentSession();
                }
                return;
              }

              final business = updatedState.businesses.first;

              final appType = mapStringToAppType(
                business.category ?? "General",
              );

              final prefs = await SharedPreferences.getInstance();

              if (widget.isFromAdmin) {
                // Drop owner session leftovers; restore admin token in prefs.
                await prefs.remove("businessId");
                await prefs.remove("appType");
                await prefs.remove("businessCategory");
                await authController.persistCurrentSession();

                if (!context.mounted) return;

                CustomDialog.showSuccessSnack(
                  context,
                  "Business account created successfully",
                );
                Navigator.pop(context, true);
              } else {
                await prefs.setString("appType", appType.name);
                await prefs.setString(
                  "businessCategory",
                  business.category ?? "General",
                );
                ref.read(appTypeProvider.notifier).state = appType;

                if (!context.mounted) return;

                // AuthGate also switches to BusinessMain; this covers nested nav.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BusinessMain(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        );
      },
    );
  }
  Widget _buildTerms(BuildContext context) {
    return Center(
      child: Text(
        "By signing up, you agree to our Terms & Privacy Policy",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.brand.textHint,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            SuperAdminTheme.route(const LoginScreen()),
          );
        },
        child: RichText(
          text: TextSpan(
            text: "Already have an account? ",
            style: TextStyle(
              color: context.brand.textSecondary,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: "Sign In",
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopFeature(
      BuildContext context,
      IconData icon,
      String text,
      ) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: context.colors.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 14),

        Text(
          text,
          style: TextStyle(
            color: context.brand.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}