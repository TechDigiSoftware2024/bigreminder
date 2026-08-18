import 'package:flutter/material.dart';
import '../../../widgets/custom_bottom_bar.dart';

class MobileLayout extends StatelessWidget {
  final List<Widget> screens;
  final int currentIndex;
  final ValueChanged<int> onTabTapped;
  final List<String> labels;

  const MobileLayout({
    super.key,
    required this.screens,
    required this.currentIndex,
    required this.onTabTapped,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
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
        labels: labels,
      ),
    );
  }
}