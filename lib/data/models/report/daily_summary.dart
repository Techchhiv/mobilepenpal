class DailySummary {
  final int studentId;
  final String date;

  final int starsEarned;
  final int stagesCompleted;
  final int timeSpentSeconds;

  final int exercisesAttempted;
  final int correctAttempts;
  final double accuracy;

  final List<DailyCharacterPerformance> charactersPracticed;
  final DailyCharacterPerformance? bestCharacter;
  final DailyCharacterPerformance? needsAttention;

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
      accuracy: _normalizeAccuracy(json['accuracy']),
      charactersPracticed: ((json['characters_practiced'] as List<dynamic>?) ??
              const <dynamic>[])
          .map(DailyCharacterPerformance.fromDynamic)
          .whereType<DailyCharacterPerformance>()
          .toList(),
      bestCharacter:
          DailyCharacterPerformance.fromDynamic(json['best_character']),
      needsAttention:
          DailyCharacterPerformance.fromDynamic(json['needs_attention']),
    );
  }

  int get accuracyPercent => (accuracy * 100).round();

  DailyCharacterPerformance? get weakestCharacter {
    if (needsAttention != null) return needsAttention;
    if (charactersPracticed.isEmpty) return null;

    final sorted = List<DailyCharacterPerformance>.from(charactersPracticed)
      ..sort((a, b) {
        final byAccuracy = a.accuracy.compareTo(b.accuracy);
        if (byAccuracy != 0) return byAccuracy;
        return b.attempts.compareTo(a.attempts);
      });

    return sorted.first;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static double _normalizeAccuracy(dynamic value) {
    final parsed = _toDouble(value);
    if (parsed > 1.0 && parsed <= 100.0) {
      return parsed / 100.0;
    }
    return parsed;
  }
}

class DailyCharacterPerformance {
  final String character;
  final double accuracy;
  final int attempts;
  final String? characterType;
  final String? difficulty;
  final String? mathOp;

  const DailyCharacterPerformance({
    required this.character,
    required this.accuracy,
    required this.attempts,
    this.characterType,
    this.difficulty,
    this.mathOp,
  });

  int get accuracyPercent => (accuracy * 100).round();

  factory DailyCharacterPerformance.fromJson(Map<String, dynamic> json) {
    return DailyCharacterPerformance(
      character: (json['character'] ?? json['label'] ?? '').toString().trim(),
      accuracy: _normalizeAccuracy(json['accuracy']),
      attempts: _toInt(json['attempts']),
      characterType:
          _toNullableString(json['character_type'] ?? json['type']),
      difficulty: _toNullableString(json['difficulty']),
      mathOp: _toNullableString(json['math_op']),
    );
  }

  static DailyCharacterPerformance? fromDynamic(dynamic value) {
    if (value is DailyCharacterPerformance) return value;
    if (value is Map<String, dynamic>) {
      final parsed = DailyCharacterPerformance.fromJson(value);
      return parsed.character.isEmpty ? null : parsed;
    }
    if (value is Map) {
      final parsed = DailyCharacterPerformance.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
      return parsed.character.isEmpty ? null : parsed;
    }
    return null;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static double _normalizeAccuracy(dynamic value) {
    final parsed = _toDouble(value);
    if (parsed > 1.0 && parsed <= 100.0) {
      return parsed / 100.0;
    }
    return parsed;
  }

  static String? _toNullableString(dynamic value) {
    final out = value?.toString().trim();
    if (out == null || out.isEmpty) return null;
    return out;
  }
}
