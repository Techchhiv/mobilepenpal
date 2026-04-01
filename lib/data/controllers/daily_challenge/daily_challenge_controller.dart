import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/utils/adventure_stage_navigation_helper.dart';
import 'package:mobilepenpal/core/utils/daily_challenge_exercise_builder.dart';
import 'package:mobilepenpal/core/utils/stage_session_type.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/data/models/report/daily_summary.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class DailyChallengeController extends GetxController {
  static const int _fallbackEarnedXp = 180;
  static const int _fallbackDailyStreak = 4;

  final HomeService _homeService = HomeService();
  final WorldService _worldService = WorldService();
  final GetStorage _box = GetStorage();

  final isLoading = false.obs;
  final isStarting = false.obs;
  final lastError = RxnString();
  final summary = Rxn<DailySummary>();
  final plan = Rxn<DailyChallengePlan>();

  HomeController? get homeController =>
      Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

  ShopController? get shopController =>
      Get.isRegistered<ShopController>() ? Get.find<ShopController>() : null;

  @override
  void onInit() {
    super.onInit();
    loadChallenge();
  }

  String get studentName {
    final value = homeController?.fullName.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'student') {
      return 'Student';
    }
    return value;
  }

  ShopAvatar? get currentAvatar {
    final avatarFromHome = homeController?.currentShopAvatar;
    if (avatarFromHome != null) return avatarFromHome;

    final shop = shopController;
    if (shop == null) return null;
    return shop.currentAvatar;
  }

  int get earnedXp => homeController?.student.value?.xp ?? _fallbackEarnedXp;
  int get dailyStreak =>
      homeController?.student.value?.streak ?? _fallbackDailyStreak;
  bool get hasChallenge => plan.value != null;
  int get challengeExerciseCount =>
      plan.value?.exercises.length ??
      DailyChallengeExerciseBuilder.targetExerciseCount;

  bool get isCompletedToday {
    final studentId = homeController?.student.value?.id;
    if (studentId == null) return false;
    final saved = _box.read<String>('daily_challenge_date_$studentId');
    if (saved == null) return false;
    final today = DateTime.now().toIso8601String().split('T').first;
    return saved == today;
  }

  Future<void> loadChallenge({bool force = false}) async {
    if (isLoading.value) return;

    isLoading.value = true;
    lastError.value = null;

    try {
      final daily = await _loadDailySummary(force: force);
      summary.value = daily;

      final exerciseBank = await _loadExerciseBank(force: force);
      final adventureController = Get.isRegistered<AdventureController>()
          ? Get.find<AdventureController>()
          : null;
      final builtPlan = DailyChallengeExerciseBuilder.build(
        summary: daily,
        allExercises: exerciseBank,
        recentProgressExercises: _recentProgressExercises(
          adventureController: adventureController,
        ),
        latestProgressExercises: _latestProgressExercises(
          adventureController: adventureController,
        ),
      );

      if (builtPlan == null) {
        plan.value = null;
        lastError.value = 'No daily challenge available yet.';
        return;
      }

      plan.value = builtPlan;
    } catch (e) {
      plan.value = null;
      lastError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startDailyChallenge() async {
    if (isStarting.value) return;

    if (isCompletedToday) {
      AppSnackbar.show('daily_challenge_done'.tr, title: '🎉');
      return;
    }

    if (plan.value == null) {
      await loadChallenge(force: true);
    }

    final readyPlan = plan.value;
    if (readyPlan == null) {
      AppSnackbar.show('No daily challenge is ready yet.', title: 'Oops');
      return;
    }

    isStarting.value = true;
    try {
      final didOpen = await AdventureStageNavigationHelper.openPreparedStage(
        categoryLabel: readyPlan.categoryLabel,
        stageIndex: 0,
        exerciseList: List<Exercise>.from(readyPlan.exercises)..shuffle(),
        sessionType: StageSessionType.dailyChallenge,
      );

      if (!didOpen) {
        AppSnackbar.show('Could not open today\'s challenge.', title: 'Oops');
      }
    } finally {
      if (Get.isRegistered<DailyChallengeController>()) {
        isStarting.value = false;
      }
    }
  }

  Future<DailySummary> _loadDailySummary({bool force = false}) async {
    final cached = homeController?.dailySummary.value;
    if (!force && cached != null) {
      return cached;
    }

    final response = await _homeService.getDailySummary();
    if (response.code == 200 && response.data != null) {
      homeController?.dailySummary.value = response.data!;
      return response.data!;
    }

    if (cached != null) return cached;
    throw Exception(
      response.message.isNotEmpty
          ? response.message
          : 'Failed to load daily summary',
    );
  }

  Future<List<Exercise>> _loadExerciseBank({bool force = false}) async {
    if (Get.isRegistered<AdventureController>()) {
      final adventureController = Get.find<AdventureController>();

      if (!force && adventureController.allExercises.isNotEmpty) {
        return adventureController.allExercises.toList();
      }

      await adventureController.fetchExercises();
      if (adventureController.allExercises.isNotEmpty) {
        return adventureController.allExercises.toList();
      }
    }

    final response = await _worldService.getExercises();
    if (response.code == 200 &&
        response.data != null &&
        response.data!.isNotEmpty) {
      return response.data!;
    }

    throw Exception(
      response.message.isNotEmpty
          ? response.message
          : 'Failed to load exercises',
    );
  }

  List<Exercise> _recentProgressExercises({
    required AdventureController? adventureController,
  }) {
    if (adventureController == null || adventureController.stages.isEmpty) {
      return const <Exercise>[];
    }

    final latestIndex = _currentAdventureStageIndex(adventureController);
    final startIndex =
        latestIndex >= DailyChallengeExerciseBuilder.recentProgressWindow
        ? latestIndex - DailyChallengeExerciseBuilder.recentProgressWindow + 1
        : 0;

    return adventureController.stages
        .sublist(startIndex, latestIndex + 1)
        .expand((stage) => stage.exercises)
        .toList();
  }

  List<Exercise> _latestProgressExercises({
    required AdventureController? adventureController,
  }) {
    if (adventureController == null || adventureController.stages.isEmpty) {
      return const <Exercise>[];
    }

    final latestIndex = _currentAdventureStageIndex(adventureController);
    return adventureController.stages[latestIndex].exercises.toList();
  }

  int _currentAdventureStageIndex(AdventureController adventureController) {
    if (adventureController.stages.isEmpty) return 0;

    int maxUnlocked = -1;
    for (final val in adventureController.categoryUnlockedIndex.values) {
      if (val > maxUnlocked) maxUnlocked = val;
    }

    final unlockedIndex = maxUnlocked > -1 ? maxUnlocked : 0;
    if (unlockedIndex >= adventureController.stages.length) {
      return adventureController.stages.length - 1;
    }
    return unlockedIndex;
  }
}
