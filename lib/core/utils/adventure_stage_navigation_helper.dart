import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_controller.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/presentation/screens/adventure/adventure_stage_page.dart';

class AdventureStageNavigationHelper {
  static AdventureStage? findStageByIndex(
    AdventureController controller,
    int stageIndex,
  ) {
    for (final stage in controller.stages) {
      if (stage.index == stageIndex) return stage;
    }
    return null;
  }

  static Future<bool> openStage({
    required AdventureStage stage,
    required AdventureController adventureController,
    bool replaceCurrent = false,
  }) async {
    if (adventureController.isTransitioning.value) return false;

    adventureController.isTransitioning.value = true;

    try {
      _disposePreparedStageControllers();

      final stageController = Get.put(
        AdventureStageController(autoLoadFromArguments: false),
      );

      await stageController.prepareStage(
        categoryLabel: stage.label,
        stageIndex: stage.index,
        exerciseList: stage.exercises,
        deferInitialAudio: true,
      );

      if (stage.exercises.isNotEmpty && stageController.exercises.isEmpty) {
        adventureController.isTransitioning.value = false;
        _disposePreparedStageControllers();
        return false;
      }

      final animationController = Get.isRegistered<StageAnimationController>()
          ? Get.find<StageAnimationController>()
          : null;
      final audioController = Get.isRegistered<StageAudioController>()
          ? Get.find<StageAudioController>()
          : null;

      final navigation = replaceCurrent
          ? Get.off(() => const AdventureStagePage())
          : Get.to(() => const AdventureStagePage());

      adventureController.isTransitioning.value = false;

      navigation?.whenComplete(() {
        _disposePreparedStageControllers(
          stageController: stageController,
          animationController: animationController,
          audioController: audioController,
        );
      });

      return true;
    } catch (e) {
      dev.log(
        'openStage error: $e',
        name: 'AdventureStageNavigationHelper',
      );
      adventureController.isTransitioning.value = false;
      _disposePreparedStageControllers();
      return false;
    }
  }

  static void _disposePreparedStageControllers({
    AdventureStageController? stageController,
    StageAnimationController? animationController,
    StageAudioController? audioController,
  }) {
    if (Get.isRegistered<AdventureStageController>()) {
      final registered = Get.find<AdventureStageController>();
      if (stageController == null || identical(registered, stageController)) {
        Get.delete<AdventureStageController>(force: true);
      }
    }
    if (Get.isRegistered<StageAnimationController>()) {
      final registered = Get.find<StageAnimationController>();
      if (animationController == null ||
          identical(registered, animationController)) {
        Get.delete<StageAnimationController>(force: true);
      }
    }
    if (Get.isRegistered<StageAudioController>()) {
      final registered = Get.find<StageAudioController>();
      if (audioController == null || identical(registered, audioController)) {
        Get.delete<StageAudioController>(force: true);
      }
    }
  }
}
