import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/api_constants.dart';

class BuildService {

  static Future<BuildResponse> buildProject({
    required String projectId,
    String instructions = '',
    int initialScreenIndex = 0,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/build/$projectId');
      String token = SharedPreferencesService.getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'instructions': instructions,
          'initialScreenIndex': initialScreenIndex,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw BuildException(
            'Request timed out. Please check your connection and try again.',
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BuildResponse(
          success: true,
          buildId: data['buildId'],
          message: data['buildStatus'],
        );
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw BuildException(
          data['message'] ?? 'Bad request. Please check your project data.',
        );
      } else if (response.statusCode == 401) {
        throw BuildException(
          'Unauthorized. Please check your authentication token.',
        );
      } else if (response.statusCode == 404) {
        throw BuildException(
          'Project not found. Please verify the project ID.',
        );
      } else if (response.statusCode == 500) {
        throw BuildException(
          'Server error. Please try again later.',
        );
      } else {
        throw BuildException(
          'Failed to build project. Status code: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      throw BuildException(
        'Network error: ${e.message}. Please check your internet connection.',
      );
    } on FormatException catch (_) {
      throw BuildException(
        'Invalid response from server. Please try again.',
      );
    } catch (e) {
      if (e is BuildException) {
        rethrow;
      }
      throw BuildException(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}

class BuildResponse {
  final bool success;
  final String? buildId;
  final String message;

  BuildResponse({
    required this.success,
    this.buildId,
    required this.message,
  });
}

class BuildException implements Exception {
  final String message;

  BuildException(this.message);

  @override
  String toString() => message;
}