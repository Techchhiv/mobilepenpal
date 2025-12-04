import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';

class StageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StageController>(() => StageController());
  }
}