import 'dart:convert';

import 'package:flutomapp/constants/api_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiApiService {
  static Future<Map<String, dynamic>> hitGeminiApi(String prompt) async {
    String geminiApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
    if (geminiApiKey.isEmpty) {
      return {"success": false, "response": 'Error: API key is not set'};
    }
    final response = await http.post(
      Uri.parse(ApiConstants.gemini_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "X-goog-api-key": geminiApiKey,
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode.toString().startsWith("2")) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['candidates'] != null &&
          responseBody['candidates'].isNotEmpty) {
        return {
          "success": true,
          "response":
              responseBody['candidates'][0]['content']['parts'][0]['text'],
        };
      } else {
        return {
          "success": false,
          "response": 'Error: No candidates found in response',
        };
      }
    } else {
      return {
        "success": false,
        "response": 'Error: ${response.statusCode} - ${response.body}',
      };
    }
  }
}
