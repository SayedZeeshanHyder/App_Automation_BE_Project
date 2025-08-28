import 'package:get/get.dart';
import '../controller/dynamic_render_prompt_controller.dart';

class DynamicRenderingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DynamicScreenController>(() => DynamicScreenController());
  }
}