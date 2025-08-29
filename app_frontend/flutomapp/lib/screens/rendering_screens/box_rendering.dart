import 'package:flutomapp/screens/rendering_screens/widget_rendering.dart';
import 'package:flutter/material.dart';

import 'color_rendering.dart';

class BoxRendering {
  static Widget buildContainer(Map<String,dynamic>? widgetData){
    print("Container Widget Built Successfully");
    if (widgetData == null) {
      return Container();
    }
    final dynamic colorData = widgetData['color'];
    final Color? color = colorData == null
        ? null
        : ColorRendering.buildColor(colorData);

    final double? width = _toDouble(widgetData['width']);
    final double? height = _toDouble(widgetData['height']);
    return Container(
      width: width,
      height: height,
      padding: buildEdgeInsets(widgetData?['padding']),
      margin: buildEdgeInsets(widgetData?['margin']),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular((widgetData?['borderRadius'] as num?)?.toDouble() ?? 0.0),
      ),
      child: widgetData?['child'] != null
          ? WidgetRendering.buildWidget(widgetData!['child'])
          : null,
    );
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  static EdgeInsets buildEdgeInsets(dynamic data) {
    if (data is Map) {
      return EdgeInsets.only(
        left: (data['left'] as num?)?.toDouble() ?? 0.0,
        top: (data['top'] as num?)?.toDouble() ?? 0.0,
        right: (data['right'] as num?)?.toDouble() ?? 0.0,
        bottom: (data['bottom'] as num?)?.toDouble() ?? 0.0,
      );
    } else if (data is num) {
      return EdgeInsets.all(data.toDouble());
    } else {
      return EdgeInsets.zero;
    }
  }

  static Widget buildSizedBox(Map<String, dynamic>? widgetData) {
    print("SizedBox Widget Built Successfully");
    return SizedBox(
      width: (widgetData?['width'] as num?)?.toDouble(),
      height: (widgetData?['height'] as num?)?.toDouble(),
      child: widgetData?['child'] != null
          ? WidgetRendering.buildWidget(widgetData!['child'])
          : null,
    );
  }

  static Widget buildCard(Map<String, dynamic>? widgetData) {
    print("Card Widget Built Successfully");
    return Card(
      shape: buildShapeBorder(widgetData),
      color: ColorRendering.buildColor(widgetData?['color']),
      elevation: (widgetData?['elevation'] as num?)?.toDouble() ?? 1.0,
      child: widgetData?['child'] != null
          ? WidgetRendering.buildWidget(widgetData!['child'])
          : null,
    );
  }

  static BoxDecoration buildBoxDecoration(Map<String, dynamic>? widgetData) {
    final border = widgetData?['border'] as Map<String, dynamic>?;
    final boxShadow = widgetData?['boxShadow'] as Map<String, dynamic>?;

    return BoxDecoration(
      shape: buildBoxShape(widgetData),
      color: ColorRendering.buildColor(widgetData?['color']),
      borderRadius: BorderRadius.circular((widgetData?['borderRadius'] as num?)?.toDouble() ?? 0.0),
      border: border != null
          ? Border.all(
        color: ColorRendering.buildColor(border['color']),
        width: (border['width'] as num?)?.toDouble() ?? 1.0,
      )
          : null,
      boxShadow: boxShadow != null
          ? [
        BoxShadow(
          color: ColorRendering.buildColor(boxShadow['color']),
          blurRadius: (boxShadow['blurRadius'] as num?)?.toDouble() ?? 0.0,
          offset: Offset(
            (boxShadow['offsetX'] as num?)?.toDouble() ?? 0.0,
            (boxShadow['offsetY'] as num?)?.toDouble() ?? 0.0,
          ),
        ),
      ]
          : null,
    );
  }

  static BoxShape buildBoxShape(Map<String, dynamic>? widgetData) {
    switch (widgetData?['shape']) {
      case 'circle':
        return BoxShape.circle;
      case 'rectangle':
      default:
        return BoxShape.rectangle;
    }
  }

  static ShapeBorder buildShapeBorder(Map<String, dynamic>? widgetData) {
    final borderRadius = BorderRadius.circular((widgetData?['borderRadius'] as num?)?.toDouble() ?? 0.0);
    switch (widgetData?['shape']) {
      case 'circle':
        return const CircleBorder();
      case 'beveledRectangle':
        return BeveledRectangleBorder(borderRadius: borderRadius);
      case 'roundedRectangle':
        return RoundedRectangleBorder(borderRadius: borderRadius);
      default:
        return const RoundedRectangleBorder();
    }
  }

  static Widget buildNetworkImage(Map<String, dynamic>? widgetData) {
    print("NetworkImage Widget Built Successfully");
    print(widgetData);
    if (widgetData == null || widgetData['url'] == null) {
      return Container();
    }

    // Helper function to safely get double value or return static default
    double? getDoubleOrDefault(dynamic value, double? staticDefault) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
        // If parsing fails, return the static default
        return staticDefault;
      }
      return staticDefault;
    }

    // Get width - if it's not a valid number, use a static default (e.g., 200.0)
    double? width = getDoubleOrDefault(widgetData['width'], 200.0);

    // Get height - if it's not a valid number, use a static default (e.g., 200.0)
    double? height = getDoubleOrDefault(widgetData['height'], 200.0);

    return Image.network(
        widgetData['url'],
        width: width,
        height: height,
        fit: buildBoxFit(widgetData['fit']),
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey,
            child: const Center(
              child: Text(
                'Image failed to load',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
    );
  }

  static BoxFit buildBoxFit(widgetData) {
    switch (widgetData) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.scaleDown;
    }
  }
}
