import 'dart:ui';

import 'package:bigreminder/screens/super_admin/bottom_nav_screens/settings_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/subscription_screen.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/super_admin_home.dart';
import 'package:bigreminder/theme/super_admin_colors.dart';
import 'package:bigreminder/widgets/custom_dialog.dart';
import 'package:bigreminder/widgets/super_admin_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/super_admin/super_admin_provider.dart';
import '../../auth/signup_screen.dart';
import 'notification_screen.dart';

class SuperAdminMain extends ConsumerStatefulWidget {
  const SuperAdminMain({super.key});

  @override
  ConsumerState<SuperAdminMain> createState() => _SuperAdminMainState();
}

class _SuperAdminMainState extends ConsumerState<SuperAdminMain> {
  int currentIndex = 0;

  /// Nested content navigator — Super Admin sidebar stays permanent;
  /// Business List / Users / Queries push only in the right pane.
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);

  final List<Widget> _screens = const [
    SuperAdminHome(),
    SubscriptionScreen(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(userProvider);
      ref.invalidate(businessListProvider);
      ref.invalidate(platformDashboardProvider);
      ref.invalidate(adminQueryProvider);
    });
  }

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() => currentIndex = index);
    _tabIndex.value = index;
    // Pop nested routes (Business List, etc.) back to tab shell.
    _contentNavKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _openCreateBusiness() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (dialogContext) {
        final width = CustomDialog.dialogWidth(
          dialogContext,
          desktop: CustomDialog.confirmWidth,
        );
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: SuperAdminColors.primaryDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded,
                          size: 24,
                          color: SuperAdminColors.iconColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Create Business',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quickly onboard a new business account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: SuperAdminColors.buttonPrimaryBg,
                            foregroundColor: SuperAdminColors.buttonPrimaryText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result != true || !mounted) return;

    final nav = _contentNavKey.currentState;
    final created = nav == null
        ? await Navigator.push<bool>(
            context,
            SuperAdminTheme.route(const SignupScreen(isFromAdmin: true)),
          )
        : await nav.push<bool>(
            MaterialPageRoute(
              builder: (_) => SuperAdminTheme.wrap(
                const SignupScreen(isFromAdmin: true),
              ),
            ),
          );

    if (created == true && mounted) {
      ref.invalidate(userProvider);
      ref.invalidate(businessListProvider);
      ref.invalidate(platformDashboardProvider);
      _onTabChange(0);
    }
  }

  Widget _contentNavigator() {
    return Navigator(
      key: _contentNavKey,
      onGenerateRoute: (_) {
        return MaterialPageRoute(
          builder: (_) => ValueListenableBuilder<int>(
            valueListenable: _tabIndex,
            builder: (_, index, __) {
              return IndexedStack(
                index: index.clamp(0, _screens.length - 1),
                children: _screens,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return SuperAdminTheme.wrap(
      Builder(
        builder: (context) {
          final primary = Theme.of(context).colorScheme.primary;

          if (isDesktop) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Row(
                children: [
                  SuperAdminSidebar(
                    currentIndex: currentIndex,
                    onTap: _onTabChange,
                    onCreateBusiness: _openCreateBusiness,
                  ),
                  Expanded(child: _contentNavigator()),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _contentNavigator(),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _navItem(
                        Icons.dashboard_outlined,
                        'Home',
                        0,
                        primary,
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        Icons.workspace_premium_outlined,
                        'Plans',
                        1,
                        primary,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: _openCreateBusiness,
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        Icons.notifications_none_rounded,
                        'Notify',
                        2,
                        primary,
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        Icons.settings_outlined,
                        'Settings',
                        3,
                        primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, Color primary) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => _onTabChange(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
