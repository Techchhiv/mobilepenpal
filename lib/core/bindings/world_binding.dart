import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';

class WorldBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorldController>(() => WorldController());
    Get.lazyPut<LevelController>(() => LevelController());
  }
}