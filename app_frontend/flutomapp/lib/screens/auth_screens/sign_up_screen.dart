import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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
  bool _isLoading = false;
  String? _selectedRole;

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
      _showGlassSnackBar("Please fix the errors in the form.", isError: true);
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
        _showGlassSnackBar("Account created successfully!");
        Get.to(
              () => OtpVerificationScreen(
            email: _emailController.text,
            role: _selectedRole ?? "User",
          ),
          transition: Transition.rightToLeft,
        );
      } else {
        final errorMessage =
            responseBody['message'] ?? 'An unknown error occurred.';
        _showGlassSnackBar(errorMessage, isError: true);
      }
    } on SocketException {
      _showGlassSnackBar(
        "No Internet connection. Please check your network.",
        isError: true,
      );
    } on http.ClientException {
      _showGlassSnackBar(
        "Could not connect to the server. Please try again later.",
        isError: true,
      );
    } on FormatException {
      _showGlassSnackBar("Invalid response from the server.", isError: true);
    } catch (e) {
      _showGlassSnackBar(
        "An unexpected error occurred",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showGlassSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Background glassmorphism circles
          _buildBackgroundCircles(),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildGlassCard(),
                            const SizedBox(height: 24),
                            _buildLoginPrompt(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(200),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.08),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Medium left circle
        Positioned(
          top: 200,
          left: -80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(150),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withOpacity(0.06),
                  border: Border.all(
                    color: _accentColor.withOpacity(0.12),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Small top-left circle
        Positioned(
          top: 100,
          left: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.05),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom-right large circle
        Positioned(
          bottom: -120,
          right: -80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(250),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withOpacity(0.07),
                  border: Border.all(
                    color: _accentColor.withOpacity(0.14),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Small bottom-left circle
        Positioned(
          bottom: 150,
          left: 30,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 70,
                height: 70,
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
          ),
        ),

        // Tiny accent circle
        Positioned(
          top: 350,
          right: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withOpacity(0.05),
                  border: Border.all(
                    color: _accentColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Medium center-right circle
        Positioned(
          top: 450,
          right: -60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(120),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.06),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.12),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Icon with glass effect
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _glassBackground.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _glassBorder.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryTextColor.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/app_icon.png',
                height: 36,
                width: 36,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.flutter_dash,
                    size: 36,
                    color: _primaryColor,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Create Account',
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start your journey with us today',
          style: TextStyle(
            color: _secondaryTextColor.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
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
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.6),
                blurRadius: 2,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                _buildGlassTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'john_doe2',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildGlassTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'john.doe@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildGlassPasswordField(),
                const SizedBox(height: 20),
                _buildGlassDropdown(),
                const SizedBox(height: 28),
                _buildSignUpButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _glassBorder.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, color: _secondaryTextColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              labelStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.5),
                fontSize: 14,
              ),
              floatingLabelStyle: const TextStyle(
                color: _primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              errorStyle: TextStyle(
                color: _errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPasswordField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _glassBorder.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: _secondaryTextColor,
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _secondaryTextColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              labelStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.5),
                fontSize: 14,
              ),
              floatingLabelStyle: const TextStyle(
                color: _primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              errorStyle: TextStyle(
                color: _errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _glassBorder.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Role',
              hintText: 'Select your role',
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: _secondaryTextColor,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              labelStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: _secondaryTextColor.withOpacity(0.5),
                fontSize: 14,
              ),
              floatingLabelStyle: const TextStyle(
                color: _primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              errorStyle: TextStyle(
                color: _errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            dropdownColor: _glassBackground,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: _secondaryTextColor,
              size: 28,
            ),
            items: ['User', 'Owner'].map((String role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(
                  role,
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedRole = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select a role' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
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
              onTap: _isLoading ? null : _signUp,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: _isLoading
                    ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
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

  Widget _buildLoginPrompt() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
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
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account?",
                style: TextStyle(
                  color: _secondaryTextColor.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.off(
                        () => LoginScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}