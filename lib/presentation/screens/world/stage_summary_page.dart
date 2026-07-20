import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/controllers/world/stage_summary_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class StageSummaryPage extends GetView<StageSummaryController> {
  const StageSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (controller.isContinuing.value) return;

          controller.goBackToLevel();
        },
        child: Scaffold(
          body: LoadingOverlay(
            isLoading: controller.isContinuing.value,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/backgrounds/stage_background.png",
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2B7A78).withValues(alpha: 1),
                          Color(0xFF6B9F8E).withValues(alpha: 0.0),
                        ],
                        stops: const [0.15, 0.45],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      _buildIcon(),
                      const SizedBox(height: 24),
                      _buildScore(),
                      Expanded(child: _buildStarDisplay()),
                      _buildBottomButtons(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: controller.goBackToLevel,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Lottie.asset("assets/animated/trophy.json", repeat: false),
    );
  }

  Widget _buildScore() {
    final rawScore =
        '${controller.correctAnswers}/${controller.totalQuestions}';
    final score = NumberFormatUtils.digitsByLocale(rawScore);

    final msgKey = _encouragementKey(
      stars: controller.starsEarned,
      correct: controller.correctAnswers,
      total: controller.totalQuestions,
    );

    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          msgKey.tr,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStarDisplay() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(StageSummaryController.maxStars, (index) {
          final isEarned = index < controller.starsEarned;

          final dy = index == 1 ? -18.0 : 6.0;

          return Transform.translate(
            offset: Offset(0, dy),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                isEarned
                    ? 'assets/animated/star.json'
                    : 'assets/animated/star_border.json',
                controller: isEarned ? controller.starControllers[index] : null,
                onLoaded: isEarned
                    ? (composition) {
                        controller.starControllers[index].duration =
                            composition.duration;
                      }
                    : null,
                repeat: false,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.globalMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: controller.retryStage,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1FB9FF),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.replay, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: controller.continueNext,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _encouragementKey({
    required int stars,
    required int correct,
    required int total,
  }) {
    if (total <= 0) return 'summary_good_try';

    final accuracy = correct / total;

    if (stars >= 3 || accuracy >= 0.999) return 'summary_perfect';

    if (stars == 2 || accuracy >= 0.50) return 'summary_great';

    return 'summary_good_try';
  }
}
