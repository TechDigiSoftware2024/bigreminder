import 'package:bigreminder/constants/get_bottom_bar_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/business/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/enum_classes.dart';
import 'layouts/business_desktop_layout.dart';
import 'layouts/business_mobile_layout.dart';


class BusinessMain extends ConsumerStatefulWidget {
  const BusinessMain({super.key,});

  @override
  ConsumerState<BusinessMain> createState() => _BusinessMainState();
}

class _BusinessMainState extends ConsumerState<BusinessMain> {
  int currentIndex = 0;
  bool _initialized = false; // 🔥 prevent multiple calls

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (_initialized) return;
      _initialized = true;

      final token = ref.read(authControllerProvider).token;

      if (token != null && token.isNotEmpty) {
        await ref
            .read(businessControllerProvider.notifier)
            .fetchMyBusinesses(token);

        final businessState = ref.read(businessControllerProvider);

        if (businessState.businesses.isNotEmpty) {
          final business = businessState.businesses.first;

          final appType =
          mapStringToAppType(business.category ?? "General");

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("appType", appType.name);
          await prefs.setString(
              "businessCategory", business.category ?? "General");

          ref.read(appTypeProvider.notifier).state = appType;
        }
      }
    });
  }
  void onTabTapped(int index) {
    /// 🔥 CHANGE TAB
    setState(() {
      currentIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    final appType = ref.watch(appTypeProvider);
    final businessState = ref.watch(businessControllerProvider);

    final screens = getBottomBarScreens(appType);

    if (businessState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (businessState.businesses.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No business data found"),
        ),
      );
    }

    if (currentIndex >= screens.length) {
      currentIndex = 0;
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return DesktopLayout(
        screens: screens,
        currentIndex: currentIndex,
        onTabTapped: onTabTapped,
        labels: getBottomBarLabels(appType),
      );
    }

    return MobileLayout(
      screens: screens,
      currentIndex: currentIndex,
      onTabTapped: onTabTapped,
      labels: getBottomBarLabels(appType),
    );
  }
}
