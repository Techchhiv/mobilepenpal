import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
