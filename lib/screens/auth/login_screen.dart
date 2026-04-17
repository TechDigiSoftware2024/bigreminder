import 'package:bigreminder/providers/auth/auth_provider.dart';
import 'package:bigreminder/screens/auth/signup_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/super_admin_main.dart';
import 'package:bigreminder/widgets/custom_card.dart';
import 'package:bigreminder/widgets/custom_button.dart';
import 'package:bigreminder/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../constants/business_main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _formatError(String? error) {
    if (error == null || error.isEmpty) return '';
    // Firebase / generic error cleanup
    final lower = error.toLowerCase();
    if (lower.contains('user-not-found') || lower.contains('no user record')) {
      return 'No account found with this email.';
    }
    if (lower.contains('wrong-password') || lower.contains('invalid credential')) {
      return 'Incorrect password. Please try again.';
    }
    if (lower.contains('invalid-email')) return 'Please enter a valid email address.';
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('network')) return 'Network error. Check your connection.';
    if (lower.contains('user-disabled')) return 'This account has been disabled.';
    // strip firebase prefix
    final cleaned = error.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    return cleaned.isNotEmpty ? cleaned : 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // Listen for errors
    ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        final msg = _formatError(next.error.toString());
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }

      if (prev?.isLoading == true &&
          next.isLoading == false &&
          next.user != null &&
          next.error == null) {

        final role = next.user!.role; // 👈 from API

        if (role == 'super_admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => SuperAdminMain()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BusinessMain()),
                (route) => false,
          );
        }
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
              ],
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
                      const SizedBox(height: 70),

                      // Headline
                      const Text(
                        "Welcome to \nBiz Reminder ",
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
                        "Sign in to pick up where you left off",
                        style: TextStyle(
                          color: Colors.blueGrey.withOpacity(0.7),
                          fontSize: 14.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Glass Card ──
                      CustomCard(
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: phoneController,
                              hint: "Phone number",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Phone is required";
                                }
                                final regex = RegExp(r'^[6-9][0-9]{9}$');
                                if (!regex.hasMatch(value)) {
                                  return "Enter a valid 10-digit phone number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
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
                                  return "Minimum 6 characters required";
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

                      const SizedBox(height: 14),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.blueGrey.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Login Button ──
                      Consumer(
                        builder: (context, ref, _) {

                          final isLoading = ref.watch(
                            authControllerProvider.select((s) => s.isLoading),
                          );

                          return CustomButton(
                            backgroundColor: Colors.grey,
                            label: "Sign In",
                            isLoading: isLoading,
                            onTap: isLoading
                                ? null
                                : () {
                              if (!_formKey.currentState!.validate()) return;
                              ref.read(authControllerProvider.notifier).login(
                                phoneController.text.trim(),
                                passwordController.text.trim(),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // ── Divider ──
                      _OrDivider(),

                      const SizedBox(height: 18),

                      // Social hint row (cosmetic)
                      _SocialChip(
                        icon: Icons.phone_outlined,
                        label: "Phone Number",
                      ),

                      const SizedBox(height: 22),

                      // Navigate to Signup
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen())),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.blueGrey.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(
                                  text: "Sign Up",
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


class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: Colors.blueGrey.withOpacity(0.15), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "or continue with",
            style: TextStyle(
              color: Colors.blueGrey.withOpacity(0.7),
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.blueGrey.withOpacity(0.15), thickness: 1)),
      ],
    );
  }
}


class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.withOpacity(0.13)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blueGrey, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
