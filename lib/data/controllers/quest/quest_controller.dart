import 'dart:math';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/quest/quest.dart';
import 'package:mobilepenpal/data/models/quest/quest_summary.dart';
import 'package:mobilepenpal/data/models/quest/quest_type.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_board_controller.dart';
import 'package:mobilepenpal/data/services/home_service.dart';

/// Controller backing the Quest screen.
///
/// Fetches curriculum-based quest data from the backend and generates
/// exactly 3 daily quests:
///   1. Weakest Character (or Mastery Showcase fallback)
///   2. Recent Character  (or Deep Memory fallback)
///   3. Random Review
class QuestController extends GetxController {
  final HomeService _homeService = HomeService();

  // ── Observable state ──────────────────────────────────────────
  final quests = <Quest>[].obs;
  final isLoading = false.obs;
  final isStartingQuest = false.obs;

  // ── Helpers ───────────────────────────────────────────────────
  HomeController? get _home =>
      Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

  String get studentName {
    final name = _home?.fullName.trim() ?? '';
    return (name.isEmpty || name.toLowerCase() == 'student') ? 'Learner' : name;
  }

  int get dailyStreak => _home?.student.value?.streak ?? 0;
  int get totalCoins => _home?.student.value?.coin ?? 0;

  /// Number of quests already completed today.
  int get completedCount => quests.where((q) => q.isCompleted).length;

  /// Total available quests.
  int get totalQuests => quests.length;

  /// Whether every quest is completed.
  bool get allCompleted => quests.isNotEmpty && completedCount == totalQuests;

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadQuests();
  }

  // ── Actions ───────────────────────────────────────────────────

  Future<void> startQuest(String questId) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = quests[idx];
    if (quest.isCompleted) return;

    if (isStartingQuest.value) return;

    isStartingQuest.value = true;
    try {
      Get.delete<QuestBoardController>();
      final boardController = Get.put(QuestBoardController());
      await boardController.prepareQuest(quest);

      Get.toNamed('/quest/board');
    } finally {
      isStartingQuest.value = false;
    }
  }

  /// Pull-to-refresh / retry.
  Future<void> refreshQuests() async {
    await _loadQuests();
  }

  void incrementQuestProgress(String id) {
    final idx = quests.indexWhere((q) => q.id == id);
    if (idx != -1) {
      final q = quests[idx];
      final newProgress = q.progress + 1;
      quests[idx] = q.copyWith(
        progress: newProgress,
        isCompleted: newProgress >= q.total,
      );
    }
  }

  // ── Data Loading ──────────────────────────────────────────────
  Future<void> _loadQuests() async {
    isLoading.value = true;
    try {
      final response = await _homeService.getQuestSummary();

      if (response.code == 200 && response.data != null) {
        final summary = response.data!;
        quests.value = _generateQuests(summary);
      } else {
        // Network error or bad response — show empty state
        quests.value = [];
      }
    } catch (e) {
      quests.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // ── Quest Generation Logic ────────────────────────────────────

  List<Quest> _generateQuests(QuestSummary summary) {
    // If the student hasn't completed any curriculum stages yet, show nothing.
    if (!summary.hasLearnedAnything) {
      return [];
    }

    final rng = Random();
    final result = <Quest>[];

    // ─── Quest 1: Weakest Character ─────────────────────────────
    result.add(_buildWeakestQuest(summary, rng));

    // ─── Quest 2: Recent Character ──────────────────────────────
    result.add(_buildRecentQuest(summary, rng));

    // ─── Quest 3: Random Review ─────────────────────────────────
    result.add(_buildRandomQuest(summary, rng));

    return result;
  }

  /// Quest 1: Weakest character quest.
  /// Fallback: If no weakest exists (perfect accuracy or not enough attempts),
  /// create a "Mastery Showcase" quest with the most-practiced character.
  Quest _buildWeakestQuest(QuestSummary summary, Random rng) {
    if (summary.weakestCharacters.isNotEmpty) {
      final chars = summary.weakestCharacters.map((e) => e.character).toList();
      return Quest(
        id: 'q1_weakest',
        type: QuestType.weakestCharacters,
        title: 'Weakest Character',
        subtitle: 'Practice your lowest-accuracy letters',
        previewCharacters: chars,
        progress: 0,
        total: chars.length,
        rewardCoins: 15,
      );
    }

    // Fallback: Mastery Showcase — pick a random learned character
    final shuffled = List<String>.from(summary.allLearnedCharacters)..shuffle(rng);
    final char = shuffled.first;
    return Quest(
      id: 'q1_mastery',
      type: QuestType.masteryShowcase,
      title: 'Mastery Showcase ⭐',
      subtitle: 'Show off your best writing!',
      previewCharacters: [char],
      progress: 0,
      total: 1,
      rewardCoins: 10,
    );
  }

  /// Quest 2: Recent character quest (from the most recently completed level).
  /// Fallback: If all levels are completed, create a "Deep Memory" quest
  /// with the oldest-practiced character.
  Quest _buildRecentQuest(QuestSummary summary, Random rng) {
    if (summary.allLevelsCompleted) {
      // Deep Memory fallback
      final char =
          summary.oldestPracticedCharacter ??
          (List<String>.from(summary.allLearnedCharacters)..shuffle(rng)).first;
      return Quest(
        id: 'q2_deep_memory',
        type: QuestType.deepMemory,
        title: 'Deep Memory 🧠',
        subtitle: 'Refresh a character from long ago',
        previewCharacters: [char],
        progress: 0,
        total: 1,
        rewardCoins: 15,
      );
    }

    if (summary.recentCharacters.isNotEmpty) {
      final shuffled = List<String>.from(summary.recentCharacters)..shuffle(rng);
      // Pick up to 5 unique characters (no repeating here)
      final chars = shuffled.take(5).toList();
      
      return Quest(
        id: 'q2_recent',
        type: QuestType.recentReview,
        title: 'Recent Characters',
        subtitle: 'Revisit your latest lesson',
        previewCharacters: chars,
        progress: 0,
        total: chars.length,
        rewardCoins: 12,
      );
    }

    // Extra fallback
    final shuffled = List<String>.from(summary.allLearnedCharacters)..shuffle(rng);
    final chars = shuffled.take(5).toList();
    return Quest(
      id: 'q2_recent_fallback',
      type: QuestType.recentReview,
      title: 'Recent Characters',
      subtitle: 'Revisit characters you\'ve learned',
      previewCharacters: chars,
      progress: 0,
      total: chars.length,
      rewardCoins: 12,
    );
  }

  /// Quest 3: Random review — random characters from the entire learned pool.
  Quest _buildRandomQuest(QuestSummary summary, Random rng) {
    final shuffled = List<String>.from(summary.allLearnedCharacters)..shuffle(rng);
    // Take up to 5 random characters
    final chars = shuffled.take(5).toList();
    
    return Quest(
      id: 'q3_random',
      type: QuestType.randomReview,
      title: 'Random Review',
      subtitle: 'Random mix of everything you\'ve learned',
      previewCharacters: chars,
      progress: 0,
      total: chars.length,
      rewardCoins: 20,
    );
  }
}
