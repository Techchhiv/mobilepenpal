import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/models/level/level_stage.dart';

class LevelDetailPage extends StatelessWidget {
  const LevelDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LevelController levelController = Get.put(LevelController());

    final parameters = Get.parameters;
    final levelId = int.tryParse(parameters['levelId'] ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (levelId == null) {
        Get.snackbar(
          'Error',
          'Level ID not provided',
          snackPosition: SnackPosition.TOP,
        );
        Future.delayed(const Duration(seconds: 2), () => Get.back());
        return;
      }
      levelController.fetchLevelDetail(levelId);
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/level_background.jpg",
              fit: BoxFit.fill,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.1, 1],
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Obx(() {
                    final level = levelController.currentLevel.value;
                    return Row(
                      children: [
                        InkWell(
                          onTap: () => Get.back(),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  level?.worldName ?? "Loading...",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (levelController.isLoading.value)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  Obx(() {
                    if (levelController.isLoading.value) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "loading_level".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final level = levelController.currentLevel.value;
                    if (level == null) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "level_not_found".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  final levelId = int.tryParse(
                                    Get.parameters['levelId'] ?? '',
                                  );
                                  if (levelId != null) {
                                    levelController.fetchLevelDetail(levelId);
                                  }
                                },
                                child: Text("retry".tr),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Expanded(
                      child: Column(
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

                          Expanded(child: _buildStagesCarousel(level.stages)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagesCarousel(List<LevelStage> stages) {
    return PageView.builder(
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];
        return _buildStageCard(stage, index + 1, stages.length);
      },
    );
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
                color: Colors.black.withOpacity(0.1),
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

                      Spacer(),
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

                      Spacer(),
                      _buildStarDisplay(
                        stage.starsEarned,
                        stage.maxStars,
                        isUnlocked,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUnlocked
                        ? () => _navigateToStage(stage)
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
                          ? AppColors.primary.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
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

  Widget _buildStarDisplay(int starsEarned, int maxStars, bool isUnlocked) {
    const double radius = 140;

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxStars, (index) {
          final isFilled = index < starsEarned;

          double angleStep = 30;
          double startAngle = -angleStep * (maxStars - 1) / 2;

          double angle = (startAngle + index * angleStep) * (3.1416 / 180);

          double dy = radius * (1 - cos(angle));

          return Transform.translate(
            offset: Offset(0, dy),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: (isFilled ? Colors.amber : Colors.grey.shade400),
              size: 64,
            ),
          );
        }),
      ),
    );
  }

  void _navigateToStage(LevelStage stage) {
    // Navigate to stage gameplay page
    // Get.to(() => StageGamePage(stage: stage));

    // For now, show a snackbar
    Get.snackbar(
      "Stage ${stage.name}",
      "Navigating to stage gameplay...",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
