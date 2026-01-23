import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';

class LevelBinding implements Bindings {
  @override
  void dependencies() {
    // Get.lazyPut<LevelController>(() => LevelController(), fenix: true);
    Get.lazyPut<StageController>(() => StageController(), fenix: true);
  }
}