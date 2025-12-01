import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const primaryColor = Color(0xFF5161F1);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: Typography.blackMountainView.apply(
        bodyColor: const Color(0xFF1A1B2C),
        displayColor: const Color(0xFF1A1B2C),
      ),
    );
  }
}
