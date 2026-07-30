import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/services/auth/auth_gate.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> restoreAppType(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();

  final savedAppType = prefs.getString("appType");

  AppType appType;

  if (savedAppType != null) {
    appType = AppType.values.firstWhere(
          (e) => e.name == savedAppType,
      orElse: () => AppType.generic,
    );
  } else {
    // fallback (old data support)
    final savedCategory = prefs.getString("businessCategory");
    appType = mapStringToAppType(savedCategory);
  }

  ref.read(appTypeProvider.notifier).state = appType;

  print("🔥 RESTORED APP TYPE: $appType");
}

void main() async {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    restoreAppType(ref);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
      home: AuthGate(),
    );
  }
}