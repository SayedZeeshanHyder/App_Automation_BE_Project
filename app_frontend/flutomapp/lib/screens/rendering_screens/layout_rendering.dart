import 'package:flutomapp/screens/rendering_screens/widget_rendering.dart';
import 'package:flutter/material.dart';

class LayoutRendering {

  static Widget buildCenter(Map<String,dynamic>? widgetData){
    print("Center Widget Built Successfully");
    return Center(
      child: widgetData?['child'] != null
          ? WidgetRendering.buildWidget(widgetData!['child'])
          : null,
    );
  }

  static Widget buildColumn(Map<String, dynamic>? widgetData) {
    print("Column Widget Built Successfully");
    final children = (widgetData?['children'] as List<dynamic>?)
        ?.map<Widget>((child) => WidgetRendering.buildWidget(child))
        .toList() ??
        [];

    return Column(
      crossAxisAlignment: buildCrossAxisAlignment(widgetData?['crossAxisAlignment']),
      mainAxisAlignment: buildMainAxisAlignment(widgetData?['mainAxisAlignment']),
      children: children,
    );
  }

  static Widget buildRow(Map<String, dynamic>? widgetData) {
    print("Row widget Built Successfully");
    final children = (widgetData?['children'] as List<dynamic>?)
        ?.map<Widget>((child) => WidgetRendering.buildWidget(child))
        .toList() ??
        [];

    return Row(
      crossAxisAlignment: buildCrossAxisAlignment(widgetData?['crossAxisAlignment']),
      mainAxisAlignment: buildMainAxisAlignment(widgetData?['mainAxisAlignment']),
      children: children,
    );
  }

  static Widget buildListView(Map<String, dynamic>? widgetData) {
    print("ListView Widget Built Successfully");
    final children = (widgetData?['children'] as List<dynamic>?)
        ?.map<Widget>((child) => WidgetRendering.buildWidget(child))
        .toList() ??
        [];

    return ListView(
      children: children,
    );
  }

  static Widget buildGridView(Map<String, dynamic>? widgetData) {
    print("GridView Widget Built Successfully");
    final children = (widgetData?['children'] as List<dynamic>?)
        ?.map<Widget>((child) => WidgetRendering.buildWidget(child))
        .toList() ??
        [];

    return GridView.count(
      crossAxisCount: widgetData?['crossAxisCount'] ?? 2,
      children: children,
    );
  }

