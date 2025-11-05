import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/otp_controller.dart';

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtpController>(() => OtpController());
  }
}