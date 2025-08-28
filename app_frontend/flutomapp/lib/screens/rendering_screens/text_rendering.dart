import 'package:flutter/material.dart';

import 'color_rendering.dart';

class TextRendering {
  static Text buildTextWidget(Map<String, dynamic>? widgetData) {
    print("Text Rendered Successfully ${widgetData?['data']}");

    final String text = widgetData?['data']?.toString() ?? '';

    return Text(
      text,
      style: buildTextStyle(widgetData?['style'] as Map<String, dynamic>?),
    );
  }

  static TextStyle buildTextStyle(Map<String, dynamic>? styleData) {
    if (styleData == null || styleData.isEmpty) {
      return const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      );
    }

    return TextStyle(
      fontSize: _toDouble(styleData['fontSize']) ?? 14.0,
      fontWeight: buildFontWeight(styleData['fontWeight']?.toString()),
      color: ColorRendering.buildColor(styleData['color']) ?? Colors.black,
    );
  }

  static FontWeight buildFontWeight(String? fontWeight) {
    switch (fontWeight) {
      case 'bold':
        return FontWeight.bold;
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w500;
      case 'normal':
      default:
        return FontWeight.normal;
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
