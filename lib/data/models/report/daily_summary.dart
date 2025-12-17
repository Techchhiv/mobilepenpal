class DailySummary {
  final int studentId;
  final String date;

  final int starsEarned;
  final int stagesCompleted;
  final int timeSpentSeconds;

  final int exercisesAttempted;
  final int correctAttempts;
  final double accuracy;

  final List<dynamic> charactersPracticed;
  final dynamic bestCharacter;
  final dynamic needsAttention;

  DailySummary({
    required this.studentId,
    required this.date,
    required this.starsEarned,
    required this.stagesCompleted,
    required this.timeSpentSeconds,
    required this.exercisesAttempted,
    required this.correctAttempts,
    required this.accuracy,
    required this.charactersPracticed,
    required this.bestCharacter,
    required this.needsAttention,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      studentId: json['student_id'] ?? 0,
      date: json['date'] ?? '',
      starsEarned: json['stars_earned'] ?? 0,
      stagesCompleted: json['stages_completed'] ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      exercisesAttempted: json['exercises_attempted'] ?? 0,
      correctAttempts: json['correct_attempts'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      charactersPracticed: (json['characters_practiced'] as List<dynamic>? ?? []),
      bestCharacter: json['best_character'],
      needsAttention: json['needs_attention'],
    );
  }

  int get accuracyPercent => (accuracy * 100).round();
}
