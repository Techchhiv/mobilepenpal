/// Data model representing the quest summary returned by the backend.
///
/// Contains curriculum-derived data for generating daily quests:
///  - weakest character (lowest accuracy)
///  - recent characters (from the most recently completed level)
///  - all learned characters (pool for random review)
///  - oldest practiced character (for deep memory fallback)
///  - whether all levels are completed
class QuestSummary {
  final List<WeakestCharacter> weakestCharacters;
  final List<String> recentCharacters;
  final List<String> allLearnedCharacters;
  final String? oldestPracticedCharacter;
  final bool allLevelsCompleted;

  const QuestSummary({
    this.weakestCharacters = const [],
    this.recentCharacters = const [],
    this.allLearnedCharacters = const [],
    this.oldestPracticedCharacter,
    this.allLevelsCompleted = false,
  });

  factory QuestSummary.fromJson(Map<String, dynamic> json) {
    return QuestSummary(
      weakestCharacters: (json['weakest_characters'] as List<dynamic>?)
              ?.map((e) => WeakestCharacter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentCharacters: (json['recent_characters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allLearnedCharacters: (json['all_learned_characters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      oldestPracticedCharacter:
          json['oldest_practiced_character']?.toString(),
      allLevelsCompleted: json['all_levels_completed'] == true,
    );
  }

  /// Whether the student has any curriculum progress at all.
  bool get hasLearnedAnything => allLearnedCharacters.isNotEmpty;
}

/// Represents the weakest character with its accuracy stats.
class WeakestCharacter {
  final String character;
  final double accuracy;
  final int attempts;

  const WeakestCharacter({
    required this.character,
    required this.accuracy,
    required this.attempts,
  });

  factory WeakestCharacter.fromJson(Map<String, dynamic> json) {
    return WeakestCharacter(
      character: (json['character'] ?? '').toString(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}
