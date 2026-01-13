class MonthlySummary {
  final int studentId;
  final String month;
  final String fromDate;
  final String toDate;

  final int totalStarsEarned;
  final int totalStagesCompleted;
  final int totalTimeSpentSeconds;

  final int totalExercisesAttempted;
  final int totalCorrectAttempts;
  final double accuracy;

  final int practiceDays;
  final int charactersAttempted;

  final List<Map<String, dynamic>> charactersSummary;
  final List<Map<String, dynamic>> topMasteredCharacters;
  final List<Map<String, dynamic>> charactersToReview;

  final List<Map<String, dynamic>> weeklyChart;

  final String? summaryText;

  MonthlySummary({
    required this.studentId,
    required this.month,
    required this.fromDate,
    required this.toDate,
    required this.totalStarsEarned,
    required this.totalStagesCompleted,
    required this.totalTimeSpentSeconds,
    required this.totalExercisesAttempted,
    required this.totalCorrectAttempts,
    required this.accuracy,
    required this.practiceDays,
    required this.charactersAttempted,
    required this.charactersSummary,
    required this.topMasteredCharacters,
    required this.charactersToReview,
    required this.weeklyChart,
    this.summaryText,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      studentId: json['student_id'] ?? 0,
      month: json['month'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',

      totalStarsEarned: json['total_stars_earned'] ?? 0,
      totalStagesCompleted: json['total_stages_completed'] ?? 0,
      totalTimeSpentSeconds: json['total_time_spent_seconds'] ?? 0,

      totalExercisesAttempted: json['total_exercises_attempted'] ?? 0,
      totalCorrectAttempts: json['total_correct_attempts'] ?? 0,
      accuracy: (json['accuracy'] is num)
          ? (json['accuracy'] as num).toDouble()
          : double.tryParse('${json['accuracy']}') ?? 0.0,

      practiceDays: json['practice_days'] ?? 0,
      charactersAttempted: json['characters_attempted'] ?? 0,

      charactersSummary: (json['characters_summary'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),

      topMasteredCharacters: (json['top_mastered_characters'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),

      charactersToReview: (json['characters_to_review'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),

      weeklyChart: (json['weekly_chart'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),

      summaryText: json['summary_text']?.toString(),
    );
  }
}
