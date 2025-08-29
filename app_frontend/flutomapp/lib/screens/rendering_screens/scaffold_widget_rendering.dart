import 'package:flutomapp/screens/rendering_screens/text_rendering.dart';
import 'package:flutomapp/screens/rendering_screens/widget_rendering.dart';
import 'package:flutter/material.dart';

import 'color_rendering.dart';

class ScaffoldWidgetRendering {
  static PreferredSizeWidget? buildAppBar(Map<String, dynamic>? widgetData) {
    if (widgetData == null) return null;
    print("AppBar Rendered Successfully");
    return AppBar(
      title: widgetData['title'] != null
          ? WidgetRendering.buildWidget(widgetData['title'])
          : null,
      backgroundColor: ColorRendering.buildColor(widgetData['backgroundColor']),
      actions: (widgetData['actions'] as List<dynamic>?)
          ?.map<Widget>((action) => WidgetRendering.buildWidget(action))
          .toList() ??
          [],
      leading: widgetData['leading'] != null
          ? WidgetRendering.buildWidget(widgetData['leading'])
          : null,
      elevation: (widgetData['elevation'] as num?)?.toDouble() ?? 0.0,
      centerTitle: widgetData['centerTitle'] ?? false,
      foregroundColor:
      ColorRendering.buildColor(widgetData['foregroundColor'] ?? "#FFFFFF"),
      automaticallyImplyLeading:
      widgetData['automaticallyImplyLeading'] ?? true,
      titleTextStyle: TextRendering.buildTextStyle(
          widgetData['titleTextStyle'] as Map<String, dynamic>? ?? {}),
    );
  }

  static Widget buildScaffold(Map<String, dynamic>? widgetData) {
    print("Scaffold Rendered Successfully");
    return Scaffold(
      appBar: buildAppBar(widgetData?['appBar']),
      body: widgetData?['body'] != null
          ? WidgetRendering.buildWidget(widgetData!['body'])
          : const SizedBox.shrink(),
      backgroundColor:
      ColorRendering.buildColor(widgetData?['backgroundColor']),
    );
  }
}
