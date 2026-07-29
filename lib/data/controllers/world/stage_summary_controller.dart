import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class StageSummaryController extends GetxController
    with GetTickerProviderStateMixin {
  late final int worldId;
  late final int levelId;
  late final int stageId;

  static const int maxStars = 3;
  late final int starsEarned;
  late final int correctAnswers;
  late final int totalQuestions;
  late final int? nextStageId;
  late final bool isLast;

  final isContinuing = false.obs;
  late final List<AnimationController> starControllers;

  @override
  void onInit() {
    super.onInit();

    final params = Get.parameters;
    worldId = int.tryParse(params['worldId'] ?? '0') ?? 0;
    levelId = int.tryParse(params['levelId'] ?? '0') ?? 0;
    stageId = int.tryParse(params['stageId'] ?? '0') ?? 0;

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final summary = args['summary'] as Map<String, dynamic>? ?? {};

    starsEarned = (summary['stars_earned'] as int?) ?? 0;
    correctAnswers = (summary['correct_answers'] as int?) ?? 0;
    totalQuestions = (summary['total_questions'] as int?) ?? 0;
    isLast = (summary['is_last'] as bool?) ?? false;

    final rawNext = summary['next_stage_id'];
    if (rawNext is int) {
      nextStageId = rawNext;
    } else if (rawNext is String) {
      nextStageId = int.tryParse(rawNext);
    } else {
      nextStageId = null;
    }

    starControllers = List.generate(
      maxStars,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStarAnimations();
    });
  }

  @override
  void onClose() {
    for (final c in starControllers) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> _startStarAnimations() async {
    if (starsEarned <= 0) return;

    await Future.delayed(const Duration(milliseconds: 400));

    for (var i = 0; i < starsEarned && i < maxStars; i++) {
      final c = starControllers[i];
      c.reset();
      c.forward();
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> goBackToLevel() async {
    if (isContinuing.value) return;
    isContinuing.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 16));

      final levelController = Get.find<LevelController>();
      levelController.worldId = worldId;
      levelController.levelId = levelId;

      levelController.currentLevel.value = null;
      await levelController.fetchLevelDetail();
      levelController.update();

      bool hitLevel = false;

      Get.until((route) {
        final name = route.settings.name ?? '';
        final isLevelOnly =
            name.contains('/level/') && !name.contains('/stage/');
        if (isLevelOnly) hitLevel = true;
        return isLevelOnly;
      });

      if (!hitLevel) {
        final levelRoute = RouteBuilder.build(AppRoutes.level, {
          'worldId': worldId.toString(),
          'levelId': levelId.toString(),
        });
        Get.offNamed(levelRoute);
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to load level'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (Get.isRegistered<StageSummaryController>()) {
        isContinuing.value = false;
      }
    }
  }

  void retryStage() {
    try {
      final stageController = Get.find<StageController>();
      stageController.resetForRetry();
    } catch (_) {}

    final stageRoute = RouteBuilder.build(AppRoutes.stage, {
      'worldId': worldId.toString(),
      'levelId': levelId.toString(),
      'stageId': stageId.toString(),
    });

    Get.offNamed(stageRoute);
  }

  Future<void> continueNext() async {
    if (isContinuing.value) return;

    if (!isLast) {
      await goBackToLevel();
      return;
    }

    isContinuing.value = true;

    try {
      final worldController = Get.find<WorldController>();
      await worldController.fetchWorldById(worldId);

      final worldRoute = RouteBuilder.build(AppRoutes.world, {
        'id': worldId.toString(),
      });

      Get.offAllNamed(worldRoute);
    } catch (_) {
      if (Get.isRegistered<StageSummaryController>()) {
        isContinuing.value = false;
      }
    }
  }
}
