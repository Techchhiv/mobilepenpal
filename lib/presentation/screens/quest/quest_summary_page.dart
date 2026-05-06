import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_summary_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/summary_widget.dart';

class QuestSummaryPage extends GetView<QuestSummaryController> {
  const QuestSummaryPage({super.key});

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

            controller.goBackToQuestHub();
          },
          child: Scaffold(
            body: SummaryWidget(
              starsEarned: controller.starsEarned,
              correctAnswers: controller.correctAnswers,
              totalQuestions: controller.totalQuestions,
              earnedCoins: controller.earnedCoins,
              onRetry: controller.retryQuest,
              onContinue: controller.continueNext,
              onClose: controller.goBackToQuestHub,
            ),
          ),
        ),
      );
    });
  }
}
