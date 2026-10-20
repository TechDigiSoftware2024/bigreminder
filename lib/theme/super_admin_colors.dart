import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import '../models/app_color_scheme.dart';

/// Platform shell uses the same enterprise tokens as the business app.
class SuperAdminColors {
  SuperAdminColors._();

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;

  static const Color background = AppColors.background;
  static const Color surfaceMuted = AppColors.surfaceMuted;
  static const Color border = AppColors.border;

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textHint = AppColors.textHint;

  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;

  static const Color grey100 = AppColors.grey100;
  static const Color grey400 = AppColors.grey400;
  static const Color grey500 = AppColors.grey500;

  static const Color iconColor = AppColors.iconColor;
  static const Color buttonPrimaryBg = AppColors.buttonPrimaryBg;
  static const Color buttonPrimaryText = AppColors.buttonPrimaryText;
}

class AppBrand {
  const AppBrand();

  Color get white => AppColors.white;
  Color get background => AppColors.background;
  Color get border => AppColors.border;
  Color get primaryDark => AppColors.primaryDark;
  Color get textPrimary => AppColors.textPrimary;
  Color get textSecondary => AppColors.textSecondary;
  Color get textHint => AppColors.textHint;
  Color get sidebar => AppColors.sidebar;
  Color get sidebarText => AppColors.sidebarText;
  Color get sidebarMuted => AppColors.sidebarMuted;
  Color get sidebarActive => AppColors.sidebarActive;
}

extension SuperAdminContext on BuildContext {
  AppBrand get brand => const AppBrand();
  ColorScheme get colors => Theme.of(this).colorScheme;
}

class SuperAdminTheme {
  SuperAdminTheme._();

  static ThemeData get theme =>
      AppTheme.light(AppColorScheme(primary: AppColors.primary));

  static Widget wrap(Widget child) {
    return Theme(
      data: theme,
      child: child,
    );
  }

  static Route<T> route<T>(Widget page) {
    return MaterialPageRoute<T>(
      builder: (_) => wrap(page),
    );
  }
}
