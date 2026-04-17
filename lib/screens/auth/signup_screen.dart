import 'package:bigreminder/providers/auth/auth_provider.dart';
import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/widgets/custom_card.dart';
import 'package:bigreminder/widgets/custom_button.dart';
import 'package:bigreminder/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../constants/business_main.dart';
import '../../providers/auth/auth_state.dart';
import '../../widgets/custom_dropdown.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

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
  @override
  Widget build(BuildContext context) {

    ref.listen<AuthState>(authControllerProvider, (prev, next) {

      /// ================= ERROR =================
      if (next.error != null && next.error != prev?.error) {
        final msg = _formatError(next.error!);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
      }

      /// ================= SUCCESS =================
      final isSuccess =
          prev?.isLoading == true &&
              next.isLoading == false &&
              next.user != null &&
              next.error == null;

      if (isSuccess) {
        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => BusinessMain()),
              (route) => false,
        );
      }
    });
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFAFAFA),
                Color(0xFFF5F5F5),
                Color(0xFFFFFFFF),
              ]
            ),
          ),
          child: Stack(
            children: [
              // ── Main content ──
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Headline
                      const Text(
                        "Create an Account",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Start your productivity journey today",
                        style: TextStyle(
                          color: Colors.blueGrey.withOpacity(0.8),
                          fontSize: 14.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Glass form card ──
                      CustomCard(
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: nameController,
                              hint: "Full Name",
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              validator: (value){
                                if(value == null || value.isEmpty){
                                  return "Name is required";
                                }
                                final name = value.trim();

                                if(name.length < 2){
                                  return "Name must be at least 2 characters";
                                }
                                if(!RegExp(r"^[a-z A-z]+$").hasMatch(name)){
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

                                /// ===== CATEGORY DROPDOWN =====
                                CustomDropdown(
                                  roles: businessCategories,
                                  selectedRole: selectedCategory,
                                  hint: "Select Business Category",
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value;

                                      // 🔥 CORE LOGIC
                                      showOtherField = value == "Other";

                                      // optional reset
                                      if (!showOtherField) {
                                        otherCategoryController.clear();
                                      }
                                    });
                                  },
                                  validator: (value) =>
                                  value == null ? "Please select category" : null,
                                ),

                                /// ===== OTHER FIELD =====
                                if (showOtherField)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: TextFormField(
                                      controller: otherCategoryController,
                                      decoration: InputDecoration(
                                        hintText: "Enter your business category",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (showOtherField && (value == null || value.trim().isEmpty)) {
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
                            ),
                            const SizedBox(height: 6),
                            CustomTextField(
                              controller: emailController,
                              hint: "Enter PAN or AADHAAR  number",
                              icon: Icons.document_scanner_outlined,
                              keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "PAN or Aadhaar number is required";
                                  }
                                  final input = value.trim().toUpperCase();
                                  // 🔥 Aadhaar → 12 digits
                                  final aadhaarRegex = RegExp(r'^\d{12}$');
                                  // 🔥 PAN → 5 letters + 4 digits + 1 letter
                                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                                  if (aadhaarRegex.hasMatch(input) || panRegex.hasMatch(input)) {
                                    return null; // ✅ valid
                                  }
                                  return "Enter valid PAN or Aadhaar";
                                }
                            ),
                            const SizedBox(height: 6),
                            CustomTextField(
                              controller: phoneController,
                              hint: "Phone number",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Phone number is required";
                                }

                                if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) {
                                  return "Enter a valid phone number (8–15 digits)";
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            // CustomDropdown(
                            //   roles: ["staff",""],
                            //   selectedRole: selectedRole,
                            //   onChanged: (value) {
                            //     selectedRole = value;
                            //   },
                            //   validator: (value) {
                            //     if (value == null || value.isEmpty) {
                            //       return "Please select a role";
                            //     }
                            //     return null;
                            //   },
                            // ),
                           // const SizedBox(height: 14),
                            CustomTextField(
                              controller: passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePassword,
                              validator: (value){
                                if(value == null || value.isEmpty){
                                  return "Password is required";
                                }
                                if(value.length < 6){
                                  return "Password must be at least 6 characters";
                                }
                                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@]{6,}$')
                                    .hasMatch(value)) {
                                  return "Password must contain letters and numbers";
                                }
                                return null;
                              },
                              trailing: GestureDetector(
                                onTap: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.blueGrey,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Signup Button ──
                      Consumer(
                        builder: (context, ref, _) {
                          final state = ref.watch(authControllerProvider);

                          return CustomButton(
                            backgroundColor: Colors.grey,
                            label: "Create Account",
                            isLoading: state.isLoading,
                            onTap: state.isLoading
                                ? null
                                : () async {
                              if (!_formKey.currentState!.validate()) return;

                              await ref.read(authControllerProvider.notifier).signup(
                                ownerName: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                password: passwordController.text.trim(),
                                businessName: businessNameController.text.trim(),
                                businessCategory: finalCategory ?? "general",
                                address: addressController.text.trim(),
                                doc: docFilePath ?? "",
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      // Terms hint
                      Center(
                        child: Text(
                          "By signing up, you agree to our Terms & Privacy Policy",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueGrey.withOpacity(0.8),
                            fontSize: 11.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Navigate to Login
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LoginScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: Colors.blueGrey.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

