import 'package:bigreminder/providers/theme_provider.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/super_admin_main.dart';
import 'package:bigreminder/services/auth/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'constants/business_main.dart';
import 'firebase_options.dart';

Future<void> initFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔔 Permission request
  NotificationSettings settings = await messaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // 🎯 Get Token
    String? token = await messaging.getToken();

    print("🔥🔥 FCM TOKEN 👇👇");
    print(token);
  } else {
    print("❌ Permission Denied");
  }

  // 🔄 Token refresh listener
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print("♻️ NEW TOKEN: $newToken");
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initFCM(); // 🚀 yaha call kiya

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