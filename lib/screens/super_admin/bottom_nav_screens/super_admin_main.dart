import 'dart:ui';

import 'package:bigreminder/theme/app_colors.dart';
import 'package:bigreminder/screens/super_admin/bottom_nav_screens/categories_screen.dart';
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
    CategoriesScreen(),
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
            bottomNavigationBar: Material(
              color: AppColors.surface,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 58,
                    child: Row(
                      children: [
                        Expanded(
                          child: _navItem(
                            Icons.dashboard_outlined,
                            'Home',
                            0,
                          ),
                        ),
                        Expanded(
                          child: _navItem(
                            Icons.category_outlined,
                            'Category',
                            1,
                          ),
                        ),
                        Expanded(
                          child: _navItem(
                            Icons.add_business_outlined,
                            'New',
                            -1,
                            onPressed: _openCreateBusiness,
                          ),
                        ),
                        Expanded(
                          child: _navItem(
                            Icons.workspace_premium_outlined,
                            'Plans',
                            2,
                          ),
                        ),
                        Expanded(
                          child: _navItem(
                            Icons.notifications_none_outlined,
                            'Notify',
                            3,
                          ),
                        ),
                        Expanded(
                          child: _navItem(
                            Icons.settings_outlined,
                            'Settings',
                            4,
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
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    VoidCallback? onPressed,
  }) {
    final isSelected = index >= 0 && currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onPressed ?? () => _onTabChange(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 2,
            width: 18,
            margin: const EdgeInsets.only(bottom: 6),
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
