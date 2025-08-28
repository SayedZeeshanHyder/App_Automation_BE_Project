import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HitGeminiAPI{

  static Future<Map<String, dynamic>> hitGeminiAPI(String prompt) async {
    String geminiAPIKEY = dotenv.env['GOOGLE_API_KEY'] ?? '';
    final response = await http.post(Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),headers: {
      "Content-Type": "application/json",
      "X-goog-api-key": geminiAPIKEY
    },body: jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text": prompt
            }
          ]
        }
      ]
    }));

    if (response.statusCode == 200) {
      String responseData = jsonDecode(response.body)["candidates"][0]['content']["parts"][0]['text'];
      responseData = responseData.replaceAll('''"width": double.infinity''','''"width:${Get.size.width}''');
      responseData = responseData.replaceAll('''"height": double.infinity''','''"height:${Get.size.height}''');
      print("Code Generated: $responseData");
      print('''Code Contains ${responseData.contains('"width": double.infinity}')}''');
      return jsonDecode(responseData.substring(responseData.indexOf("{"),responseData.lastIndexOf("}") + 1));
    } else {

      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

}