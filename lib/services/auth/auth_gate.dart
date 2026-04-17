
import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/screens/business/business_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/business_main.dart';
import '../../providers/auth/auth_provider.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/super_admin/bottom_nav_screens/super_admin_main.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    /// ================= LOADING =================
    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ================= USER CHECK =================
    if (state.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.user!.role == "super_admin") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SuperAdminMain()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BusinessMain()),
                (route) => false,
          );
        }
      });

      return const SizedBox(); // empty while navigating
    }

    /// ================= NOT LOGGED IN =================
    return LoginScreen();
  }
}