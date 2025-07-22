import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants{

  static const String gemini_baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://flutomapp.com/api';

  static final String createFlutterProject  = "/create-flutter-project";

}