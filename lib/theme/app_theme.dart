import 'package:flutter/material.dart';
import '../models/app_color_scheme.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  // static ThemeData light = ThemeData(
  //   useMaterial3: true,
  //
  //   // 🎨 BACKGROUND
  //   scaffoldBackgroundColor: AppColors.background,
  //
  //   // 📱 APP BAR
  //   appBarTheme: const AppBarTheme(
  //     backgroundColor: AppColors.appBarBg,
  //     elevation: 0,
  //     scrolledUnderElevation: 0,
  //     foregroundColor: AppColors.textPrimary,
  //     centerTitle: false,
  //   ),
  //
  //   // 🔤 TEXT THEME
  //   textTheme: const TextTheme(
  //     bodyMedium: TextStyle(
  //       color: AppColors.textPrimary,
  //       fontSize: 14,
  //     ),
  //     titleMedium: TextStyle(
  //       color: AppColors.textPrimary,
  //       fontWeight: FontWeight.w600,
  //       fontSize: 16,
  //     ),
  //   ),
  //
  //   // 🔘 BUTTON THEME
  //   elevatedButtonTheme: ElevatedButtonThemeData(
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: AppColors.buttonPrimaryBg,
  //       foregroundColor: AppColors.buttonPrimaryText,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: AppRadius.button,
  //       ),
  //       padding: const EdgeInsets.symmetric(vertical: 14),
  //       elevation: 0,
  //     ),
  //   ),
  //
  //   // 📥 INPUT FIELD THEME
  //   inputDecorationTheme: InputDecorationTheme(
  //     filled: true,
  //     fillColor: AppColors.inputBg,
  //     contentPadding:
  //     const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  //
  //     border: OutlineInputBorder(
  //       borderRadius: AppRadius.input,
  //       borderSide: const BorderSide(color: AppColors.inputBorder),
  //     ),
  //
  //     enabledBorder: OutlineInputBorder(
  //       borderRadius: AppRadius.input,
  //       borderSide: const BorderSide(color: AppColors.inputBorder),
  //     ),
  //
  //     focusedBorder: OutlineInputBorder(
  //       borderRadius: AppRadius.input,
  //       borderSide: const BorderSide(
  //         color: AppColors.inputFocusedBorder,
  //         width: 1.5,
  //       ),
  //     ),
  //
  //     errorBorder: OutlineInputBorder(
  //       borderRadius: AppRadius.input,
  //       borderSide: const BorderSide(
  //         color: AppColors.inputErrorBorder,
  //       ),
  //     ),
  //   ),
  //
  //   // 🧱 CARD THEME
  //   cardTheme: CardThemeData(
  //     color: AppColors.card,
  //     elevation: 0,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: AppRadius.card,
  //     ),
  //     margin: EdgeInsets.zero,
  //   ),
  //
  //   // 🔘 FAB THEME
  //   floatingActionButtonTheme: const FloatingActionButtonThemeData(
  //     backgroundColor: AppColors.buttonPrimaryBg,
  //     foregroundColor: AppColors.buttonPrimaryText,
  //     elevation: 2,
  //   ),
  //
  //   // 🎯 DIVIDER
  //   dividerTheme: const DividerThemeData(
  //     color: AppColors.divider,
  //     thickness: 1,
  //   ),
  //
  //   // 🌈 COLOR SCHEME (Material 3 important)
  //   colorScheme: ColorScheme.light(
  //     primary: AppColors.primary,
  //     onPrimary: AppColors.textOnPrimary,
  //     surface: AppColors.card,
  //     onSurface: AppColors.textPrimary,
  //     error: AppColors.error,
  //   ),
  // );

  static ThemeData light(AppColorScheme colors) {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.light(
        primary: colors.primary,
        onPrimary: Colors.white,

        secondary: colors.primary,
        onSecondary: Colors.white,

        surface: Colors.white,
        onSurface: Colors.black,

        background: Colors.white,
        onBackground: Colors.black,

        error: Colors.red,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}