  static Widget buildListViewBuilder(Map<String, dynamic>? widgetData) {
    print("ListViewBuilder Widget Built Successfully");

    try {
      final itemTemplate = widgetData?['itemTemplate'] as Map<String, dynamic>?;
      dynamic dataListRaw = widgetData?['dataList'];
      List<dynamic> dataList = [];

      if (dataListRaw is List<dynamic>) {
        dataList = dataListRaw;
      } else if (dataListRaw is String) {
        print("ERROR: dataList is a string reference: $dataListRaw");
        print("This means the template wasn't processed with actual API data.");
        return Center(
          child: Text('ListView dataList is a string reference, not actual data'),
        );
      } else {
        print("ERROR: dataList is neither List nor String: ${dataListRaw.runtimeType}");
        dataList = [];
      }

      final dataKeys = widgetData?['dataKeys'] as Map<String, dynamic>? ?? {};

      if (itemTemplate == null) {
        print("ERROR: itemTemplate is null");
        return Center(
          child: Text('ListView template not found'),
        );
      }

      print("ListView.builder - Items count: ${dataList.length}");
      print("ListView.builder - DataKeys: $dataKeys");
      print("ListView.builder - ItemTemplate structure: $itemTemplate");

      // Print sample data with types
      if (dataList.isNotEmpty) {
        print("ListView.builder - Sample data item 0:");
        final sampleItem = dataList.first;
        if (sampleItem is Map<String, dynamic>) {
          sampleItem.forEach((key, value) {
            print("  $key: $value (${value.runtimeType})");
          });
        }
      }

      if (dataList.isEmpty) {
        return Center(
          child: Text('No data available'),
        );
      }

      return ListView.builder(
        shrinkWrap: widgetData?['shrinkWrap'] ?? false,
        physics: widgetData?['physics'] != null
            ? buildScrollPhysics(widgetData!['physics'])
            : const AlwaysScrollableScrollPhysics(),
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          try {
            final currentData = dataList[index] as Map<String, dynamic>? ?? {};
            print("\n=== Processing item $index ===");
            print("Current data: $currentData");

            // Log data types for debugging
            currentData.forEach((key, value) {
              print("Data[$key]: $value (${value.runtimeType})");
            });

            // Create a copy of the template and replace placeholders with actual data
            print("Original template: $itemTemplate");
            final processedTemplate = _processTemplate(itemTemplate, currentData, dataKeys);
            print("Final processed template: $processedTemplate");

            return WidgetRendering.buildWidget(processedTemplate);
          } catch (e, stackTrace) {
            print("Error building item $index: $e");
            print("StackTrace: $stackTrace");
            return Container(
              height: 50,
              color: Colors.red[100],
              child: Center(
                child: Text('Error loading item $index: ${e.toString()}'),
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      print("Error in buildListViewBuilder: $e");
      print("StackTrace: $stackTrace");
      return Container(
        color: Colors.red[100],
        child: Center(
          child: Text('ListView error: ${e.toString()}'),
        ),
      );
    }
  }

  static Map<String, dynamic> _processTemplate(Map<String, dynamic> template, Map<String, dynamic> currentData, Map<String, dynamic> dataKeys) {
    try {
      print("\n--- _processTemplate called ---");
      print("Template keys: ${template.keys.toList()}");
      print("CurrentData keys: ${currentData.keys.toList()}");
      print("DataKeys mapping: $dataKeys");

      // Create a deep copy of the template to avoid modifying the original
      Map<String, dynamic> processed = _deepCopyMap(template);

      // Recursively process the template
      _processNode(processed, currentData, dataKeys);

      print("Template processing completed");
      return processed;
    } catch (e, stackTrace) {
      print("Error in _processTemplate: $e");
      print("StackTrace: $stackTrace");
      print("Template: $template");
      print("CurrentData: $currentData");
      print("DataKeys: $dataKeys");
      rethrow;
    }
  }

  static void _processNode(Map<String, dynamic> node, Map<String, dynamic> currentData, Map<String, dynamic> dataKeys) {
    try {
      List<String> keys = node.keys.toList();
      print("Processing node with keys: $keys");

      for (String key in keys) {
        dynamic value = node[key];
        print("Processing key '$key' with value '$value' (${value.runtimeType})");

        if (value is String && value.startsWith('{{') && value.endsWith('}}')) {
          String dataKey = value.substring(2, value.length - 2).trim();
          String actualKey = dataKeys[dataKey]?.toString() ?? dataKey;
          dynamic apiValue = currentData[actualKey];

          print("Found placeholder: $value");
          print("  DataKey: '$dataKey'");
          print("  ActualKey: '$actualKey'");
          print("  ApiValue: '$apiValue' (${apiValue.runtimeType})");
          print("  Key expects numeric: ${_isNumericProperty(key)}");

          if (apiValue == null) {
            print("  Setting to empty string");
            node[key] = "";
          } else if (apiValue is String) {
            if (_isNumericProperty(key)) {
              double? numValue = double.tryParse(apiValue);
              if (numValue != null) {
                print("  Parsed string '$apiValue' to double: $numValue");
                node[key] = numValue;
              } else {
                print("  WARNING: Could not parse '$apiValue' as number for key '$key', using 0.0");
                node[key] = 0.0;
              }
            } else {
              print("  Using string value: '$apiValue'");
              node[key] = apiValue;
            }
          } else if (apiValue is num) {
            if (_isNumericProperty(key)) {
              print("  Converting num $apiValue to double: ${apiValue.toDouble()}");
              node[key] = apiValue.toDouble();
            } else {
              print("  Converting num $apiValue to string: ${apiValue.toString()}");
              node[key] = apiValue.toString();
            }
          } else {
            print("  Converting ${apiValue.runtimeType} to string: ${apiValue.toString()}");
            node[key] = apiValue.toString();
          }
        } else if (value is Map<String, dynamic>) {
          print("  Recursing into map for key '$key'");
          _processNode(value, currentData, dataKeys);
        } else if (value is List) {
          print("  Processing list for key '$key' with ${value.length} items");
          for (int i = 0; i < value.length; i++) {
            if (value[i] is Map<String, dynamic>) {
              print("    Recursing into list item $i (map)");
              _processNode(value[i], currentData, dataKeys);
            } else if (value[i] is String &&
                value[i].startsWith('{{') &&
                value[i].endsWith('}}')) {
              String dataKey = value[i].substring(2, value[i].length - 2).trim();
              String actualKey = dataKeys[dataKey]?.toString() ?? dataKey;
              dynamic apiValue = currentData[actualKey];
              print("    Replacing list placeholder: ${value[i]} with key: $actualKey, value: $apiValue (${apiValue.runtimeType})");
              if (apiValue == null) {
                value[i] = "";
              } else {
                value[i] = apiValue.toString();
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      print("Error in _processNode: $e");
      print("StackTrace: $stackTrace");
      print("Node: $node");
      print("CurrentData: $currentData");
      print("DataKeys: $dataKeys");
      rethrow;
    }
  }

  static Map<String, dynamic> _deepCopyMap(Map<String, dynamic> original) {
    Map<String, dynamic> copy = {};
    original.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        copy[key] = _deepCopyMap(value);
      } else if (value is List) {
        copy[key] = _deepCopyList(value);
      } else {
        copy[key] = value;
      }
    });
    return copy;
  }

  static List<dynamic> _deepCopyList(List<dynamic> original) {
    List<dynamic> copy = [];
    for (var item in original) {
      if (item is Map<String, dynamic>) {
        copy.add(_deepCopyMap(item));
      } else if (item is List) {
        copy.add(_deepCopyList(item));
      } else {
        copy.add(item);
      }
    }
    return copy;
  }

  static bool _isNumericProperty(String key) {
    const numericProperties = {
      'fontSize', 'elevation', 'width', 'height',
      'borderWidth', 'borderRadius', 'margin', 'padding',
      'size', 'maxLines', 'flex', 'spacing', 'runSpacing',
      'itemCount', 'crossAxisCount', 'childAspectRatio',
      'mainAxisSpacing', 'crossAxisSpacing'
    };
    return numericProperties.contains(key);
  }

  static Widget buildSingleChildScrollView(Map<String, dynamic>? widgetData) {
    print("SingleChildScrollView Widget Built Successfully");
    return SingleChildScrollView(
      physics: buildScrollPhysics(widgetData?['physics']),
      child: widgetData?['child'] != null
          ? WidgetRendering.buildWidget(widgetData!['child'])
          : const SizedBox.shrink(),
    );
  }

  static ScrollPhysics buildScrollPhysics(String? physicsType) {
    if(physicsType == null || physicsType.isEmpty) {
      return const AlwaysScrollableScrollPhysics();
    }
    switch (physicsType) {
      case 'alwaysScrollableScrollPhysics':
        return const AlwaysScrollableScrollPhysics();
      case 'neverScrollableScrollPhysics':
        return const NeverScrollableScrollPhysics();
      case 'bouncingScrollPhysics':
        return const BouncingScrollPhysics();
      case 'clampingScrollPhysics':
        return const ClampingScrollPhysics();
      default:
        return const AlwaysScrollableScrollPhysics();
    }
  }

  static MainAxisAlignment buildMainAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment buildCrossAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

}