// import 'package:bigreminder/providers/auth/auth_provider.dart';
// import 'package:bigreminder/screens/auth/signup_screen.dart';
// import 'package:bigreminder/screens/super_admin/bottom_nav_screens/super_admin_main.dart';
// import 'package:bigreminder/widgets/custom_button.dart';
// import 'package:bigreminder/widgets/custom_textfield.dart';
// import 'package:flutter/material.dart';
  // import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:ui';
// import '../../providers/auth/auth_state.dart';
// // import '../../widgets/custom_dialog.dart';
// import '../business/business_main.dart';
//
// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends ConsumerState<LoginScreen>
//     with TickerProviderStateMixin {
//   bool _isNavigating = false;
//
//   final phoneController = TextEditingController();
//   final passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   final _formKey = GlobalKey<FormState>();
//   @override
//   void initState() {
//     super.initState();
//
//     ref.listenManual<AuthState>(authControllerProvider, (prev, next) async {
//       if (next.error != null && next.error!.isNotEmpty) {
//         if (!mounted) return;
//
//         CustomDialog.showErrorSnack(context, _formatError(next.error));
//         return;
//       }
//
//       final isSuccess =
//           prev?.isLoading == true &&
//           next.isLoading == false &&
//           next.user != null &&
//           next.error == null;
//
//       if (!isSuccess) return;
//       if (_isNavigating) return;
//
//       _isNavigating = true;
//
//       try {
//         final user = next.user!;
//         final token = next.token;
//
//         final prefs = await SharedPreferences.getInstance();
//
//         await prefs.setBool('is_logged_in', true);
//
//         await prefs.setString('user_id', user.userId);
//
//         await prefs.setString('user_role', user.role);
//
//         await prefs.setString('access_token', token ?? '');
//
//         if (!mounted) return;
//
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(
//             builder: (_) => user.role == "super_admin"
//                 ? const SuperAdminMain()
//                 : const BusinessMain(),
//           ),
//           (route) => false,
//         );
//       } finally {
//         _isNavigating = false;
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     phoneController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
//
//   String _formatError(String? error) {
//     if (error == null || error.isEmpty) return '';
//     final lower = error.toLowerCase();
//     if (lower.contains('user-not-found') || lower.contains('no user record')) {
//       return 'No account found with this phone number.';
//     }
//     if (lower.contains('wrong-password') ||
//         lower.contains('invalid credential')) {
//       return 'Incorrect password. Please try again.';
//     }
//     if (lower.contains('invalid-email'))
//       return 'Please enter a valid phone number.';
//     if (lower.contains('too-many-requests')) {
//       return 'Too many attempts. Please wait a moment and try again.';
//     }
//     if (lower.contains('network'))
//       return 'Network error. Check your connection.';
//     if (lower.contains('user-disabled'))
//       return 'This account has been disabled.';
//     final cleaned = error.replaceAll(RegExp(r'\[.*?\]'), '').trim();
//     return cleaned.isNotEmpty
//         ? cleaned
//         : 'Something went wrong. Please try again.';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("LOGIN SCREEN REBUILD");
//     final isLoading = ref.watch(
//       authControllerProvider.select((s) => s.isLoading),
//     );
//
//     return Scaffold(
//       backgroundColor: context.brand.background,
//       body: Form(
//         key: _formKey,
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: BoxDecoration(color: context.brand.background),
//           child: SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 70),
//
//                   // Welcome Text with primary colors
//                   const Text(
//                     "Welcome to \nBiz Reminder",
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
//                     "Sign in to pick up where you left off",
//                     style: TextStyle(
//                       color: context.brand.textSecondary,
//                       fontSize: 14.5,
//                     ),
//                   ),
//
//                   const SizedBox(height: 36),
//
//                   // Login Form Card with blue border
//                   Container(
//                     decoration: BoxDecoration(
//                       color: context.brand.background,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: context.brand.border, width: 1.5),
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
//                             controller: phoneController,
//                             hint: "Phone number",
//                             icon: Icons.phone_outlined,
//                             keyboardType: TextInputType.number,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return "Phone is required";
//                               }
//                               final regex = RegExp(r'^[6-9][0-9]{9}$');
//                               if (!regex.hasMatch(value)) {
//                                 return "Enter a valid 10-digit phone number";
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 14),
//                           CustomTextField(
//                             controller: passwordController,
//                             hint: "Password",
//                             icon: Icons.lock_outline_rounded,
//                             obscure: _obscurePassword,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return "Password is required";
//                               }
//                               if (value.length < 6) {
//                                 return "Minimum 6 characters required";
//                               }
//                               return null;
//                             },
//                             trailing: GestureDetector(
//                               onTap: () => setState(
//                                 () => _obscurePassword = !_obscurePassword,
//                               ),
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
//                   const SizedBox(height: 14),
//
//                   // Forgot Password
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: Text(
//                       "Forgot Password?",
//                       style: TextStyle(
//                         color: context.colors.primary,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Sign In Button with primary color
//                   CustomButton(
//                     backgroundColor: context.colors.primary,
//                     label: "Sign In",
//                     isLoading: isLoading,
//                     onTap: () {
//                       print("SIGN IN CLICKED");
//
//                       if (!_formKey.currentState!.validate()) {
//                         print("FORM INVALID");
//                         return;
//                       }
//
//                       print("CALLING LOGIN");
//
//                       ref.read(authControllerProvider.notifier).login(
//                         phoneController.text.trim(),
//                         passwordController.text.trim(),
//                       );
//                     },
//                   ),
//
//                   // const SizedBox(height: 18),
//                   // _OrDivider(),
//                   // const SizedBox(height: 18),
//                   //
//                   // _SocialChip(
//                   //   icon: Icons.phone_outlined,
//                   //   label: "Phone Number",
//                   // ),
//                   const SizedBox(height: 22),
//
//                   // Sign Up Link with primary color
//                   Center(
//                     child: GestureDetector(
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => SignupScreen()),
//                       ),
//                       child: RichText(
//                         text: TextSpan(
//                           text: "Don't have an account? ",
//                           style: TextStyle(
//                             color: context.brand.textSecondary,
//                             fontSize: 14,
//                           ),
//                           children: const [
//                             TextSpan(
//                               text: "Sign Up",
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
//         ),
//       ),
//     );
//   }
// }
//
// // Blue themed divider
// class _OrDivider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Divider(
//             color: context.colors.primary.withOpacity(0.15),
//             thickness: 1,
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Text(
//             "or continue with",
//             style: TextStyle(color: context.brand.textSecondary, fontSize: 12.5),
//           ),
//         ),
//         Expanded(
//           child: Divider(
//             color: context.colors.primary.withOpacity(0.15),
//             thickness: 1,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // Blue themed social chip
// class _SocialChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _SocialChip({required this.icon, required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
//           decoration: BoxDecoration(
//             color: context.colors.primary.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: context.colors.primary.withOpacity(0.15)),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: context.colors.primary, size: 22),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: context.colors.primary,
//                   fontSize: 13.5,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:bigreminder/providers/auth/auth_provider.dart';
import 'package:bigreminder/screens/auth/signup_screen.dart';
import 'package:bigreminder/theme/super_admin_colors.dart';
import 'package:bigreminder/widgets/custom_button.dart';
import 'package:bigreminder/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth/auth_state.dart';
import '../../widgets/custom_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isNavigating = false;

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    ref.listenManual<AuthState>(authControllerProvider, (prev, next) async {
      if (next.isLoading) return;

      final errorJustArrived = next.error != null &&
          next.error!.isNotEmpty &&
          prev?.error != next.error;

      if (errorJustArrived) {
        if (!mounted) return;
        CustomDialog.showErrorSnack(context, _formatError(next.error));
        return;
      }

      // Navigation is handled by AuthGate when user is set.
      // Persist a few UI prefs only — auth token is already saved by AuthController.
      final isSuccess = prev?.isLoading == true &&
          next.isLoading == false &&
          next.user != null &&
          next.error == null;

      if (!isSuccess) return;

      final user = next.user!;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_id', user.userId);
        await prefs.setString('user_role', user.role);
      } catch (e) {
        debugPrint('Login prefs write failed: $e');
      }
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _formatError(String? error) {
    if (error == null || error.isEmpty) return '';
    final lower = error.toLowerCase();
    if (lower.contains('user-not-found') || lower.contains('no user record')) {
      return 'No account found with this phone number.';
    }
    if (lower.contains('wrong-password') ||
        lower.contains('invalid credential')) {
      return 'Incorrect password. Please try again.';
    }
    if (lower.contains('invalid-email'))
      return 'Please enter a valid phone number.';
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('network'))
      return 'Network error. Check your connection.';
    if (lower.contains('user-disabled'))
      return 'This account has been disabled.';
    final cleaned = error.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    return cleaned.isNotEmpty
        ? cleaned
        : 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider.select((s) => s.isLoading),);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return SuperAdminTheme.wrap(
      Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: context.brand.background,
            body: isDesktop
                ? _buildDesktopLayout(context, isLoading)
                : _buildMobileLayout(context, isLoading),
          );
        },
      ),
    );
  }
  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 650,
        ),
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.brand.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.brand.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // ─────────────────────────────
              // LEFT SIDE
              // ─────────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: context.brand.sidebar,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: context.brand.sidebarActive,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.business_center_rounded,
                          color: context.brand.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        "Biz Reminder",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: context.brand.white,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "Manage your business,\ncustomers and reminders smarter.",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          color: context.brand.sidebarText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 35),

                      _desktopFeature(
                        context,
                        Icons.notifications_active_outlined,
                        "Automate customer reminders",
                      ),

                      const SizedBox(height: 16),

                      _desktopFeature(
                        context,
                        Icons.campaign_outlined,
                        "Promote offers & upcoming events",
                      ),

                      const SizedBox(height: 16),

                      _desktopFeature(
                        context,
                        Icons.payments_outlined,
                        "Recover pending payments faster",
                      ),
                    ],
                  ),
                ),
              ),

              // ─────────────────────────────
              // RIGHT SIDE
              // ─────────────────────────────
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 55,
                    vertical: 45,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: context.brand.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Sign in to pick up where you left off",
                          style: TextStyle(
                            color: context.brand.textSecondary,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 35),

                        CustomTextField(
                          controller: phoneController,
                          hint: "Phone number",
                          digitsOnly: true,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                          ],
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.number,
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

                        const SizedBox(height: 18),

                        CustomTextField(
                          controller: passwordController,
                          hint: "Password",
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          validator: (value) {
                            debugPrint(
                              "PASSWORD VALUE: [$value] | LENGTH: ${value?.length}",
                            );
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }

                            if (value.length < 6) {
                              return "Minimum 6 characters required";
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

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            backgroundColor: context.colors.primary,
                            label: "Sign In",
                            isLoading: isLoading,
                            onTap: () {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              ref
                                  .read(authControllerProvider.notifier)
                                  .login(
                                phoneController.text.trim(),
                                passwordController.text.trim(),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 25),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                SuperAdminTheme.route(const SignupScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: context.brand.textSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Sign Up",
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
            color: context.brand.sidebarActive,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: context.brand.sidebarText,
            size: 18,
          ),
        ),

        const SizedBox(width: 14),

        Text(
          text,
          style: TextStyle(
            color: context.brand.sidebarText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  Widget _buildMobileLayout(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),

              Text(
                "Welcome to \nBiz Reminder",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: context.brand.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Sign in to pick up where you left off",
                style: TextStyle(
                  color: context.brand.textSecondary,
                  fontSize: 14.5,
                ),
              ),

              const SizedBox(height: 36),

              Container(
                decoration: BoxDecoration(
                  color: context.brand.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.brand.border,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: phoneController,
                        hint: "Phone number",
                        digitsOnly: true,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                        ],
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.number,
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
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  backgroundColor: context.colors.primary,
                  label: "Sign In",
                  isLoading: isLoading,
                  onTap: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    ref
                        .read(authControllerProvider.notifier)
                        .login(
                      phoneController.text.trim(),
                      passwordController.text.trim(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SuperAdminTheme.route(const SignupScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: context.brand.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: context.colors.primary,
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
    );
  }
}