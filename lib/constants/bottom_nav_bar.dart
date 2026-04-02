import 'package:bigreminder/constants/get_bottom_bar_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_bottom_bar.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  int currentIndex = 0;

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
    final screens = getBottomBarScreens(appType);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[currentIndex],
      ),

      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
      ),
    );
  }
}