import 'package:bigreminder/screens/Super Admin/super_admin.dart';
import 'package:bigreminder/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../../constants/bottom_nav_bar.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/create business/create_business.dart';

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
      if (state.user!.role == "super_admin") {
        return const SuperAdminHome();
      } else {
        return  CreateBusinessScreen();
      }
    }

    /// ================= NOT LOGGED IN =================
    return SignupScreen();
  }
}