import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/screens/business/business_main.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_models/auth_user_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/auth_state.dart';
import '../../screens/super_admin/bottom_nav_screens/super_admin_main.dart';
import 'auth_gate.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key,});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    if (!_ready) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = state.user;

    if (user != null && user.hasValidToken) {
      if (user.isSuperAdmin) {
        return const SuperAdminMain();
      } else {
        return BusinessMain();
      }
    }

    return const LoginScreen();
  }
}