import 'package:flutter/material.dart';

class AppColors {

  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);

  static const Color backgroundColor = Colors.white;
  static const Color cardBackground = Colors.white;

  static const Color primaryText = Color(0xFF2E7D32);
  static const Color secondaryText = Color(0xFF757575);
  static const Color lightText = Color(0xFF9E9E9E);
  static const Color whiteText = Colors.white;

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
  ];

  static const List<Color> logoGradient = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFF66BB6A),
  ];

  // Opacity Colors
  static const Color primaryGreenOpacity05 = Color(0x0D4CAF50);
  static const Color primaryGreenOpacity08 = Color(0x144CAF50);
  static const Color primaryGreenOpacity10 = Color(0x1A4CAF50);
  static const Color primaryGreenOpacity30 = Color(0x4D4CAF50);

  static const Color borderColor = Color(0x1A4CAF50);
  static const Color dividerColor = Color(0xFFE0E0E0);

  static const Color shadowColor = Color(0x4D4CAF50);
  static const Color lightShadow = Color(0x144CAF50);

  static const Color buttonPrimary = Color(0xFF4CAF50);
  static const Color buttonText = Colors.white;

  static const Color progressBackground = Color(0x1A4CAF50);
  static const Color progressForeground = Color(0xFF4CAF50);

  static LinearGradient get primaryLinearGradient => const LinearGradient(
    colors: primaryGradient,
  );

  static LinearGradient get logoLinearGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: logoGradient,
  );

  static Color getPrimaryWithOpacity(double opacity) {
    return primaryGreen.withOpacity(opacity);
  }

  static Color getGreyWithOpacity(int greyShade, double opacity) {
    return Colors.grey[greyShade]!.withOpacity(opacity);
  }
}