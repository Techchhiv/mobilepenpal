import 'package:mobilepenpal/data/models/quest/quest_type.dart';

/// Data model representing a single quest in the quest system.
///
/// Each quest tracks its type, visual metadata, progress, reward,
/// and the characters the user will practice.
class Quest {
  final String id;
  final QuestType type;
  final String title;
  final String subtitle;
  final List<String> previewCharacters;
  final int progress;      // e.g. 2 out of 5 completed
  final int total;         // total steps/characters to practice
  final int rewardXp;
  final bool isCompleted;

  const Quest({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.previewCharacters,
    required this.progress,
    required this.total,
    required this.rewardXp,
    this.isCompleted = false,
  });

  /// Convenience getter: progress as a 0.0–1.0 fraction.
  double get progressFraction =>
      total > 0 ? (progress / total).clamp(0.0, 1.0) : 0.0;

  /// Returns a copy with updated fields.
  Quest copyWith({
    String? id,
    QuestType? type,
    String? title,
    String? subtitle,
    List<String>? previewCharacters,
    int? progress,
    int? total,
    int? rewardXp,
    bool? isCompleted,
  }) {
    return Quest(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      previewCharacters: previewCharacters ?? this.previewCharacters,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      rewardXp: rewardXp ?? this.rewardXp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
