import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dynamic_render_prompt_controller.dart';
import 'widget_rendering.dart';

class DynamicRenderingScreen extends GetView<DynamicScreenController> {
  // The constructor is now very simple and doesn't hold state.
  const DynamicRenderingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Binding has already created the controller for this route.
    // GetView automatically finds the correct controller instance for us.
    final Size screenSize = MediaQuery.of(context).size;

    // Initialization is now handled by the controller's onInit method.
    // The build method is clean and no longer accesses Get.arguments.

    return Scaffold(
      body: Stack(
        children: [
          // This Obx block will now correctly and permanently react to data changes
          Obx(() => controller.widgetData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : WidgetRendering.buildWidget(controller.widgetData.value)),

          // This Obx block now correctly shows/hides the FAB based on the mode
          Obx(() => controller.mode.value == ScreenMode.view
              ? const SizedBox.shrink()
              : Positioned(
            top: controller.fabPosition.value.dy,
            left: controller.fabPosition.value.dx,
            child: GestureDetector(
              onPanUpdate: (details) => controller.updateFabPosition(details, screenSize),
              child: FloatingActionButton(
                onPressed: controller.showEditBottomSheet,
                tooltip: 'Edit Screen',
                child: const Icon(Icons.edit_outlined),
              ),
            ),
          )),

          // This Obx block handles the saving overlay
          Obx(() => controller.isSaving.value
              ? Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}