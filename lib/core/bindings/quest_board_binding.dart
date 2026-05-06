import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_board_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';

class QuestBoardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuestBoardController>(() => QuestBoardController());
    Get.lazyPut<StageAnimationController>(
      () => StageAnimationController(),
      fenix: true,
    );
    Get.lazyPut<StageAudioController>(
      () => StageAudioController(),
      fenix: true,
    );
  }
}
