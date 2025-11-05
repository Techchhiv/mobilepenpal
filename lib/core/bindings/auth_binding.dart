import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<AuthController>(() => AuthController());
  }
}