import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';

class DynamicMiniGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StageAnimationController>(
      () => StageAnimationController(),
      fenix: true,
    );
    Get.lazyPut<StageAudioController>(
      () => StageAudioController(),
      fenix: true,
    );
    Get.lazyPut<DynamicMiniGameController>(
      () => DynamicMiniGameController(),
      fenix: true,
    );
  }
}
