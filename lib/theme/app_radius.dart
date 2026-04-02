import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // 🔹 BASIC RADII
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  // 🔹 COMMON BORDER RADIUS (READY TO USE)
  static const BorderRadius radiusSM =
  BorderRadius.all(Radius.circular(sm));

  static const BorderRadius radiusMD =
  BorderRadius.all(Radius.circular(md));

  static const BorderRadius radiusLG =
  BorderRadius.all(Radius.circular(lg));

  static const BorderRadius radiusXL =
  BorderRadius.all(Radius.circular(xl));

  // 🔹 SPECIAL USE CASES

  // cards
  static const BorderRadius card =
  BorderRadius.all(Radius.circular(lg));

  // buttons
  static const BorderRadius button =
  BorderRadius.all(Radius.circular(md));

  // input fields
  static const BorderRadius input =
  BorderRadius.all(Radius.circular(md));

  // chips / tags (rounded)
  static const BorderRadius pill =
  BorderRadius.all(Radius.circular(50));

  // bottom sheets / modals (top rounded only)
  static const BorderRadius bottomSheet =
  BorderRadius.vertical(top: Radius.circular(lg));
}