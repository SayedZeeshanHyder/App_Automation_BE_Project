import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BuildConfirmationDialog extends StatefulWidget {
  final List<String> screens;
  final Function onConfirmed;

  const BuildConfirmationDialog({
    super.key,
    required this.screens,
    required this.onConfirmed,
  });

  @override
  State<BuildConfirmationDialog> createState() =>
      _BuildConfirmationDialogState();
}

class _BuildConfirmationDialogState extends State<BuildConfirmationDialog> {
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _primaryTextColor = Color(0xFF0F1419);
  static const Color _secondaryTextColor = Color(0xFF536471);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _backgroundColor = Color(0xFFFAFAFC);
  static const Color _borderColor = Color(0xFFE4E6EF);

  int _countdown = 10;
  Timer? _timer;
  bool _isAuthenticating = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final TextEditingController _instructionsController = TextEditingController();
  int _selectedScreenIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_countdown > 0) return;

    setState(() => _isAuthenticating = true);

    try {
      final bool canAuthenticateWithBiometrics =
      await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          _showErrorSnackbar('Biometric authentication is not available');
          setState(() => _isAuthenticating = false);
        }
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to build the project',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        setState(() => _isAuthenticating = false);

        if (didAuthenticate) {
          Navigator.of(context).pop();
          widget.onConfirmed(
            _instructionsController.text.trim(),
            _selectedScreenIndex,
          );
        } else {
          _showErrorSnackbar('Authentication failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuthenticating = false);
        _showErrorSnackbar('Authentication error: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryTextColor.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.build_rounded,
                        color: _primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build Project',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _primaryTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure and confirm your build',
                          style: TextStyle(
                            fontSize: 13,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 24),

              // Instructions field
              _fieldLabel('Instructions', optional: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  color: _primaryTextColor,
                ),
                decoration: _inputDecoration(
                  hint: 'e.g. Create a Notes App with dark mode support…',
                  icon: Icons.edit_note_rounded,
                ),
              ),

              const SizedBox(height: 20),

              // Initial Screen selector
              _fieldLabel('Initial Screen'),
              const SizedBox(height: 8),
              _screenDropdown(),

              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 24),

              // Countdown
              if (_countdown > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_rounded,
                            color: _primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Please wait $_countdown second${_countdown != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_countdown > 0) const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isAuthenticating
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _backgroundColor,
                        foregroundColor: _secondaryTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _countdown == 0 && !_isAuthenticating
                          ? _handleConfirm
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        _secondaryTextColor.withOpacity(0.3),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAuthenticating
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Confirm & Build',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool optional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryTextColor,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _borderColor),
            ),
            child: const Text(
              'optional',
              style: TextStyle(fontSize: 11, color: _secondaryTextColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _screenDropdown() {
    if (widget.screens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: _secondaryTextColor),
            SizedBox(width: 8),
            Text(
              'No screens available',
              style: TextStyle(fontSize: 14, color: _secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedScreenIndex,
      decoration: _inputDecoration(
        hint: 'Select initial screen',
        icon: Icons.phone_android_rounded,
      ),
      style: const TextStyle(fontSize: 14, color: _primaryTextColor),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _secondaryTextColor),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      items: widget.screens.asMap().entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(
            entry.value,
            style: const TextStyle(fontSize: 14, color: _primaryTextColor),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedScreenIndex = value);
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _secondaryTextColor),
      prefixIcon: Icon(icon, size: 18, color: _secondaryTextColor),
      filled: true,
      fillColor: _backgroundColor,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    color: _borderColor,
  );
}