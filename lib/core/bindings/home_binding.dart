import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/home/navigation_controller.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_controller.dart';
import 'package:mobilepenpal/data/controllers/daily_challenge/daily_challenge_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
    Get.lazyPut<AdventureController>(() => AdventureController(), fenix: true);
    Get.lazyPut<DailyChallengeController>(
      () => DailyChallengeController(),
      fenix: true,
    );
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<HomeAnimationController>(
      () => HomeAnimationController(),
      fenix: true,
    );
    Get.lazyPut<ShopController>(() => ShopController(), fenix: true);
  }
}
