import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<HomeAnimationController>(() => HomeAnimationController());
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<WorldController>(() => WorldController());
  }
}
