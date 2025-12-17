import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/report/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportController>(() => ReportController());
  }
}