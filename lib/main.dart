import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/services/auth/auth_gate.dart';
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> restoreAppType(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedAppType = prefs.getString('appType');

  AppType appType;

  if (savedAppType != null) {
    appType = AppType.values.firstWhere(
          (e) => e.name == savedAppType,
      orElse: () => AppType.generic,
    );
  } else {
    final savedCategory = prefs.getString('businessCategory');
    appType = mapStringToAppType(savedCategory);
  }

  ref.read(appTypeProvider.notifier).state = appType;

  debugPrint('🔥 RESTORED APP TYPE: $appType');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();

    restoreAppType(ref);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
      home: const AuthGate(),
    );
  }
}