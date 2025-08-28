import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/gemini_prompts.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import '../screens/rendering_screens/hit_gemini_api.dart';

/// Defines the purpose of the DynamicRenderingScreen to control UI and logic.
enum ScreenMode { view, update, create }

class DynamicScreenController extends GetxController {
  // STATE
  var fabPosition = const Offset(20, 100).obs;
  var isSaving = false.obs;
  var isUpdateEnabled = false.obs;
  var isUpdating = false.obs;
  var widgetData = <String, dynamic>{}.obs;

  // CONTEXT
  var mode = ScreenMode.view.obs;
  Project? project;
  ProjectScreen? screen;
  String? initialPrompt;
  String? screenName;

  late TextEditingController promptController;

  @override
  void onInit() {
    super.onInit();

    // Initialize state from arguments passed during navigation.
    // This happens only ONCE when the controller is created for a route.
    if (Get.arguments != null) {
      final args = Get.arguments as Map<String, dynamic>;
      widgetData.value = args['widgetData'] ?? {};
      mode.value = args['mode'] ?? ScreenMode.view;
      project = args['project'];
      screen = args['screen'];
      initialPrompt = args['initialPrompt'];
      screenName = args['screenName'];
    }

    promptController = TextEditingController();
    promptController.addListener(() {
      isUpdateEnabled.value = promptController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }

  Future<void> handleUpdate() async {
    if (promptController.text.trim().isEmpty) return;
    isUpdating.value = true;
    try {
      final updateInstruction = promptController.text.trim();
      final updatePrompt = GeminiPrompts.generateGeminiUpdatePrompt(updateInstruction, widgetData.value);
      final newWidgetData = await HitGeminiAPI.hitGeminiAPI(updatePrompt);
      widgetData.value = newWidgetData; // This update will now persist
      Get.back();
      Get.snackbar('Success', 'UI Updated!', backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update UI: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
      promptController.clear();
    }
  }

  Future<void> handleSave() async {
    isSaving.value = true;
    try {
      if (mode.value == ScreenMode.create) {
        final screenData = {
          "screenName": screenName ?? "Untitled Screen",
          "screenPrompt": initialPrompt ?? "N/A",
          "screenUI": widgetData.value,
          "screenCode": "// Generated Dart code will be here",
        };
        await ApiService.createScreen(projectId: project!.id, screenData: screenData);
      } else if (mode.value == ScreenMode.update) {
        final screenData = {
          "screenName": "Updated ${screen!.screenName}",
          "screenPrompt": screen!.screenPrompt,
          "screenUI": widgetData.value,
          "screenCode": "// Updated Dart code will be here",
        };
        await ApiService.updateScreen(
          projectId: project!.id,
          screenId: screen!.screenId,
          screenData: screenData,
        );
      }
      Get.snackbar('Success', 'Screen saved successfully!', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save screen: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  void updateFabPosition(DragUpdateDetails details, Size screenSize) {
    const double fabSize = 56.0;
    double newX = fabPosition.value.dx + details.delta.dx;
    double newY = fabPosition.value.dy + details.delta.dy;

    newX = newX.clamp(0, screenSize.width - fabSize);
    newY = newY.clamp(0, screenSize.height - fabSize - Get.mediaQuery.padding.top);

    fabPosition.value = Offset(newX, newY);
  }

  void showEditBottomSheet() {
    Get.bottomSheet(
      _buildBottomSheetContent(),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    );
  }

  Widget _buildBottomSheetContent() {
    return Padding(
      padding: EdgeInsets.only(
          bottom: Get.mediaQuery.viewInsets.bottom + Get.mediaQuery.padding.bottom,
          left: 20, right: 20, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Screen', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Get.back()),
            ],
          ),
          const Divider(height: 24),
          TextField(controller: promptController, decoration: InputDecoration(labelText: 'Enter new prompt to update UI', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Get.back(), child: const Text('Discard')),
              const SizedBox(width: 8),
              Obx(() => ElevatedButton(
                onPressed: isUpdateEnabled.value && !isUpdating.value ? handleUpdate : null,
                child: isUpdating.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update'),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  handleSave();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Save Screen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}