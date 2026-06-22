import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/adventure_stage_navigation_helper.dart';
import 'package:mobilepenpal/core/utils/stage_session_type.dart';
import 'package:mobilepenpal/data/controllers/mini_game/adventure/adventure_controller.dart';
import 'package:mobilepenpal/data/controllers/dashboard/navigation_controller.dart';
import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AdventureSummaryController extends GetxController {
  late final int correctAnswers;
  late final int totalQuestions;
  late final int starsEarned;
  late final int pointsEarned;
  late final int stageIndex;
  late final int earnedCoins;
  late final int earnedXp;
  late final String sessionType;
  late final String categoryLabel;
  late final List<Exercise> exercises;

  final isRestarting = false.obs;

  bool get isDailyChallenge => StageSessionType.isDailyChallenge(sessionType);

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
    sessionType =
        args['sessionType'] as String? ?? StageSessionType.adventure;
    categoryLabel = args['categoryLabel'] as String? ?? 'Daily Challenge';
    exercises =
        (args['exercises'] as List? ?? const <dynamic>[])
            .whereType<Exercise>()
            .toList();
  }

  void goBack() {
    if (isDailyChallenge) {
      _returnToDailyChallenge();
      return;
    }

    _unlockAndBack();
  }

  Future<void> retry() async {
    if (isDailyChallenge) {
      isRestarting.value = true;
      final didNavigate = await AdventureStageNavigationHelper.openPreparedStage(
        categoryLabel: categoryLabel,
        stageIndex: stageIndex,
        exerciseList: exercises,
        sessionType: sessionType,
        replaceCurrent: true,
      );
      if (didNavigate) return;
      isRestarting.value = false;
      _returnToDailyChallenge();
      return;
    }

    if (Get.isRegistered<AdventureController>()) {
      final adventureController = Get.find<AdventureController>();
      
      final stage = AdventureStageNavigationHelper.findStageByIndex(
        adventureController,
        stageIndex,
      );

      if (stage != null) {
        await adventureController.completeStage(stage, stars: starsEarned);

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
    if (!isDailyChallenge && Get.isRegistered<AdventureController>()) {
      final adventureController = Get.find<AdventureController>();
      final stage = AdventureStageNavigationHelper.findStageByIndex(
        adventureController,
        stageIndex,
      );
      if (stage != null) {
        adventureController.completeStage(stage, stars: starsEarned);
      }
    }
    Get.back(result: result);
  }

  void _returnToDailyChallenge() {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changePage(2);
    }

    Get.offAllNamed(
      AppRoutes.home,
      arguments: {'initialTabIndex': 2},
    );
  }
}
