import 'dart:math';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/quest/quest.dart';
import 'package:mobilepenpal/data/models/quest/quest_summary.dart';
import 'package:mobilepenpal/data/models/quest/quest_type.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_board_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
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
      // Ensure StageAnimationController and StageAudioController are registered
      if (!Get.isRegistered<StageAnimationController>()) {
        Get.put(StageAnimationController());
      }
      if (!Get.isRegistered<StageAudioController>()) {
        Get.put(StageAudioController());
      }

      // Pre-load/prepare the quest details
      final boardController = Get.isRegistered<QuestBoardController>()
          ? Get.find<QuestBoardController>()
          : Get.put(QuestBoardController());

      await boardController.prepareQuest(quest);

      Get.toNamed('/quest/board', arguments: {'quest': quest});
    } catch (e) {
      Get.snackbar('Error', 'Failed to start quest: $e');
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
        final newQuests = _generateQuests(summary);
        
        // Merge with existing quests to preserve progress
        for (int i = 0; i < newQuests.length; i++) {
          final existingIdx = quests.indexWhere((q) => q.id == newQuests[i].id);
          if (existingIdx != -1) {
            // Preserve progress and characters if it's the same quest ID
            final eq = quests[existingIdx];
            newQuests[i] = newQuests[i].copyWith(
              progress: eq.progress,
              isCompleted: eq.isCompleted,
              previewCharacters: eq.previewCharacters,
              total: eq.total,
            );
          }
        }
        
        quests.value = newQuests;
      } else {
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
        title: 'quest_title_weakest',
        subtitle: 'quest_subtitle_weakest',
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
      title: 'quest_title_mastery',
      subtitle: 'quest_subtitle_mastery',
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
        title: 'quest_title_deep_memory',
        subtitle: 'quest_subtitle_deep_memory',
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
        title: 'quest_title_recent',
        subtitle: 'quest_subtitle_recent',
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
      title: 'quest_title_recent',
      subtitle: 'quest_subtitle_recent_fallback',
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
      title: 'quest_title_random',
      subtitle: 'quest_subtitle_random',
      previewCharacters: chars,
      progress: 0,
      total: chars.length,
      rewardCoins: 20,
    );
  }
}
