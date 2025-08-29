import 'dart:typed_data';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class ApiService {
  static Future<Uint8List?> createFlutterProject({
    required String projectName,
    required String organization,
    required String description,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.createFlutterProject}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectName': projectName,
          'organization': organization,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  static Future<void> createScreen({
    required String projectId,
    required Map<String, dynamic> screenData,
  }) async {
    final String token = SharedPreferencesService.getToken();
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/project/$projectId');

    print(projectId);
    print(screenData);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(screenData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create screen: ${response.body}');
    }
  }

  static Future<void> updateScreen({
    required String projectId,
    required String screenId,
    required Map<String, dynamic> screenData,
  }) async {
    final String token = SharedPreferencesService.getToken();
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/project');

    final body = {
      "projectId": projectId,
      "screenId": screenId,
      "screen": screenData,
    };

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update screen: ${response.body}');
    }
  }
}
