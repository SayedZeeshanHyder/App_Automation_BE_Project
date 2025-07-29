import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../controller/otp_controller.dart';

class OtpVerificationScreen extends StatelessWidget {
  final String verificationCode;
  final String authToken;
  final String userId;

  const OtpVerificationScreen({
    Key? key,
    required this.verificationCode, required this.authToken, required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OtpController controller = Get.put(OtpController(verificationCode, authToken, userId));
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06, // 6% of screen width
                ),
                child: Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 20 : 40),

                    // Header Section
                    _buildHeader(context),

                    SizedBox(height: isSmallScreen ? 30 : 60),

                    // OTP Input Section
                    _buildOtpInputSection(controller, context),

                    SizedBox(height: isSmallScreen ? 25 : 40),

                    // Verify Button
                    _buildVerifyButton(controller, context),

                    SizedBox(height: isSmallScreen ? 20 : 30),

                    // Resend Section
                    _buildResendSection(controller, context),

                    const Spacer(),

                    // Footer
                    _buildFooter(context),

                    SizedBox(height: isSmallScreen ? 15 : 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Column(
      children: [
        // Logo/Icon
        Container(
          width: isSmallScreen ? 60 : 80,
          height: isSmallScreen ? 60 : 80,
          decoration: BoxDecoration(
            gradient: AppColors.logoLinearGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.security,
            color: AppColors.whiteText,
            size: isSmallScreen ? 30 : 40,
          ),
        ),

        SizedBox(height: isSmallScreen ? 16 : 24),

        // Title
        Text(
          'Verify Your Identity',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),

        SizedBox(height: isSmallScreen ? 8 : 12),

        // Subtitle
        Text(
          'Enter the 6-digit verification code\nsent to your registered device',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppColors.secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputSection(OtpController controller, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final fieldWidth = isSmallScreen ? 45.0 : 55.0;
    final fieldHeight = isSmallScreen ? 50.0 : 60.0;
    final fontSize = isSmallScreen ? 20.0 : 24.0;

    return Column(
      children: [
        // OTP Input Fields
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6),
                child: SizedBox(
                  width: fieldWidth,
                  height: fieldHeight,
                  child: Obx(() => TextFormField(
                    controller: controller.otpControllers[index],
                    focusNode: controller.focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: controller.isVerified.value
                          ? AppColors.primaryGreenOpacity10
                          : AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: controller.errorMessage.value.isNotEmpty
                              ? Colors.red.withOpacity(0.5)
                              : controller.isVerified.value
                              ? AppColors.primaryGreen
                              : AppColors.borderColor,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: controller.errorMessage.value.isNotEmpty
                              ? Colors.red.withOpacity(0.5)
                              : controller.isVerified.value
                              ? AppColors.primaryGreen
                              : AppColors.borderColor,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.red.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      controller.onFieldChanged(value, index);
                    },
                    onTap: () {
                      if (controller.otpControllers[index].text.isNotEmpty) {
                        controller.otpControllers[index].selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.otpControllers[index].text.length),
                        );
                      }
                    },
                  )),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 20),

        // Error Message
        Obx(() => controller.errorMessage.value.isNotEmpty
            ? Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  controller.errorMessage.value,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildVerifyButton(OtpController controller, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      child: ElevatedButton(
        onPressed: controller.isLoading.value
            ? null
            : () => controller.verifyOtp(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          elevation: 0,
          shadowColor: AppColors.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: controller.isLoading.value
            ? SizedBox(
          width: isSmallScreen ? 20 : 24,
          height: isSmallScreen ? 20 : 24,
          child: const CircularProgressIndicator(
            color: AppColors.whiteText,
            strokeWidth: 2,
          ),
        )
            : controller.isVerified.value
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: isSmallScreen ? 20 : 24),
            const SizedBox(width: 8),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ));
  }

  Widget _buildResendSection(OtpController controller, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => controller.resendOtp(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Resend OTP',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenOpacity05,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.primaryGreen,
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your information is protected with end-to-end encryption',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: isSmallScreen ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
