import 'package:flutter/material.dart';

class ColorRendering {
  static Color buildColor(String hexCode) {
    // Handle special case for "transparent"
    if (hexCode.toLowerCase() == 'transparent') {
      return Colors.transparent;
    }

    // Remove '#' if present
    hexCode = hexCode.replaceFirst('#', '');

    // Add alpha if missing
    final buffer = StringBuffer();
    if (hexCode.length == 6) buffer.write('ff'); // default alpha
    buffer.write(hexCode);

    // Parse hex to Color
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      // fallback color if parsing fails
      print('Invalid color code: $hexCode. Using Colors.black as fallback.');
      return Colors.black;
    }
  }
}