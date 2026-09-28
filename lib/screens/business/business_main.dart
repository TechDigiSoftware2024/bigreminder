// import 'package:bigreminder/constants/get_bottom_bar_screens.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../providers/auth/auth_provider.dart';
// import '../../providers/business/business_provider.dart';
// import '../../providers/theme_provider.dart';
// import '../../utils/enum_classes.dart';
//
// import 'layouts/business_desktop_layout.dart';
// import 'layouts/business_mobile_layout.dart';
//
// class BusinessMain extends ConsumerStatefulWidget {
//   const BusinessMain({
//     super.key,
//   });
//
//   @override
//   ConsumerState<BusinessMain> createState() => _BusinessMainState();
// }
//
// class _BusinessMainState extends ConsumerState<BusinessMain> {
//   int currentIndex = 0;
//
//   bool _initialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // IMPORTANT:
//     // Do not modify Riverpod provider directly inside initState.
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeBusiness();
//     });
//   }
//
//   Future<void> _initializeBusiness() async {
//     if (_initialized) return;
//
//     _initialized = true;
//
//     try {
//       // ============================================================
//       // 1. GET CURRENT AUTH STATE
//       // ============================================================
//
//       final authState = ref.read(
//         authControllerProvider,
//       );
//
//       final token = authState.token;
//
//       debugPrint(
//         'BUSINESS INIT TOKEN => '
//             '${token == null ? "NULL" : "AVAILABLE"}',
//       );
//
//       if (token == null || token.isEmpty) {
//         debugPrint(
//           'BUSINESS INIT => TOKEN EMPTY',
//         );
//         return;
//       }
//
//       // ============================================================
//       // 2. FETCH BUSINESSES
//       // ============================================================
//
//       debugPrint(
//         'BUSINESS INIT => FETCHING BUSINESSES',
//       );
//
//       await ref
//           .read(businessControllerProvider.notifier)
//           .fetchMyBusinesses(token);
//
//       // ============================================================
//       // 3. CHECK IF WIDGET STILL EXISTS
//       // ============================================================
//
//       if (!mounted) return;
//
//       final businessState = ref.read(
//         businessControllerProvider,
//       );
//
//       debugPrint(
//         'BUSINESS INIT => '
//             'BUSINESSES COUNT = '
//             '${businessState.businesses.length}',
//       );
//
//       // ============================================================
//       // 4. NO BUSINESS
//       // ============================================================
//
//       if (businessState.businesses.isEmpty) {
//         debugPrint(
//           'BUSINESS INIT => NO BUSINESS FOUND',
//         );
//         return;
//       }
//
//       // ============================================================
//       // 5. FIRST BUSINESS
//       // ============================================================
//
//       final business = businessState.businesses.first;
//
//       final category = business.category ?? 'General';
//
//       final appType = mapStringToAppType(
//         category,
//       );
//
//       debugPrint(
//         'BUSINESS INIT => '
//             'CATEGORY = $category',
//       );
//
//       debugPrint(
//         'BUSINESS INIT => '
//             'APP TYPE = ${appType.name}',
//       );
//
//       // ============================================================
//       // 6. SAVE LOCAL BUSINESS CONFIG
//       // ============================================================
//
//       final prefs = await SharedPreferences.getInstance();
//
//       await prefs.setString(
//         'appType',
//         appType.name,
//       );
//
//       await prefs.setString(
//         'businessCategory',
//         category,
//       );
//
//       // ============================================================
//       // 7. UPDATE THEME PROVIDER
//       // ============================================================
//
//       if (!mounted) return;
//
//       ref.read(appTypeProvider.notifier).state = appType;
//
//       debugPrint(
//         'BUSINESS INIT => COMPLETED',
//       );
//     } catch (e, stackTrace) {
//       debugPrint(
//         'BUSINESS INIT ERROR => $e',
//       );
//
//       debugPrint(
//         stackTrace.toString(),
//       );
//     }
//   }
//
//   void onTabTapped(int index) {
//     if (!mounted) return;
//
//     setState(() {
//       currentIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     // ============================================================
//     // BUSINESS STATE
//     // ============================================================
//
//     final businessState = ref.watch(
//       businessControllerProvider,
//     );
//
//     // ============================================================
//     // APP TYPE
//     // ============================================================
//
//     final appType = ref.watch(
//       appTypeProvider,
//     );
//
//     // ============================================================
//     // RESPONSIVE
//     // ============================================================
//
//     final isDesktop =
//         MediaQuery.sizeOf(context).width >= 900;
//
//     final screens = getBottomBarScreens(
//       appType,
//     );
//
//     // ============================================================
//     // LOADING
//     // ============================================================
//
//     if (businessState.isLoading) {
//       return const Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//
//     // ============================================================
//     // ERROR
//     // ============================================================
//
//     if (businessState.error != null) {
//       return Scaffold(
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.error_outline_rounded,
//                   size: 50,
//                   color: Colors.red,
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 const Text(
//                   'Unable to load business',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 Text(
//                   businessState.error.toString(),
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: Colors.grey,
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 ElevatedButton(
//                   onPressed: () async {
//                     final token = ref
//                         .read(authControllerProvider)
//                         .token;
//
//                     if (token == null ||
//                         token.isEmpty) {
//                       return;
//                     }
//
//                     await ref
//                         .read(
//                       businessControllerProvider
//                           .notifier,
//                     )
//                         .fetchMyBusinesses(token);
//                   },
//                   child: const Text(
//                     'Retry',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     // ============================================================
//     // NO BUSINESS
//     // ============================================================
//
//     if (businessState.businesses.isEmpty) {
//       return Scaffold(
//         body: Center(
//           child: SizedBox(
//             width: isDesktop ? 400 : double.infinity,
//             child: Padding(
//               padding: const EdgeInsets.all(34),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.business_outlined,
//                       size: 48,
//                       color: Colors.orange,
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   const Text(
//                     'No Business Found',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   const Text(
//                     'We could not find a business '
//                         'associated with your account.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                       height: 1.5,
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   ElevatedButton.icon(
//                     onPressed: () async {
//                       final token = ref
//                           .read(
//                         authControllerProvider,
//                       )
//                           .token;
//
//                       if (token == null ||
//                           token.isEmpty) {
//                         return;
//                       }
//
//                       await ref
//                           .read(
//                         businessControllerProvider
//                             .notifier,
//                       )
//                           .fetchMyBusinesses(token);
//                     },
//                     icon: const Icon(
//                       Icons.refresh_rounded,
//                     ),
//                     label: const Text(
//                       'Try Again',
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   TextButton.icon(
//                     onPressed: () async {
//                       await ref
//                           .read(
//                         authControllerProvider
//                             .notifier,
//                       )
//                           .logout();
//                     },
//                     icon: const Icon(
//                       Icons.logout,
//                     ),
//                     label: const Text(
//                       'Login Again',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//
//     // ============================================================
//     // PROTECT INDEX
//     // ============================================================
//
//     if (currentIndex >= screens.length) {
//       currentIndex = 0;
//     }
//
//     // ============================================================
//     // DESKTOP
//     // ============================================================
//
//     if (isDesktop) {
//       return DesktopLayout(
//         screens: screens,
//         currentIndex: currentIndex,
//         onTabTapped: onTabTapped,
//         labels: getBottomBarLabels(
//           appType,
//         ),
//       );
//     }
//
//     // ============================================================
//     // MOBILE
//     // ============================================================
//
//     return MobileLayout(
//       screens: screens,
//       currentIndex: currentIndex,
//       onTabTapped: onTabTapped,
//       labels: getBottomBarLabels(
//         appType,
//       ),
//     );
//   }
// }
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
  const BusinessMain({super.key});

  @override
  ConsumerState<BusinessMain> createState() => _BusinessMainState();
}

class _BusinessMainState extends ConsumerState<BusinessMain> {
  int currentIndex = 0;

  bool _initialized = false;

  // ------------------------------------------------------------
  // UI ERROR STATES
  // ------------------------------------------------------------

  bool _sessionExpired = false;
  String? _screenError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBusiness();
    });
  }

  // ============================================================
  // INITIALIZE BUSINESS
  // ============================================================

  Future<void> _initializeBusiness({bool isRetry = false}) async {
    if (_initialized && !isRetry) {
      return;
    }

    _initialized = true;

    if (mounted) {
      setState(() {
        _sessionExpired = false;
        _screenError = null;
      });
    }

    try {
      // ==========================================================
      // 1. GET AUTH STATE
      // ==========================================================

      final authState = ref.read(authControllerProvider);

      final token = authState.token;

      debugPrint(
        'BUSINESS INIT TOKEN => '
        '${token == null ? "NULL" : "AVAILABLE"}',
      );

      // ==========================================================
      // 2. TOKEN MISSING
      // ==========================================================

      if (token == null || token.isEmpty) {
        debugPrint('BUSINESS INIT => TOKEN MISSING');

        if (!mounted) return;

        setState(() {
          _sessionExpired = true;
          _screenError = 'Your session has expired. Please login again.';
        });

        return;
      }

      // ==========================================================
      // 3. FETCH BUSINESSES
      // ==========================================================

      debugPrint('BUSINESS INIT => FETCHING BUSINESSES');

      try {
        await ref
            .read(businessControllerProvider.notifier)
            .fetchMyBusinesses(token);
      } catch (e) {
        debugPrint('BUSINESS FETCH FAILED => $e');

        if (!mounted) return;

        final error = e.toString();

        // --------------------------------------------------------
        // 401 / UNAUTHORIZED / TOKEN ERROR
        // --------------------------------------------------------

        if (_isAuthenticationError(error)) {
          setState(() {
            _sessionExpired = true;
            _screenError = 'Your session has expired. Please login again.';
          });

          return;
        }

        // --------------------------------------------------------
        // OTHER API ERROR
        // --------------------------------------------------------

        setState(() {
          _sessionExpired = false;
          _screenError = _cleanError(error);
        });

        return;
      }

      if (!mounted) return;

      // ==========================================================
      // 4. GET BUSINESS STATE
      // ==========================================================

      final businessState = ref.read(businessControllerProvider);

      debugPrint(
        'BUSINESS COUNT => '
        '${businessState.businesses.length}',
      );

      // ==========================================================
      // 5. BUSINESS API SUCCESS BUT NO BUSINESS
      // ==========================================================

      if (businessState.businesses.isEmpty) {
        debugPrint('BUSINESS INIT => NO BUSINESS');

        if (!mounted) return;

        setState(() {
          _sessionExpired = false;
          _screenError = null;
        });

        return;
      }

      // ==========================================================
      // 6. GET FIRST BUSINESS
      // ==========================================================

      final business = businessState.businesses.first;

      final category = business.category ?? 'General';

      final appType = mapStringToAppType(category);

      debugPrint('BUSINESS CATEGORY => $category');

      debugPrint('APP TYPE => ${appType.name}');

      // ==========================================================
      // 7. SAVE BUSINESS CONFIG
      // ==========================================================

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('appType', appType.name);

      await prefs.setString('businessCategory', category);

      // ==========================================================
      // 8. UPDATE THEME
      // ==========================================================

      if (!mounted) return;

      ref.read(appTypeProvider.notifier).state = appType;

      debugPrint('BUSINESS INIT => COMPLETED');

      if (mounted) {
        setState(() {
          _sessionExpired = false;
          _screenError = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('BUSINESS INIT ERROR => $e');

      debugPrint(stackTrace.toString());

      if (!mounted) return;

      final error = e.toString();

      if (_isAuthenticationError(error)) {
        setState(() {
          _sessionExpired = true;
          _screenError = 'Your session has expired. Please login again.';
        });
      } else {
        setState(() {
          _sessionExpired = false;
          _screenError = _cleanError(error);
        });
      }
    }
  }

  // ============================================================
  // AUTH ERROR DETECTION
  // ============================================================

  bool _isAuthenticationError(String error) {
    final lower = error.toLowerCase();

    return lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('authentication failed') ||
        lower.contains('token expired') ||
        lower.contains('token invalid') ||
        lower.contains('invalid token') ||
        lower.contains('jwt expired') ||
        lower.contains('jwt') && lower.contains('expired');
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(String error) {
    return error.replaceFirst('Exception: ', '').trim();
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> _retry() async {
    debugPrint('BUSINESS RETRY START');

    await _initializeBusiness(isRetry: true);
  }

  // ============================================================
  // LOGIN AGAIN
  // ============================================================

  Future<void> _loginAgain() async {
    debugPrint('LOGIN AGAIN START');

    try {
      // ----------------------------------------------------------
      // LOGOUT
      // ----------------------------------------------------------

      await ref.read(authControllerProvider.notifier).logout();

      if (!mounted) return;

      // ----------------------------------------------------------
      // CLEAR BUSINESS PROVIDER
      // ----------------------------------------------------------

      ref.invalidate(businessControllerProvider);

      // ----------------------------------------------------------
      // RESET LOCAL STATE
      // ----------------------------------------------------------

      setState(() {
        _initialized = false;
        _sessionExpired = true;
        _screenError = 'Please login again to continue.';
      });

      // ----------------------------------------------------------
      // IMPORTANT
      // ----------------------------------------------------------
      //
      // AuthController.logout() changes:
      //
      // state = AuthState();
      //
      // Your ROOT AUTH GATE should now automatically
      // show LoginPage.
      //
      // DO NOT push BusinessMain again.
      //
    } catch (e) {
      debugPrint('LOGIN AGAIN ERROR => $e');

      if (!mounted) return;

      setState(() {
        _sessionExpired = true;
        _screenError = 'Unable to logout. Please try again.';
      });
    }
  }

  // ============================================================
  // TAB
  // ============================================================

  void onTabTapped(int index) {
    if (!mounted) return;

    setState(() {
      currentIndex = index;
    });

    // When returning to Home, refresh dashboard totals immediately.
    if (index == 0) {
      Future.microtask(() {
        if (!mounted) return;
        try {
          final id = ref.read(businessIdProvider);
          ref.invalidate(dashboardProvider(id));
        } catch (_) {}
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessControllerProvider);

    final appType = ref.watch(appTypeProvider);

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final screens = getBottomBarScreens(appType);

    // ==========================================================
    // LOADING
    // ==========================================================

    if (businessState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ==========================================================
    // SESSION EXPIRED / TOKEN NULL / 401
    // ==========================================================

    if (_sessionExpired) {
      return _buildErrorScreen(
        context,
        icon: Icons.lock_outline_rounded,
        title: 'Session Expired',
        message:
            _screenError ?? 'Your session has expired. Please login again.',
        primaryButtonText: 'Login Again',
        primaryIcon: Icons.login_rounded,
        onPrimaryPressed: _loginAgain,
        showRetry: true,
      );
    }

    // ==========================================================
    // API ERROR
    // ==========================================================

    if (_screenError != null) {
      return _buildErrorScreen(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Business',
        message: _screenError!,
        primaryButtonText: 'Retry',
        primaryIcon: Icons.refresh_rounded,
        onPrimaryPressed: _retry,
        showRetry: false,
      );
    }

    // ==========================================================
    // NO BUSINESS
    // ==========================================================

    if (businessState.businesses.isEmpty) {
      return _buildErrorScreen(
        context,
        icon: Icons.business_outlined,
        title: 'No Business Found',
        message: 'We could not find a business associated with your account.',
        primaryButtonText: 'Try Again',
        primaryIcon: Icons.refresh_rounded,
        onPrimaryPressed: _retry,
        showRetry: false,
      );
    }

    // ==========================================================
    // PROTECT INDEX
    // ==========================================================

    if (currentIndex >= screens.length) {
      currentIndex = 0;
    }

    // ==========================================================
    // DESKTOP
    // ==========================================================

    if (isDesktop) {
      return DesktopLayout(
        screens: screens,
        currentIndex: currentIndex,
        onTabTapped: onTabTapped,
        labels: getBottomBarLabels(appType),
      );
    }

    // ==========================================================
    // MOBILE
    // ==========================================================

    return MobileLayout(
      screens: screens,
      currentIndex: currentIndex,
      onTabTapped: onTabTapped,
      labels: getBottomBarLabels(appType),
    );
  }

  // ============================================================
  // COMMON ERROR SCREEN
  // ============================================================

  Widget _buildErrorScreen(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String primaryButtonText,
    required IconData primaryIcon,
    required Future<void> Function() onPrimaryPressed,
    required bool showRetry,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: isDesktop ? 420 : double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------------------------------------------------
                  // ICON
                  // ------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // MESSAGE
                  // ------------------------------------------------
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // PRIMARY BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await onPrimaryPressed();
                      },
                      icon: Icon(primaryIcon),
                      label: Text(primaryButtonText),
                    ),
                  ),

                  // ------------------------------------------------
                  // LOGIN AGAIN
                  // ------------------------------------------------
                  if (!showRetry) ...[
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loginAgain,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Login Again'),
                      ),
                    ),
                  ],

                  // ------------------------------------------------
                  // SESSION EXPIRED
                  // ------------------------------------------------
                  if (showRetry) ...[
                    const SizedBox(height: 10),

                    TextButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
