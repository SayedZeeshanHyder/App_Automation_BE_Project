import 'package:flutter/material.dart';
import 'package:material_symbols_icons/get.dart';

import 'color_rendering.dart';

class IconRendering {
  static Widget buildIcon(Map<String, dynamic> widgetData) {
    String iconName = widgetData['name'] ?? 'help';
    IconData icon;
    try {
      icon = SymbolsGet.get(iconName,SymbolStyle.sharp);
    } catch (_) {
      icon = SymbolsGet.get("help", SymbolStyle.sharp);
    }
    return Icon(
      icon,
      color: ColorRendering.buildColor(widgetData['color']),
      size: (widgetData['size'] ?? 24).toDouble(),
    );
  }
}
