import 'package:flutter/material.dart';
import '../models/app_color_scheme.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(AppColorScheme colors) {
    final scheme = ColorScheme.light(
      primary: colors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      surfaceContainerHighest: AppColors.surfaceMuted,
    );

    const title = TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: title,
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBg,
        foregroundColor: AppColors.appBarText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.appBarText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.appBarIcon, size: 20),
        actionsIconTheme: IconThemeData(color: AppColors.appBarIcon, size: 20),
        shape: Border(
          bottom: BorderSide(color: AppColors.appBarBorder),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.buttonDisabledBg,
          disabledForegroundColor: AppColors.buttonDisabledText,
          elevation: 0,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(0, 40),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.45)),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.inputErrorBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 1,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBg,
        selectedColor: AppColors.chipSelectedBg,
        labelStyle: const TextStyle(
          color: AppColors.chipText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSM),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        dense: true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sidebar,
        contentTextStyle: TextStyle(color: AppColors.sidebarText, fontSize: 13),
      ),
    );
  }
}
