import 'dart:convert';
import 'package:flutomapp/bindings/dynamic_rendering_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../constants/gemini_prompts.dart';
import '../../controller/dynamic_render_prompt_controller.dart';
import '../../models/project_model.dart';
import '../rendering_screens/dynamic_rendering.dart';
import '../rendering_screens/hit_gemini_api.dart';

class PromptScreen extends StatefulWidget {
  final String projectId;
  const PromptScreen({super.key, required this.projectId});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final _screenNameController = TextEditingController();
  final _promptController = TextEditingController();
  final _apiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // A professional color scheme for the UI
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _cardBackgroundColor = Colors.white;

  @override
  void dispose() {
    _screenNameController.dispose();
    _promptController.dispose();
    _apiController.dispose();
    super.dispose();
  }

  Future<void> _generateUi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String formattedData;
      try {
        var data = await hitApi(_apiController.text.trim());
        formattedData = formatApiResponseForPrompt(data);
      } catch (e) {
        debugPrint("Error during context API call: $e");
        formattedData = "No data available. Assume data based on the screen description.";
      }

      String prompt = GeminiPrompts.generateGeminiPrompt(
        _promptController.text.trim(),
        formattedData,
      );

      var generatedUI = await HitGeminiAPI.hitGeminiAPI(prompt);

      if (mounted) {
        // This is a placeholder for passing the project context.
        final projectForApi = Project(
          id: widget.projectId,
          projectName: "Temp",
          status: '',
          createdAt: DateTime.now(),
          lastBuildAt: DateTime.now(),
          organisationId: '',
          listOfScreens: [],
          envVariables: [],
          androidPermissions: [],
          firebaseConfigured: false,
        );

        // MODIFIED: Replaced Navigator.push with Get.to, adding the binding and arguments
        Get.to(
              () => const DynamicRenderingScreen(),
          binding: DynamicRenderingBinding(), // The crucial binding that creates the controller
          arguments: {
            'widgetData': generatedUI,
            'mode': ScreenMode.create,
            'project': projectForApi,
            'initialPrompt': _promptController.text.trim(),
            'screenName': _screenNameController.text.trim(),
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate UI: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('AI Screen Generator', style: TextStyle(color: _primaryTextColor)),
        backgroundColor: _cardBackgroundColor,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _primaryTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Name Your Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryTextColor)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _screenNameController,
                decoration: _inputDecoration(
                  hintText: 'e.g., "Login Screen" or "User Profile"',
                  icon: Icons.label_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name for the screen.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text('2. Describe Your Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryTextColor)),
              const SizedBox(height: 8),
              const Text('Explain the UI you want to create. Be as descriptive as possible.', style: TextStyle(fontSize: 15, color: _secondaryTextColor)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _promptController,
                maxLines: 5,
                decoration: _inputDecoration(
                  hintText: 'e.g., "Create a login screen with email and password fields..."',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description for the screen.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text('3. Provide Data Source (Optional)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryTextColor)),
              const SizedBox(height: 8),
              const Text('Enter a GET API endpoint to provide real data context for the UI.', style: TextStyle(fontSize: 15, color: _secondaryTextColor)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _apiController,
                decoration: _inputDecoration(
                  hintText: 'e.g., "https://api.example.com/users/1"',
                  icon: Icons.http_outlined,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateUi,
                  icon: _isLoading ? Container() : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                      : const Text('Generate UI', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: _secondaryTextColor),
      filled: true,
      fillColor: _cardBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }

  static Future<Map<String, dynamic>> hitApi(String apiUrl) async {
    if (apiUrl.isEmpty) {
      return {"type": "map", "data": {}};
    }
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map) {
        return {"type": "map", "data": data as Map<String, dynamic>};
      } else if (data is List) {
        return {"type": "list", "data": data as List<dynamic>};
      } else {
        throw Exception('Unsupported JSON structure.');
      }
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  static String formatApiResponseForPrompt(Map<String, dynamic> apiResult) {
    final type = apiResult['type'];
    final data = apiResult['data'];
    if ((type == 'map' && (data as Map).isEmpty) || (type == 'list' && (data as List).isEmpty)) {
      return "No data available. Assume data based on the screen description.";
    }
    final encoder = JsonEncoder.withIndent('  ');
    if (type == 'map') {
      return 'Here is the Data to be shown (as a Map):\n\n${encoder.convert(data)}';
    } else {
      return 'Here is the Data to be shown (as a List):\n\n${encoder.convert(data)}';
    }
  }
}