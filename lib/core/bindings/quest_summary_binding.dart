import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_summary_controller.dart';

class QuestSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuestSummaryController>(() => QuestSummaryController());
  }
}
