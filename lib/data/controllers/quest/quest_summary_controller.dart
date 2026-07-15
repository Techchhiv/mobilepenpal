import 'package:get/get.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/data/controllers/dashboard/navigation_controller.dart';

class QuestSummaryController extends GetxController {
  late final int starsEarned;
  late final int correctAnswers;
  late final int totalQuestions;
  late final int earnedCoins;

  final isContinuing = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final summary = args['summary'] as Map<String, dynamic>? ?? {};

    starsEarned = (summary['stars_earned'] as int?) ?? 0;
    correctAnswers = (summary['correct_answers'] as int?) ?? 0;
    totalQuestions = (summary['total_questions'] as int?) ?? 0;
    
    // We get coins from the summary data directly if passed
    // If not passed in summary, we fallback to args 
    earnedCoins = (summary['current_coin'] != null) 
                  ? ((args['quest']?.rewardCoins) ?? 0) 
                  : 0;
  }

  void goBackToQuestHub() {
    if (isContinuing.value) return;
    isContinuing.value = true;

    try {
      bool hitDashboard = false;
      Get.until((route) {
        if (route.settings.name == AppRoutes.dashboard) {
          hitDashboard = true;
          return true;
        }
        return route.isFirst;
      });
      if (!hitDashboard) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changePage(2);
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.dashboard);
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changePage(2);
      }
    } finally {
      if (Get.isRegistered<QuestSummaryController>()) {
        isContinuing.value = false;
      }
    }
  }

  void retryQuest() {
    Get.back(); // Go back to the quest board, assuming we haven't popped it
  }

  void continueNext() {
    goBackToQuestHub();
  }
}
