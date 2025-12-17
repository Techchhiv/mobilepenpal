import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/data/controllers/world/stage_summary_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class StageSummaryPage extends GetView<StageSummaryController> {
  const StageSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return LoadingOverlay(
        isLoading: controller.isContinuing.value,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2B7A78),
                  Color(0xFF6B9F8E),
                  Color(0xFF8FB99F),
                ],
              ),
            ),
            child: SafeArea(
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
    return Column(
      children: [
        Text(
          '${controller.correctAnswers}/${controller.totalQuestions}',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ចម្លើយត្រឹមត្រូវ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
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
    return Padding(
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
                  child: Text(
                    'retry'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
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
                  child: Text(
                    'continue'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
