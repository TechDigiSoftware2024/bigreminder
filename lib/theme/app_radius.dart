import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 10.0;

  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(4));
  static const BorderRadius bottomSheet =
      BorderRadius.vertical(top: Radius.circular(lg));
}
