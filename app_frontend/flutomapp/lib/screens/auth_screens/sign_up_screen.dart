import 'dart:convert';
import 'dart:io';

import 'package:flutomapp/screens/auth_screens/login_screen.dart';
import 'package:flutomapp/screens/auth_screens/otp_verification_screen.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isLoading = false; // To manage loading state
  String? _selectedRole;

  // Define a professional color scheme
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _fieldBorderColor = Color(0xFFD0D5DD);
  static const Color _errorColor = Color(0xFFD92D20);

  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fix the errors in the form.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Uri url = Uri.parse(
        ApiConstants.baseUrl + ApiConstants.registerApi,
      );

      final userData = {
        "userName": _usernameController.text,
        "password": _passwordController.text,
        "email": _emailController.text,
        "role": _selectedRole?.toUpperCase(),
        "createdAt": DateTime.now().toIso8601String(),
        "deviceToken": "",
      };

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode(userData),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Signup Successful!");
        await SharedPreferencesService.storeAuthInfo({
          "userId": responseBody['user']['id'],
          "token": responseBody['token'],
        });
        _showSnackBar("Account created successfully!");
        Get.to(
          () => OtpVerificationScreen(email: _emailController.text, role: _selectedRole ?? "User",),
          transition: Transition.rightToLeft,
        );
      } else {
        final errorMessage =
            responseBody['message'] ?? 'An unknown error occurred.';
        _showSnackBar(errorMessage, isError: true);
      }
    } on SocketException {
      _showSnackBar(
        "No Internet connection. Please check your network.",
        isError: true,
      );
    } on http.ClientException {
      _showSnackBar(
        "Could not connect to the server. Please try again later.",
        isError: true,
      );
    } on FormatException {
      _showSnackBar("Invalid response from the server.", isError: true);
    } catch (e) {
      _showSnackBar(
        "An unexpected error occurred: ${e.toString()}",
        isError: true,
      );
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  _buildHeader(),
                  SizedBox(height: screenHeight * 0.04),
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildRoleDropdown(),
                  SizedBox(height: screenHeight * 0.04),
                  _buildSignUpButton(),
                  SizedBox(height: screenHeight * 0.03),
                  _buildLoginPrompt(),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Icon
        Image.asset(
          'assets/app_icon.png',
          height: 50,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.flutter_dash,
              size: 50,
              color: _primaryColor,
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Start your journey with us today.',
          style: TextStyle(color: _secondaryTextColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: _inputDecoration(
        labelText: 'Username',
        hintText: 'john_doe2',
        prefixIcon: Icons.person_outline_rounded,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a username';
        }
        if (value.length < 3) {
          return 'Username must be at least 3 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration(
        labelText: 'Email',
        hintText: 'john.doe@example.com',
        prefixIcon: Icons.email_outlined,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email';
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _isPasswordObscured,
      decoration: _inputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _secondaryTextColor,
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: _inputDecoration(
        labelText: 'Role',
        prefixIcon: Icons.badge_outlined,
        hintText: 'Select your role',
      ),
      hint: const Text(
        'Select your role',
        style: TextStyle(color: _secondaryTextColor),
      ),
      items:
          ['User', 'Owner'].map((String role) {
            return DropdownMenuItem<String>(value: role, child: Text(role));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedRole = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a role' : null,
      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        color: _secondaryTextColor,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // Disable button when loading, otherwise call _signUp
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account?",
          style: TextStyle(color: _secondaryTextColor, fontSize: 15),
        ),
        TextButton(
          onPressed: () {
            Get.off(()=>LoginScreen(),transition: Transition.rightToLeft,);
          },
          child: const Text(
            'Log In',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
