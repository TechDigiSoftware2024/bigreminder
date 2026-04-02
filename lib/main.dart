import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/screens/auth/login_screen.dart';
import 'package:bigreminder/screens/auth/signup_screen.dart';
import 'package:bigreminder/services/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
      home: AuthGate(),
    );
  }
}
