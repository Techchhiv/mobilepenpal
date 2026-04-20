import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';

class AdventureStageBinding extends Bindings {
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
    Get.lazyPut<AdventureStageController>(
      () => AdventureStageController(),
      fenix: true,
    );
  }
}
