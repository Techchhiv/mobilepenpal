import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_summary_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/summary_widget.dart';

class AdventureSummaryPage extends GetView<AdventureSummaryController> {
  const AdventureSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: LoadingOverlay(
          isLoading: controller.isRestarting.value,
          child: SummaryWidget(
            starsEarned: controller.starsEarned,
            correctAnswers: controller.correctAnswers,
            totalQuestions: controller.totalQuestions,
            earnedCoins: controller.earnedCoins,
            earnedXp: controller.earnedXp,
            onRetry: controller.retry,
            onContinue: controller.goBack,
            onClose: controller.goBack,
          ),
        ),
      ),
    );
  }
}
