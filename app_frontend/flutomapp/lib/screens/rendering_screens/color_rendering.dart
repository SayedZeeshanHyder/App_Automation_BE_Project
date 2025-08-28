import 'package:flutter/material.dart';

class ColorRendering{

  static Color buildColor(String hexCode) {
    final buffer = StringBuffer();
    if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
    hexCode = hexCode.replaceFirst('#', '');
    buffer.write(hexCode);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

}