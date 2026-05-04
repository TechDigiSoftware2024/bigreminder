import 'package:bigreminder/constants/get_bottom_bar_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/business/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/enum_classes.dart';
import '../../widgets/custom_bottom_bar.dart';


class BusinessMain extends ConsumerStatefulWidget {
  const BusinessMain({super.key});

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
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        builder: (_) => const SizedBox(
          height: 200,
          child: Center(child: Text("Add Action")),
        ),
      );
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appType = ref.watch(appTypeProvider);
    final businessState = ref.watch(businessControllerProvider);

    final screens = getBottomBarScreens(appType);

    // 🔥 LOADING STATE
    if (businessState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔥 EMPTY STATE (login case)
    if (businessState.businesses.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No business data found")),
      );
    }

    // 🔥 SAFE INDEX
    if (currentIndex >= screens.length) {
      currentIndex = 0;
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: screens[currentIndex],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        labels: getBottomBarLabels(appType),
      ),
    );
  }
}