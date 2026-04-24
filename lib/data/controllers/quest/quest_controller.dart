import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/quest/quest.dart';
import 'package:mobilepenpal/data/models/quest/quest_type.dart';

/// Controller backing the Quest screen.
///
/// Manages the list of available quests, daily progress tracking,
/// and quest-start logic. Currently uses mock data; swap in real
/// backend calls when ready.
class QuestController extends GetxController {
  // ── Observable state ──────────────────────────────────────────
  final quests = <Quest>[].obs;
  final isLoading = false.obs;

  // ── Helpers ───────────────────────────────────────────────────
  HomeController? get _home =>
      Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

  String get studentName {
    final name = _home?.fullName.trim() ?? '';
    return (name.isEmpty || name.toLowerCase() == 'student')
        ? 'Learner'
        : name;
  }

  int get dailyStreak => _home?.student.value?.streak ?? 3;
  int get totalXp => _home?.student.value?.xp ?? 420;

  /// Number of quests already completed today.
  int get completedCount => quests.where((q) => q.isCompleted).length;

  /// Total available quests.
  int get totalQuests => quests.length;

  /// Whether every quest is completed.
  bool get allCompleted =>
      quests.isNotEmpty && completedCount == totalQuests;

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadMockQuests();
  }

  // ── Actions ───────────────────────────────────────────────────

  /// Simulate starting a quest (mark‑as‑completed for demo).
  void startQuest(String questId) {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = quests[idx];
    if (quest.isCompleted) return;

    // In production this would navigate into a handwriting exercise.
    quests[idx] = quest.copyWith(
      isCompleted: true,
      progress: quest.total,
    );
  }

  /// Pull-to-refresh / retry.
  Future<void> refreshQuests() async {
    isLoading.value = true;
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    _loadMockQuests();
    isLoading.value = false;
  }

  // ── Mock data ─────────────────────────────────────────────────
  void _loadMockQuests() {
    quests.value = [
      const Quest(
        id: 'q1',
        type: QuestType.weakestCharacters,
        title: 'Weakest Characters',
        subtitle: 'Practice your 3 lowest-accuracy letters',
        previewCharacters: ['ក', 'ខ', 'គ'],
        progress: 1,
        total: 3,
        rewardXp: 60,
      ),
      const Quest(
        id: 'q2',
        type: QuestType.recentReview,
        title: 'Recent Review',
        subtitle: 'Revisit characters from your last lesson',
        previewCharacters: ['ង', 'ច', 'ឆ', 'ជ'],
        progress: 0,
        total: 4,
        rewardXp: 50,
      ),
      const Quest(
        id: 'q3',
        type: QuestType.randomReview,
        title: 'Random Review',
        subtitle: 'Random mix of everything you\'ve learned',
        previewCharacters: ['ណ', 'ត', 'ថ'],
        progress: 3,
        total: 3,
        rewardXp: 45,
        isCompleted: true,
      ),
      const Quest(
        id: 'q4',
        type: QuestType.bonus,
        title: 'Bonus Quest ✨',
        subtitle: 'Complete for double XP!',
        previewCharacters: ['ប', 'ផ', 'ព'],
        progress: 0,
        total: 3,
        rewardXp: 100,
      ),
    ];
  }
}
