import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';

class LevelBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LevelController>(() => LevelController());
  }
}