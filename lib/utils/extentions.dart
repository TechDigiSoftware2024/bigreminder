import 'package:flutter/material.dart';

/// 🔤 STRING EXTENSIONS
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return this[0].toUpperCase() + substring(1);
  }

  String capitalizeWords() {
    return split(' ')
        .map((word) => word.capitalize())
        .join(' ');
  }

  bool get isValidNumber {
    return double.tryParse(this) != null;
  }
}

/// 📱 CONTEXT EXTENSIONS
extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

/// 📦 WIDGET EXTENSIONS (VERY USEFUL 🔥)
extension WidgetExtension on Widget {
  Widget paddingAll(double value) {
    return Padding(
      padding: EdgeInsets.all(value),
      child: this,
    );
  }

  Widget paddingSymmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: this,
    );
  }

  Widget center() {
    return Center(child: this);
  }
}