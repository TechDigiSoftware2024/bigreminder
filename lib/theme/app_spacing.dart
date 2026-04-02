import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  // 🔹 BASE SPACING SCALE
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // 🔹 SIZEDBOX HELPERS (vertical)
  static const SizedBox vxs = SizedBox(height: xs);
  static const SizedBox vsm = SizedBox(height: sm);
  static const SizedBox vmd = SizedBox(height: md);
  static const SizedBox vlg = SizedBox(height: lg);
  static const SizedBox vxl = SizedBox(height: xl);
  static const SizedBox vxxl = SizedBox(height: xxl);

  // 🔹 SIZEDBOX HELPERS (horizontal)
  static const SizedBox hxs = SizedBox(width: xs);
  static const SizedBox hsm = SizedBox(width: sm);
  static const SizedBox hmd = SizedBox(width: md);
  static const SizedBox hlg = SizedBox(width: lg);
  static const SizedBox hxl = SizedBox(width: xl);
  static const SizedBox hxxl = SizedBox(width: xxl);

  // 🔹 EDGE INSETS (padding shortcuts)
  static const EdgeInsets allXS = EdgeInsets.all(xs);
  static const EdgeInsets allSM = EdgeInsets.all(sm);
  static const EdgeInsets allMD = EdgeInsets.all(md);
  static const EdgeInsets allLG = EdgeInsets.all(lg);
  static const EdgeInsets allXL = EdgeInsets.all(xl);

  static const EdgeInsets horizontalMD =
  EdgeInsets.symmetric(horizontal: md);

  static const EdgeInsets verticalMD =
  EdgeInsets.symmetric(vertical: md);

  static const EdgeInsets screenPadding =
  EdgeInsets.symmetric(horizontal: lg, vertical: md);
}