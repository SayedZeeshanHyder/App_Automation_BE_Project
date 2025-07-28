import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../models/sign_up_data.dart';
import '../screens/auth_screens/second_signup_screen.dart';

class SignUpController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();

  var selectedRole = 'Developer'.obs;
  var isPasswordVisible = false.obs;
  var signUpData = SignUpData().obs;

  final roles = ['Developer', 'Owner', 'Contributor'];

  RxBool hasMinLength = false.obs;
  RxBool hasUppercase = false.obs;
  RxBool hasLowercase = false.obs;
  RxBool hasDigit = false.obs;
  RxBool hasSpecialChar = false.obs;

  void validatePassword(String password) {
    hasMinLength.value = password.length >= 6;
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    hasDigit.value = password.contains(RegExp(r'[0-9]'));
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  bool get isPasswordValid =>
      hasMinLength.value &&
          hasUppercase.value &&
          hasLowercase.value &&
          hasDigit.value &&
          hasSpecialChar.value;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void updateSignUpData() {
    signUpData.value = SignUpData(
      userName: userNameController.text,
      password: passwordController.text,
      email: emailController.text,
      role: selectedRole.value,
    );
  }

  void proceedToNextScreen() {
    if (formKey.currentState!.validate() && isPasswordValid) {
      updateSignUpData();
      Get.to(() => SecondSignUpScreen(), transition: Transition.rightToLeft);
    }
  }

  @override
  void onClose() {
    userNameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    super.onClose();
  }
}