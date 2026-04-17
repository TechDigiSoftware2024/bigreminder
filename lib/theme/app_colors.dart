import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 🟣 BRAND (Purple Identity)
  static const Color primary = Color(0xFF14B8A6);      // main teal (clean + modern)
  static const Color primaryDark = Color(0xFF0D9488);  // deeper teal for pressed/active
  static const Color primaryLight = Color(0xFFCCFBF1); // soft teal tint for backgrounds
  // ⚫ NEUTRAL BASE
  static const Color black = Color(0xFF111827);
  static const Color darkGrey = Color(0xFF374151);

  // ⚪ BACKGROUND SYSTEM
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFF3F4F6);
  static const Color card = primaryDark;
  static const Color cardText = Colors.white;

  // 🧊 GLASS EFFECT (optional premium)
  static const Color glass = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // 🔤 TEXT SYSTEM
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // 📱 APP BAR
  static const Color appBarBg = primaryDark;
  static const Color appBarText = Colors.white;
  static const Color appBarIcon = textPrimary;
  static const Color appBarBorder = Color(0xFFE5E7EB);

  // 💰 MONEY STATES (DON’T CHANGE UX)
  static const Color credit = Color(0xFF16A34A);
  static const Color debit = Color(0xFFDC2626);

  static const Color creditBg = Color(0xFFE6F9EF);
  static const Color debitBg = Color(0xFFFDECEC);

  // 📊 BALANCE STATES
  static const Color balancePositive = credit;
  static const Color balanceNegative = debit;
  static const Color balanceNeutral = textSecondary;

  // 🧱 BORDER SYSTEM
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // 🔘 BUTTON SYSTEM
  static const Color buttonPrimaryBg = primaryDark;
  static const Color buttonPrimaryText = Colors.white;

  static const Color buttonSecondaryBg = Color(0xFFF3F4F6);
  static const Color buttonSecondaryText = textPrimary;

  static const Color buttonDisabledBg = Color(0xFFE5E7EB);
  static const Color buttonDisabledText = Color(0xFF9CA3AF);

  static const Color iconColor = Colors.white;
  static const Color iconBg = primaryLight;

  // 🏷️ CHIP / TAG
  static const Color chipBg = Color(0xFFF3F4F6);
  static const Color chipSelectedBg = Color(0xFFEDE9FE); // light purple
  static const Color chipText = Color(0xFF374151);

  // 📥 INPUT FIELD
  static const Color inputBg = Colors.white;
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputFocusedBorder = primary;
  static const Color inputErrorBorder = Color(0xFFEF4444);

  // 🌟 STATUS
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // 📅 PAYMENT STATUS
  static const Color paid = Color(0xFF16A34A);
  static const Color unpaid = Color(0xFFDC2626);
  static const Color overdue = Color(0xFFF97316);

  static const Color paidBg = Color(0xFFDCFCE7);
  static const Color unpaidBg = Color(0xFFFEE2E2);
  static const Color overdueBg = Color(0xFFFFEDD5);

  // 🌫️ GREYSCALE
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);

  // 🌈 EFFECT HELPERS
  static Color primaryOpacity(double opacity) =>
      primary.withOpacity(opacity);

  static Color blackOpacity(double opacity) =>
      Colors.black.withOpacity(opacity);

  static Color whiteOpacity(double opacity) =>
      Colors.white.withOpacity(opacity);
}