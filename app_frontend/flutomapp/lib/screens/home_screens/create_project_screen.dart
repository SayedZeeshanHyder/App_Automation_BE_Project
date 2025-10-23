import 'dart:io';
import 'dart:ui';

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

  // Professional Glassmorphism color scheme
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _accentColor = Color(0xFF6C5DD3);
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _primaryTextColor = Color(0xFF0F1419);
  static const Color _secondaryTextColor = Color(0xFF536471);
  static const Color _glassBackground = Color(0xFFFEFEFF);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _glassBorder = Color(0xFFE1E7F0);

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

  void _showGlassSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      _showGlassSnackBar('Please fix the errors in the form.', isError: true);
      return;
    }

    if (_requireFirebase && _googleServicesJson == null) {
      _showGlassSnackBar(
        'Please upload google-services.json as Firebase is required.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = '🚀 Preparing your project...';
    });

    String token = SharedPreferencesService.getToken();

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
        _loadingMessage = '⚙️ Building and configuring... This may take a moment.';
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showGlassSnackBar('✅ Project created successfully!', isError: false);
        Navigator.pop(context);
      } else {
        _showGlassSnackBar(
          'Error: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      _showGlassSnackBar('An error occurred', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _buildGlassAppBar(),
      ),
      body: Stack(
        children: [
          // Background glassmorphism circles
          _buildBackgroundCircles(),

          // Main content
          _isLoading ? _buildLoadingScreen() : _buildForm(),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircles() {
    return Stack(
      children: [
        // Large top-right circle
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.05),
              border: Border.all(
                color: _primaryColor.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
        ),

        // Medium left circle
        Positioned(
          top: 300,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withOpacity(0.04),
              border: Border.all(
                color: _accentColor.withOpacity(0.08),
                width: 2,
              ),
            ),
          ),
        ),

        // Small top-right floating circle
        Positioned(
          top: 180,
          right: 50,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.03),
              border: Border.all(
                color: _primaryColor.withOpacity(0.06),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Bottom-right large circle
        Positioned(
          bottom: -120,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withOpacity(0.05),
              border: Border.all(
                color: _accentColor.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
        ),

        // Small center-left circle
        Positioned(
          top: 500,
          left: 30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.04),
              border: Border.all(
                color: _primaryColor.withOpacity(0.08),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Tiny accent circle
        Positioned(
          bottom: 250,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withOpacity(0.03),
              border: Border.all(
                color: _accentColor.withOpacity(0.06),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: _glassBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _buildGlassBackButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Project',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _glassBorder.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryTextColor.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _primaryTextColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _glassBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _glassBorder.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryTextColor.withOpacity(0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  _loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          // Project Details Section
          _buildGlassSectionCard(
            title: 'Project Details',
            icon: Icons.folder_rounded,
            child: Column(
              children: [
                _buildGlassTextField(
                  controller: _projectNameController,
                  label: 'Project Name',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 16),
                _buildGlassTextField(
                  controller: _organisationNameController,
                  label: 'Organisation Name',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),
                _buildGlassTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description_outlined,
                  isOptional: true,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          // App Icon Section
          _buildGlassSectionCard(
            title: 'App Icon',
            icon: Icons.image_outlined,
            child: _buildAppIconPicker(),
          ),

          // Firebase Configuration
          _buildGlassSectionCard(
            title: 'Firebase Configuration',
            icon: FontAwesomeIcons.fire,
            child: Column(
              children: [
                _buildGlassSwitch(),
                if (_requireFirebase) ...[
                  const SizedBox(height: 16),
                  _buildGoogleServicesButton(),
                ],
              ],
            ),
          ),

          // Environment Variables
          _buildGlassSectionCard(
            title: 'Environment Variables',
            icon: Icons.code_rounded,
            child: _buildDynamicFields(),
          ),

          // Android Permissions
          _buildGlassSectionCard(
            title: 'Android Permissions',
            icon: Icons.shield_outlined,
            child: _buildDynamicPermissionFields(),
          ),

          // Submit Button
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildGlassSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: _glassBackground.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _glassBorder.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryTextColor.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(title, icon: icon),
                  const SizedBox(height: 16),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isOptional = false,
    int maxLines = 1,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _glassBorder.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: isOptional ? '$label (Optional)' : label,
              prefixIcon: Icon(icon, color: _secondaryTextColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              labelStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            validator: (value) {
              if (!isOptional && (value == null || value.isEmpty)) {
                return 'Please enter the $label';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppIconPicker() {
    return GestureDetector(
      onTap: _pickAppIcon,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _glassBorder.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                if (_appIcon != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _appIcon!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: _primaryColor.withOpacity(0.6),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  _appIcon != null ? 'Tap to change icon' : 'Tap to upload icon',
                  style: TextStyle(
                    color: _secondaryTextColor.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSwitch() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _glassBorder.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Require Firebase',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enable Firebase services',
                      style: TextStyle(
                        color: _secondaryTextColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _requireFirebase,
                onChanged: (value) {
                  setState(() {
                    _requireFirebase = value;
                  });
                },
                activeColor: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleServicesButton() {
    return GestureDetector(
      onTap: _pickGoogleServicesJson,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _glassBorder.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.upload_file_rounded,
                    size: 20,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _googleServicesJson?.path.split('/').last ?? 'Upload google-services.json *',
                    style: TextStyle(
                      fontSize: 14,
                      color: _googleServicesJson != null
                          ? _successColor
                          : _secondaryTextColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_googleServicesJson != null)
                  Icon(
                    Icons.check_circle,
                    color: _successColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _glassBorder.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSmallTextField(controllers['key']!, 'Key'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSmallTextField(controllers['value']!, 'Value'),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeEnvVariable(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: _errorColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildAddButton('Add Variable', _addEnvVariable),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _glassBorder.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSmallTextField(
                          controller,
                          'e.g., android.permission.INTERNET',
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removePermission(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: _errorColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildAddButton('Add Permission', _addPermission),
      ],
    );
  }

  Widget _buildSmallTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: _primaryTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _secondaryTextColor.withOpacity(0.6),
          fontSize: 13,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: _primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _primaryColor.withOpacity(0.15),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _createProject,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Create Project',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}