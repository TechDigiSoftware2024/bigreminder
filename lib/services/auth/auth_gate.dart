import 'package:bigreminder/providers/auth/auth_provider.dart';
import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/screens/business/business_main.dart';
import 'package:bigreminder/theme/super_admin_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/super_admin/bottom_nav_screens/super_admin_main.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await ref.read(authControllerProvider.notifier).restoreSession();
    } catch (e, st) {
      debugPrint('AuthGate restore failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final loggedIn = (user != null && user.hasValidToken) ||
        (auth.token != null && auth.token!.isNotEmpty);

    if (!_ready) {
      return SuperAdminTheme.wrap(
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!loggedIn) {
      return SuperAdminTheme.wrap(
        const LoginScreen(key: ValueKey('auth-login')),
      );
    }

    final role = user?.role ?? '';
    if (role == 'super_admin' || user?.isSuperAdmin == true) {
      return const SuperAdminMain(key: ValueKey('super-admin-shell'));
    }

    return const BusinessMain(key: ValueKey('business-shell'));
  }
}
