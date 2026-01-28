import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutomapp/screens/auth_screens/sign_up_screen.dart';
import 'package:flutomapp/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';
import '../../services/shared_preferences_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  // Define a professional color scheme
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _fieldBorderColor = Color(0xFFD0D5DD);
  static const Color _errorColor = Color(0xFFD92D20);

  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Uri url = Uri.parse(ApiConstants.baseUrl + ApiConstants.loginApi);
      final loginData = {
        "userName": _usernameController.text,
        "password": _passwordController.text,
      };

      print("Hitting Post api $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(loginData),
      ).timeout(const Duration(seconds: 15));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Store auth info
        await SharedPreferencesService.storeAuthInfo({
          "userId": responseBody['user']?['id'],
          "token": responseBody['token'],
        });

        Get.offAll(()=>NavigationScreen(),transition: Transition.rightToLeft,);
        _showSnackBar("Login Successful!", isError: false);
      } else {
        final errorMessage = responseBody['message'] ?? 'Invalid username or password.';
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

  void _showSnackBar(String message, {required bool isError}) {
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
                  SizedBox(height: screenHeight * 0.08),
                  _buildHeader(),
                  SizedBox(height: screenHeight * 0.05),
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  SizedBox(height: screenHeight * 0.04),
                  _buildSignUpPrompt(),
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
        Image.asset(
          'assets/app_icon.png',
          height: 50,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.flutter_dash, size: 50, color: _primaryColor);
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back!',
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Log in to continue your work.',
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: _inputDecoration(
        labelText: 'Username',
        hintText: 'Enter your username',
        prefixIcon: Icons.person_outline_rounded,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
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
            _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
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
          'Log In',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: _secondaryTextColor, fontSize: 15),
        ),
        TextButton(
          onPressed: () {
            Get.off(()=>SignUpScreen(),transition: Transition.leftToRight,);
          },
          child: const Text(
            'Sign Up',
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
