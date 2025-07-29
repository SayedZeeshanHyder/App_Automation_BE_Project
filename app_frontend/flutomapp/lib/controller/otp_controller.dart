import 'package:flutomapp/screens/navigation_screen.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';

class OtpController extends GetxController {
  final String correctOtp;
  final String authToken;
  final String userId;

  OtpController(this.correctOtp, this.authToken, this.userId);

  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  RxString enteredOtp = ''.obs;
  RxBool isLoading = false.obs;
  RxBool isVerified = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    for (int i = 0; i < otpControllers.length; i++) {
      otpControllers[i].addListener(() {
        updateEnteredOtp();
      });
    }
  }

  void updateEnteredOtp() {
    String otp = '';
    for (var controller in otpControllers) {
      otp += controller.text;
    }
    enteredOtp.value = otp;

    // Clear error when user starts typing
    if (errorMessage.value.isNotEmpty) {
      errorMessage.value = '';
    }
  }

  void onFieldChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    }

    // Auto verify when all fields are filled
    if (enteredOtp.value.length == 6) {
      Future.delayed(const Duration(milliseconds: 500), () {
        verifyOtp();
      });
    }
  }

  void onFieldBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> verifyOtp() async {
    if (enteredOtp.value.length != 6) {
      errorMessage.value = 'Please enter complete OTP';
      return;
    }

    isLoading.value = true;
    if (enteredOtp.value == correctOtp) {
      isVerified.value = true;
      errorMessage.value = '';
      SharedPreferencesService.storeAuthInfo({
        "token": authToken,
        "userId": userId,
      });
      Get.offAll(()=>NavigationScreen(),transition: Transition.rightToLeft);
    } else {
      errorMessage.value = 'Invalid OTP. Please try again.';
      // Clear all fields
      for (var controller in otpControllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
    }

    isLoading.value = false;
  }

  void resendOtp() {
    // Clear all fields and reset state
    for (var controller in otpControllers) {
      controller.clear();
    }
    enteredOtp.value = '';
    errorMessage.value = '';
    isVerified.value = false;
    focusNodes[0].requestFocus();

    Get.snackbar(
      'OTP Sent',
      'A new OTP has been sent to your device',
      backgroundColor: AppColors.lightGreen,
      colorText: AppColors.whiteText,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  void onClose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.onClose();
  }
}

