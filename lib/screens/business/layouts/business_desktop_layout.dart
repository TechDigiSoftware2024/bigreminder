import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/business_sidebar.dart';

class DesktopLayout extends StatefulWidget {
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
  State<DesktopLayout> createState() =>
      _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  final GlobalKey<NavigatorState> _navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void didUpdateWidget(
      covariant DesktopLayout oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    // Sidebar tab changed.
    if (oldWidget.currentIndex != widget.currentIndex) {
      _showMainScreen();
    }
  }

  void _showMainScreen() {
    if (widget.screens.isEmpty) return;

    final index = widget.currentIndex.clamp(
      0,
      widget.screens.length - 1,
    );

    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => widget.screens[index],
      ),
          (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMainScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background ,
      body: Row(
        children: [

          // ==================================================
          // PERMANENT SIDEBAR
          // ==================================================

          BusinessSidebar(
            currentIndex: widget.currentIndex,
            onTap: widget.onTabTapped,
            labels: widget.labels,
          ),

          // ==================================================
          // RIGHT SIDE
          // ==================================================

          Expanded(
            child: Navigator(
              key: _navigatorKey,
              onGenerateRoute: (_) {
                final index = widget.currentIndex.clamp(
                  0,
                  widget.screens.length - 1,
                );

                return MaterialPageRoute(
                  builder: (_) => widget.screens[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}