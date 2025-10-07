import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../constants/api_constants.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _loadingMessage = '';
  final _projectNameController = TextEditingController();
  final _organisationNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, TextEditingController>> _envControllers = [];
  final List<TextEditingController> _permissionControllers = [];
  bool _requireFirebase = false;
  File? _googleServicesJson;
  File? _appIcon;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _projectNameController.dispose();
    _organisationNameController.dispose();
    _descriptionController.dispose();
    for (var controllers in _envControllers) {
      controllers['key']!.dispose();
      controllers['value']!.dispose();
    }
    for (var controller in _permissionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEnvVariable() {
    setState(() {
      _envControllers.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeEnvVariable(int index) {
    setState(() {
      _envControllers[index]['key']!.dispose();
      _envControllers[index]['value']!.dispose();
      _envControllers.removeAt(index);
    });
  }

  void _addPermission() {
    setState(() {
      _permissionControllers.add(TextEditingController());
    });
  }

  void _removePermission(int index) {
    setState(() {
      _permissionControllers[index].dispose();
      _permissionControllers.removeAt(index);
    });
  }

  Future<void> _pickAppIcon() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _appIcon = File(image.path);
      });
    }
  }

  Future<void> _pickGoogleServicesJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      setState(() {
        _googleServicesJson = File(result.files.single.path!);
      });
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_requireFirebase && _googleServicesJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload google-services.json as Firebase is required.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = '🚀 Preparing your project...';
    });

    String token = SharedPreferencesService.getToken();
    const String dummyAuthToken =
        'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiVVNFUiIsInN1YiI6ImFiYyIsImlhdCI6MTc1NjQ0ODY5MSwiZXhwIjoxNzU5MDQwNjkxfQ.tcRiI1j_0dEJaSgiC7WulTpGueCKkt1pdBW6NnGzelU';

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createProjectApi}'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['projectName'] = _projectNameController.text;
    request.fields['organisationName'] = _organisationNameController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['requireFirebase'] = _requireFirebase.toString();
    for (var controllers in _envControllers) {
      request.fields['envKeys'] = controllers['key']!.text;
      request.fields['envValues'] = controllers['value']!.text;
    }
    for (var controller in _permissionControllers) {
      request.fields['androidPermissions'] = controller.text;
    }

    try {
      if (_appIcon != null) {
        request.files.add(
          await http.MultipartFile.fromPath('appIcon', _appIcon!.path),
        );
      }
      if (_requireFirebase && _googleServicesJson != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'googleServicesJson',
            _googleServicesJson!.path,
          ),
        );
      }

      setState(() {
        _loadingMessage =
            '⚙️ Building and configuring... This may take a moment.';
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${response.statusCode} - $responseBody TertiaryDataType="String">responseBody',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create New Project'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey[800],
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildForm(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 20),
          Text(
            _loadingMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Please don't close the app.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Project Details
            _buildSectionCard(
              title: 'Project Details',
              icon: Icons.article_outlined,
              child: Column(
                children: [
                  _buildTextField(_projectNameController, 'Project Name*'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _organisationNameController,
                    'Organisation Name*',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description*',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // App Icon
            _buildSectionCard(
              title: 'App Icon (Optional)',
              icon: Icons.image_outlined,
              child: Center(
                child: GestureDetector(
                  onTap: _pickAppIcon,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image:
                          _appIcon != null
                              ? DecorationImage(
                                image: FileImage(_appIcon!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _appIcon == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: Colors.blueGrey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pick Icon',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueGrey[400],
                                  ),
                                ),
                              ],
                            )
                            : null,
                  ),
                ),
              ),
            ),

            // Firebase Setup
            _buildSectionCard(
              title: 'Firebase Setup',
              icon: FontAwesomeIcons.fire,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Require Firebase Integration',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                    value: _requireFirebase,
                    onChanged:
                        (bool value) =>
                            setState(() => _requireFirebase = value),
                    activeColor: Colors.blue,
                    secondary: FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.grey[50],
                  ),
                  if (_requireFirebase)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey[600],
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          side: BorderSide(color: Colors.grey[200]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _pickGoogleServicesJson,
                        icon: Icon(
                          Icons.upload_file_rounded,
                          size: 20,
                          color: Colors.blueGrey[400],
                        ),
                        label: Text(
                          _googleServicesJson?.path.split('/').last ??
                              'Upload google-services.json*',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Environment Variables
            _buildSectionCard(
              title: 'Environment Variables',
              icon: Icons.code_rounded,
              child: _buildDynamicFields(),
            ),

            // Android Permissions
            _buildSectionCard(
              title: 'Android Permissions',
              icon: Icons.shield_outlined,
              child: _buildDynamicPermissionFields(),
            ),

            // Submit Button
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _createProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text(
                  'Create Project',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title, icon: icon),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isOptional ? '$label (Optional)' : label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        labelStyle: TextStyle(color: Colors.blueGrey[400]),
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter the $label';
        }
        return null;
      },
    );
  }

  Widget _buildDynamicFields() {
    return Column(
      children: [
        ..._envControllers.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, TextEditingController> controllers = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controllers['key']!,
                    'Key',
                    isOptional: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controllers['value']!,
                    'Value',
                    isOptional: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent[200],
                  ),
                  onPressed: () => _removeEnvVariable(index),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addEnvVariable,
          icon: Icon(Icons.add, size: 18, color: Colors.blueGrey[600]),
          label: Text(
            'Add Variable',
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blueGrey[600],
            side: BorderSide(color: Colors.grey[200]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicPermissionFields() {
    return Column(
      children: [
        ..._permissionControllers.asMap().entries.map((entry) {
          int index = entry.key;
          TextEditingController controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller,
                    'e.g., android.permission.INTERNET',
                    isOptional: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent[200],
                  ),
                  onPressed: () => _removePermission(index),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addPermission,
          icon: Icon(Icons.add, size: 18, color: Colors.blueGrey[600]),
          label: Text(
            'Add Permission',
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blueGrey[600],
            side: BorderSide(color: Colors.grey[200]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
