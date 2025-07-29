import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants{

  static const String gemini_baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.103:5050';

  static final String createFlutterProject  = "/create-flutter-project";

}