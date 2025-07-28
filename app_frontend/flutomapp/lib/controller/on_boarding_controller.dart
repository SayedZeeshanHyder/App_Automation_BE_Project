import 'package:flutomapp/screens/auth_screens/first_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;

  RxInt currentSection = 0.obs;
  RxDouble progress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    ));

    scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    ));

    animationController.forward();
    updateProgress();
  }

  void nextSection() {
    if (currentSection.value < 2) {
      currentSection.value++;
      updateProgress();
      animationController.reset();
      animationController.forward();
    }
  }

  void updateProgress() {
    progress.value = (currentSection.value + 1) / 3;
  }

  void navigateToLogin() {
    Get.offAll(()=>FirstSignUpScreen(),transition: Transition.rightToLeft,);
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}