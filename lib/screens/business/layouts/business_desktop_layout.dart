import 'package:flutter/material.dart';

import '../../../widgets/business_sidebar.dart';

class DesktopLayout extends StatelessWidget {
  final List<Widget> screens;
  final int currentIndex;
  final ValueChanged<int> onTabTapped;
  final List<String> labels;

  const DesktopLayout({
    super.key,
    required this.screens,
    required this.currentIndex,
    required this.onTabTapped,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          BusinessSidebar(
            currentIndex: currentIndex,
            onTap: onTabTapped,
            labels: labels,
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(currentIndex),
                child: screens[currentIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}