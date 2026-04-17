import 'package:bigreminder/constants/get_bottom_bar_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_bottom_bar.dart';

class BusinessMain extends ConsumerStatefulWidget {
  const BusinessMain({super.key});

  @override
  ConsumerState<BusinessMain> createState() => _BusinessMainState();
}

class _BusinessMainState extends ConsumerState<BusinessMain> {
  int currentIndex = 0;

  void onTabTapped(int index) {
    // ✅ Center Button Action
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

    // ✅ Direct set (no shifting)
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appType = ref.watch(appTypeProvider);
    final screens = getBottomBarScreens(appType);

    // ✅ Safety
    if (currentIndex >= screens.length) {
      currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

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