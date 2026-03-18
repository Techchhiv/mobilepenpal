import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/adventure_stage_navigation_helper.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_controller.dart';

class AdventureSummaryController extends GetxController {
  late final int correctAnswers;
  late final int totalQuestions;
  late final int starsEarned;
  late final int pointsEarned;
  late final int stageIndex;
  late final int earnedCoins;
  late final int earnedXp;
  final isRestarting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    
    correctAnswers = args['correct'] as int? ?? 0;
    totalQuestions = args['total'] as int? ?? 0;
    starsEarned = args['stars'] as int? ?? 0;
    pointsEarned = args['points'] as int? ?? 0;
    stageIndex = args['stageIndex'] as int? ?? 0;
    earnedCoins = args['coins'] as int? ?? 0;
    earnedXp = args['xp'] as int? ?? 0;
  }

  void goBack() {
    _unlockAndBack();
  }

  Future<void> retry() async {
    if (Get.isRegistered<AdventureController>()) {
      final adventureController = Get.find<AdventureController>();
      await adventureController.completeStage(stageIndex);

      final stage = AdventureStageNavigationHelper.findStageByIndex(
        adventureController,
        stageIndex,
      );

      if (stage != null) {
        isRestarting.value = true;
        final didNavigate = await AdventureStageNavigationHelper.openStage(
          stage: stage,
          adventureController: adventureController,
          replaceCurrent: true,
        );
        if (didNavigate) return;
        isRestarting.value = false;
      }
    }

    _unlockAndBack();
  }

  void _unlockAndBack({dynamic result}) {
    // Determine if the user passed. For adventure, passing is usually any success,
    // but maybe we require at least 1 star or something. Let's say if they finished it.
    if (Get.isRegistered<AdventureController>()) {
      Get.find<AdventureController>().completeStage(stageIndex);
    }
    Get.back(result: result);
  }
}
