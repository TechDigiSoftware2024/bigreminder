import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  // 🌫️ LIGHT SHADOW (most used - cards)
  static List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // 🌫️ MEDIUM SHADOW (modals, bottom sheets)
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // 🌫️ STRONG SHADOW (rare use - floating elements)
  static List<BoxShadow> strong = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // 🔘 BUTTON SHADOW
  static List<BoxShadow> button = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 5),
    ),
  ];

  // 🧊 GLASS EFFECT SHADOW (very subtle)
  static List<BoxShadow> glass = [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}