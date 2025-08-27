import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutomapp/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../constants/api_constants.dart';
import '../../services/shared_preferences_service.dart';

class CreateOrganisationScreen extends StatefulWidget {
  const CreateOrganisationScreen({super.key});

  @override
  State<CreateOrganisationScreen> createState() => _CreateOrganisationScreenState();
}

class _CreateOrganisationScreenState extends State<CreateOrganisationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  XFile? _logoFile;
  final ImagePicker _picker = ImagePicker();

  // Define a professional color scheme
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _fieldBorderColor = Color(0xFFD0D5DD);
  static const Color _errorColor = Color(0xFFD92D20);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _logoFile = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar("Error picking image: ${e.toString()}", isError: true);
    }
  }

  Future<void> _createOrganisation() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String token = SharedPreferencesService.getToken();

      final Uri url = Uri.parse(ApiConstants.baseUrl + ApiConstants.createOrganisationApi);
      final organisationData = {
        "organisationName": _nameController.text,
        "organisationLogo": "", // Passing empty string as requested
        "organisationDescription": _descriptionController.text,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(organisationData),
      ).timeout(const Duration(seconds: 15));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Organisation created successfully!");
        Get.offAll(()=>NavigationScreen(),transition: Transition.downToUp);
      } else {
        final errorMessage = responseBody['message'] ?? 'Failed to create organisation.';
        _showSnackBar(errorMessage, isError: true);
      }
    } on SocketException {
      _showSnackBar("No Internet connection.", isError: true);
    } on TimeoutException {
      _showSnackBar("The request timed out. Please try again.", isError: true);
    } catch (e) {
      _showSnackBar("An unexpected error occurred: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorColor : Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text('Create Organisation', style: TextStyle(color: _primaryTextColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildLogoPicker(),
                  const SizedBox(height: 24),
                  _buildOrganisationNameField(),
                  const SizedBox(height: 20),
                  _buildDescriptionField(),
                  const SizedBox(height: 30),
                  _buildCreateButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Tell us about your organisation',
      style: TextStyle(
        color: _secondaryTextColor,
        fontSize: 16,
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _fieldBorderColor, width: 1.5),
                image: _logoFile != null
                    ? DecorationImage(
                  image: FileImage(File(_logoFile!.path)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _logoFile == null
                  ? const Center(
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: _secondaryTextColor,
                  size: 32,
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add Organisation Logo',
            style: TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrganisationNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: _inputDecoration(
        labelText: 'Organisation Name',
        hintText: 'e.g., Flutom Technologies',
        prefixIcon: Icons.business_center_outlined,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an organisation name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: _inputDecoration(
        labelText: 'Description',
        hintText: 'What does your organisation do?',
        prefixIcon: Icons.description_outlined,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createOrganisation,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        )
            : const Text(
          'Create Organisation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: _secondaryTextColor),
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: _fieldBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: _fieldBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: _primaryColor, width: 2.0),
      ),
      labelStyle: const TextStyle(color: _secondaryTextColor),
      floatingLabelStyle: const TextStyle(color: _primaryColor),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
