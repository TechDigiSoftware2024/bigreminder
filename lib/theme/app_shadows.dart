import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> light = [
    BoxShadow(
      color: Color(0x0A1A2332),
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x141A2332),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> strong = [
    BoxShadow(
      color: Color(0x1F1A2332),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> button = <BoxShadow>[];

  static const List<BoxShadow> glass = light;
}
