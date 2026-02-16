import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/stage_summary_controller.dart';

class StageSummaryBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut<StageController>(() => StageController());
    Get.lazyPut<StageSummaryController>(() => StageSummaryController());
    // Get.lazyPut<LevelController>(() => LevelController());
    // Get.lazyPut<WorldController>(() => WorldController());
  }
}
