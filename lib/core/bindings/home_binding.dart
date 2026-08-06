import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/dashboard/navigation_controller.dart';
import 'package:mobilepenpal/data/controllers/mini_game/mini_game_hub_controller.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    // M-06: Clamp to valid tab range [0..3] to prevent out-of-bounds crashes
    // from crafted deep-link arguments.
    final rawIndex = args is Map ? (args['initialTabIndex'] as int? ?? 0) : 0;
    final initialTabIndex = rawIndex.clamp(0, 3);

    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<NavigationController>(
      () => NavigationController(initialIndex: initialTabIndex),
      fenix: true,
    );
    Get.lazyPut<QuestController>(() => QuestController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<HomeAnimationController>(
      () => HomeAnimationController(),
      fenix: true,
    );
    Get.lazyPut<ShopController>(() => ShopController(), fenix: true);
    Get.lazyPut<MiniGameHubController>(
      () => MiniGameHubController(),
      fenix: true,
    );
  }
}
