import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_summary_controller.dart';

class AdventureSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdventureSummaryController>(() => AdventureSummaryController());
  }
}
