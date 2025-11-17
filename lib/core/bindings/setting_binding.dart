import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/settings/setting_controller.dart';

class SettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingController>(() => SettingController());
  }
}