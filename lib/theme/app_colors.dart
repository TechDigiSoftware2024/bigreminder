import 'package:flutter/material.dart';

/// Muted enterprise palette: slate canvas, steel-blue actions, soft status tones.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2C4A6E);
  static const Color primaryDark = Color(0xFF1E3550);
  static const Color primaryLight = Color(0xFFE6EDF4);
  static const Color accent = Color(0xFF5C7A96);

  // Neutrals
  static const Color black = Color(0xFF1A2332);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF3D4856);

  // Canvas
  static const Color background = Color(0xFFF3F5F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1F5);
  static const Color card = surface;
  static const Color cardText = textPrimary;

  // Navigation shell
  static const Color sidebar = Color(0xFF1C2834);
  static const Color sidebarBorder = Color(0xFF2A3846);
  static const Color sidebarText = Color(0xFFD5DCE3);
  static const Color sidebarMuted = Color(0xFF8B97A3);
  static const Color sidebarActive = Color(0xFF243447);
  static const Color sidebarAccent = Color(0xFF8AA4BE);

  // Text
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF5C6778);
  static const Color textHint = Color(0xFF8B95A3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // App bar
  static const Color appBarBg = surface;
  static const Color appBarText = textPrimary;
  static const Color appBarIcon = textPrimary;
  static const Color appBarBorder = Color(0xFFE2E6EB);

  // Money states — distinguishable, not neon
  static const Color credit = Color(0xFF2F6B4A);
  static const Color debit = Color(0xFFA33D3D);
  static const Color creditBg = Color(0xFFE7F2EB);
  static const Color debitBg = Color(0xFFF8EAEA);

  static const Color balancePositive = credit;
  static const Color balanceNegative = debit;
  static const Color balanceNeutral = textSecondary;

  // Borders
  static const Color border = Color(0xFFE2E6EB);
  static const Color divider = Color(0xFFE8ECF0);

  // Buttons
  static const Color buttonPrimaryBg = primary;
  static const Color buttonPrimaryText = textOnPrimary;
  static const Color buttonSecondaryBg = surfaceMuted;
  static const Color buttonSecondaryText = textPrimary;
  static const Color buttonDisabledBg = Color(0xFFE4E7EC);
  static const Color buttonDisabledText = Color(0xFF9AA3AE);

  static const Color iconColor = textOnPrimary;
  static const Color iconBg = primaryLight;

  // Chips
  static const Color chipBg = surfaceMuted;
  static const Color chipSelectedBg = primaryLight;
  static const Color chipText = darkGrey;

  // Inputs
  static const Color inputBg = surface;
  static const Color inputBorder = border;
  static const Color inputFocusedBorder = primary;
  static const Color inputErrorBorder = error;

  // Status
  static const Color success = Color(0xFF3D7A56);
  static const Color warning = Color(0xFF9A7430);
  static const Color error = Color(0xFFB23B3B);

  static const Color paid = credit;
  static const Color unpaid = debit;
  static const Color overdue = Color(0xFF9A6A32);
  static const Color paidBg = creditBg;
  static const Color unpaidBg = debitBg;
  static const Color overdueBg = Color(0xFFF6EFE4);

  // Greyscale
  static const Color grey50 = Color(0xFFF7F8FA);
  static const Color grey100 = Color(0xFFEEF1F4);
  static const Color grey200 = Color(0xFFE2E6EB);
  static const Color grey300 = Color(0xFFCDD3DA);
  static const Color grey400 = Color(0xFF9AA3AE);
  static const Color grey500 = Color(0xFF6B7582);

  static Color primaryOpacity(double opacity) => primary.withValues(alpha: opacity);

  static Color blackOpacity(double opacity) =>
      const Color(0xFF000000).withValues(alpha: opacity);

  static Color whiteOpacity(double opacity) => white.withValues(alpha: opacity);
}
