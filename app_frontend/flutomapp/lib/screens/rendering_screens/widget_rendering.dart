import 'package:flutomapp/screens/rendering_screens/scaffold_widget_rendering.dart';
import 'package:flutomapp/screens/rendering_screens/text_field_rendering.dart';
import 'package:flutomapp/screens/rendering_screens/text_rendering.dart';
import 'package:flutter/material.dart';

import 'box_rendering.dart';
import 'icon_rendering.dart';
import 'layout_rendering.dart';

class WidgetRendering {
  static Widget buildWidget(Map<String, dynamic> widgetData) {
    print("Rendering widget of type: ${widgetData['type']}");
    switch (widgetData['type']) {
      case 'scaffold':
        return ScaffoldWidgetRendering.buildScaffold(widgetData);
      case 'column':
        return LayoutRendering.buildColumn(widgetData);
      case 'row':
        return LayoutRendering.buildRow(widgetData);
      case 'listview':
        return LayoutRendering.buildListView(widgetData);
      case 'gridview':
        return LayoutRendering.buildGridView(widgetData);
      case 'listviewbuilder':
        return LayoutRendering.buildListViewBuilder(widgetData);
      case 'singlechildscrollview':
        return LayoutRendering.buildSingleChildScrollView(widgetData);
      case 'center':
        return LayoutRendering.buildCenter(widgetData);
      case 'container':
        return BoxRendering.buildContainer(widgetData);
      case 'sizedbox':
        return BoxRendering.buildSizedBox(widgetData);
      case 'card':
        return BoxRendering.buildCard(widgetData);
      case 'text':
        return TextRendering.buildTextWidget(widgetData);
      case 'textfield':
        return TextFieldRendering.buildTextFieldWidget(widgetData);
      case 'networkimage':
        return BoxRendering.buildNetworkImage(widgetData);
      case 'icon':
        return IconRendering.buildIcon(widgetData);
      default:
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
