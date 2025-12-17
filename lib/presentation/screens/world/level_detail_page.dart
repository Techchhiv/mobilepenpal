import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/models/level/level_stage.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class LevelDetailPage extends GetView<LevelController> {
  const LevelDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StageController stageController = Get.find<StageController>();

    return Scaffold(
      body: Obx(
        () => LoadingOverlay(
          isLoading: stageController.isLoading.value,
          child: Stack(
            children: [
              _buildBackground(),
              _buildGradientOverlay(),
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 20),
                      Expanded(child: Obx(_buildBodyContent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        "assets/images/level_background.jpg",
        fit: BoxFit.fill,
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.1, 1],
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── Top bar ─────────────────

  Widget _buildTopBar() {
    return Obx(() {
      final level = controller.currentLevel.value;

      return Row(
        children: [
          InkWell(
            onTap: () {
              if (controller.worldId > 0) {
                final worldRoute = RouteBuilder.build(AppRoutes.world, {
                  'id': controller.worldId.toString(),
                });
                Get.offNamed(worldRoute);
              } else {
                Get.back();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    level?.worldName ?? "Loading...",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (controller.isLoading.value)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBodyContent() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "loading".tr,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final level = controller.currentLevel.value;
    if (level == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              "level_not_found".tr,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                controller.fetchLevelDetail();
              },
              child: Text("retry".tr),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: Lottie.asset(
              'assets/animated/pencil.json',
              repeat: true,
              animate: true,
            ),
          ),
        ),
        Expanded(flex: 1, child: _buildStagesCarousel(level.stages)),
      ],
    );
  }

  Widget _buildStagesCarousel(List<LevelStage> stages) {
    return Obx(() {
      final pc = PageController(
        initialPage: controller.initialStageIndex.value,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!pc.hasClients) return;
        pc.jumpToPage(controller.initialStageIndex.value);
      });

      return PageView.builder(
        controller: pc,
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final stage = stages[index];
          return _buildStageCard(stage, index + 1, stages.length);
        },
      );
    });
  }

  Widget _buildStageCard(LevelStage stage, int stageNumber, int totalStages) {
    final isUnlocked =
        stage.status == "unlocked" || stage.status == "completed";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$stageNumber/$totalStages',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        stage.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Colors.black
                              : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      _buildStarDisplay(stage.starsEarned, stage.maxStars),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUnlocked
                        ? () => _navigateToStage(stage.id)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked
                          ? AppColors.primary
                          : Colors.grey.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: isUnlocked
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUnlocked ? Icons.play_arrow : Icons.lock,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isUnlocked ? "start".tr : "locked".tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── Star display ─────────────────

  Widget _buildStarDisplay(int starsEarned, int maxStars) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxStars, (index) {
          final isFilled = index < starsEarned;

          final middleIndex = maxStars ~/ 2;
          double dy;
          if (index == middleIndex) {
            dy = -8;
          } else {
            dy = 4;
          }

          return Transform.translate(
            offset: Offset(0, dy),
            child: Lottie.asset(
              isFilled
                  ? 'assets/animated/star.json'
                  : 'assets/animated/star_border.json',
              repeat: false,
              animate: isFilled,
            ),
          );
        }),
      ),
    );
  }

  void _navigateToStage(int stageId) async {
    final StageController stageController = Get.find<StageController>();

    stageController.worldId = controller.worldId;
    stageController.levelId = controller.levelId;
    stageController.stageId = stageId;

    stageController.isLoading.value = true;

    await stageController.fetchStageDetail();

    stageController.isLoading.value = false;

    if (stageController.currentStage.value != null) {
      final route = RouteBuilder.build(AppRoutes.stage, {
        'worldId': controller.worldId.toString(),
        'levelId': controller.levelId.toString(),
        'stageId': stageId.toString(),
      });

      Get.toNamed(route);
    } else {
      Get.snackbar('Error', 'Failed to load stage');
    }
  }
}
