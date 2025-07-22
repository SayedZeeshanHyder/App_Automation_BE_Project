import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/encryption_service.dart';
import '../services/file_service.dart';

class StatusItem {
  final String title;
  final String? subtitle;
  final IconData icon;

  StatusItem({
    required this.title,
    this.subtitle,
    required this.icon,
  });
}

class ProjectCreationController extends GetxController {
  final RxString currentStatus = 'Ready to start'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isCompleted = false.obs;
  final RxInt currentStatusIndex = (-1).obs;

  final List<StatusItem> statusList = [
    StatusItem(
      title: 'Initializing Setup',
      subtitle: 'Preparing project creation environment',
      icon: Icons.settings_outlined,
    ),
    StatusItem(
      title: 'Creating Flutter Project',
      subtitle: 'Generating project structure and dependencies',
      icon: Icons.code_outlined,
    ),
    StatusItem(
      title: 'Encrypting Project',
      subtitle: 'Securing your project with encryption',
      icon: Icons.lock_outlined,
    ),
    StatusItem(
      title: 'Saving to Device',
      subtitle: 'Storing encrypted project locally',
      icon: Icons.save_outlined,
    ),
    StatusItem(
      title: 'Finalizing Process',
      subtitle: 'Completing setup and cleanup',
      icon: Icons.check_circle_outlined,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    currentStatus.value = statusList.first.title;
  }

  Future<void> createProject({
    required String projectName,
    required String organization,
    required String description,
  }) async {
    try {
      isLoading.value = true;
      isCompleted.value = false;
      currentStatusIndex.value = 0;

      await _updateStatus(0, "Initializing Setup");
      await Future.delayed(const Duration(seconds: 2));

      await _updateStatus(1, "Creating Flutter Project");
      final zipData = await ApiService.createFlutterProject(
        projectName: projectName,
        organization: organization,
        description: description,
      );

      if (zipData == null) {
        throw Exception('Failed to create project - API returned null');
      }

      await _updateStatus(2, "Encrypting Project");
      await Future.delayed(const Duration(milliseconds: 800));
      final encryptedData = EncryptionService.encryptZipFile(zipData);

      await _updateStatus(3, "Saving to Device");
      await Future.delayed(const Duration(milliseconds: 800));
      await FileService.saveZhspFile(projectName, encryptedData);

      await _updateStatus(4, "Finalizing Process");
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

      isCompleted.value = true;

      await Future.delayed(const Duration(milliseconds: 800));

      Get.back();

      Get.snackbar(
        'Success',
        'Your Flutter project has been created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 24,
        ),
        duration: const Duration(seconds: 3),
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        _getErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(
          Icons.error_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
        duration: const Duration(seconds: 4),
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
      );
    } finally {
      isLoading.value = false;
      currentStatusIndex.value = -1;
    }
  }

  Future<void> _updateStatus(int index, String status) async {
    currentStatusIndex.value = index;
    currentStatus.value = status;

    await Future.delayed(const Duration(milliseconds: 300));
  }

  String _getErrorMessage(String error) {
    if (error.contains('Failed to create project')) {
      return 'Unable to generate project files';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Check your internet connection';
    } else if (error.contains('permission')) {
      return 'Storage permission required';
    } else if (error.contains('space')) {
      return 'Insufficient storage space';
    } else {
      return 'Please try again later';
    }
  }

  void resetState() {
    isLoading.value = false;
    isCompleted.value = false;
    currentStatusIndex.value = -1;
    currentStatus.value = 'Ready to start';
  }

  @override
  void onClose() {
    resetState();
    super.onClose();
  }
}
