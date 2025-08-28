import 'package:flutomapp/screens/rendering_screens/text_rendering.dart';
import 'package:flutter/material.dart';

import 'color_rendering.dart';

class TextFieldRendering {
  static TextField buildTextFieldWidget(Map<String, dynamic>? widgetData) {
    print("TextField Rendered Successfully");
    return TextField(
      style: TextRendering.buildTextStyle(widgetData?['style'] ?? {}),
      decoration: InputDecoration(
        labelText: widgetData?['labelText'] ?? "",
        hintText: widgetData?['hintText'] ?? "",
        border: buildBorder(widgetData?['border'] as Map<String, dynamic>?),
        filled: widgetData?['filled'] ?? false,
        fillColor: ColorRendering.buildColor(widgetData?['fillColor'] ?? "#FFFFFF"),
      ),
      obscureText: widgetData?['obscureText'] ?? false,
      keyboardType: buildKeyboardType(widgetData?['keyboardType'] ?? ""),
    );
  }

  static TextInputType buildKeyboardType(String? keyboardType) {
    switch (keyboardType) {
      case 'text':
        return TextInputType.text;
      case 'number':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  static InputBorder buildBorder(Map<String, dynamic>? widgetData) {
    if (widgetData == null) {
      return const OutlineInputBorder(); // default border
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular((widgetData['borderRadius'] as num?)?.toDouble() ?? 4.0),
      borderSide: BorderSide(
        color: ColorRendering.buildColor(widgetData['borderColor']),
        width: (widgetData['borderWidth'] as num?)?.toDouble() ?? 1.0,
      ),
    );
  }
}
