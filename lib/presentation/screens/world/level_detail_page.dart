import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/data/models/level/level_stage.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class LevelDetailPage extends GetView<LevelController> {
  const LevelDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return LoadingOverlay(
          isLoading: controller.isLoading.value,
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
        );
      }),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        "assets/images/backgrounds/level_background.png",
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

  Widget _buildTopBar() {
    final lc = Get.find<LocaleController>();

    return GetBuilder<LocaleController>(
      builder: (_) {
        final level = controller.currentLevel.value;

        final worldTitle = lc.isKhmer
            ? (level?.worldName ?? "Loading...")
            : (level?.worldNameEn ?? level?.worldName ?? "Loading...");

        return Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final worldController = Get.find<WorldController>();

                  if (controller.worldId > 0) {
                    await worldController.fetchWorldById(controller.worldId);
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
                      Expanded(
                        child: Text(
                          worldTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyContent() {
    if (controller.isLoading.value) {
      return const SizedBox.shrink();
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
              width: 80,
            ),
            // child: Image.asset(
            //   'assets/images/illustrations/boy.png',
            //   height: 100,
            // ),
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

    final lc = Get.find<LocaleController>();
    final title = lc.isKhmer
        ? stage.name
        : ((stage.nameEn?.trim().isNotEmpty ?? false)
              ? stage.nameEn!
              : stage.name);

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
                        NumberFormatUtils.fraction(stageNumber, totalStages),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
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
                      _buildStarDisplay(stage.starsEarned, 3),
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

  Widget _buildStarDisplay(int starsEarned, int maxStars) {
    const fixedMax = 3;
    final ms = fixedMax; // force 3 always
    final earned = starsEarned.clamp(0, ms);

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(ms, (index) {
          final isFilled = index < earned;
          final middleIndex = ms ~/ 2;
          final dy = (index == middleIndex) ? -8.0 : 4.0;

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

  Future<void> _navigateToStage(int stageId) async {
    final StageController stageController = Get.find<StageController>();

    controller.isLoading.value = true;
    try {
      await stageController.loadStage(
        newStageId: stageId,
        newWorldId: controller.worldId,
        newLevelId: controller.levelId,
      );

      if (stageController.currentStage.value == null) {
        AppSnackbar.show(
          title: 'error'.tr,
          'stage_not_found'.tr,
          backgroundColor: Colors.red,
        );
        return;
      }

      final route = RouteBuilder.build(AppRoutes.stage, {
        'worldId': controller.worldId.toString(),
        'levelId': controller.levelId.toString(),
        'stageId': stageId.toString(),
      });

      controller.isLoading.value = false;
      await Future.delayed(Duration.zero);

      Get.toNamed(route);
    } finally {
      controller.isLoading.value = false;
    }
  }
}
