import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';

class StageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StageController>(() => StageController());
    Get.lazyPut<StageAnimationController>(() => StageAnimationController());
    Get.lazyPut<WorldController>(() => WorldController());
  }
}