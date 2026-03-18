import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/stage_summary_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/summary_widget.dart';

class StageSummaryPage extends GetView<StageSummaryController> {
  const StageSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return LoadingOverlay(
        isLoading: controller.isContinuing.value,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            if (controller.isContinuing.value) return;

            controller.goBackToLevel();
          },
          child: Scaffold(
            body: SummaryWidget(
              starsEarned: controller.starsEarned,
              correctAnswers: controller.correctAnswers,
              totalQuestions: controller.totalQuestions,
              onRetry: controller.retryStage,
              onContinue: controller.continueNext,
              onClose: controller.goBackToLevel,
            ),
          ),
        ),
      );
    });
  }
}
