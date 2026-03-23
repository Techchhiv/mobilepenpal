import 'dart:math';

import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/data/models/report/daily_summary.dart';

class DailyChallengePlan {
  final DailyCharacterPerformance? focus;
  final List<Exercise> exercises;

  const DailyChallengePlan({
    required this.focus,
    required this.exercises,
  });

  String get categoryLabel => 'Daily Challenge';
}

class DailyChallengeExerciseBuilder {
  static const int targetExerciseCount = 10;
  static const int _weakFocusCount = 8;
  static const int _progressReviewCount = 2;
  static const int _latestProgressCount = 5;
  static const int _recentProgressWindow = 5;

  static DailyChallengePlan? build({
    required DailySummary summary,
    required List<Exercise> allExercises,
    List<Exercise> recentProgressExercises = const <Exercise>[],
    List<Exercise> latestProgressExercises = const <Exercise>[],
  }) {
    if (allExercises.isEmpty) return null;

    final recentPool = _normalizedPool(
      recentProgressExercises.isNotEmpty ? recentProgressExercises : allExercises,
    );
    final latestPool = _normalizedPool(
      latestProgressExercises.isNotEmpty ? latestProgressExercises : recentPool,
    );

    final focus = summary.needsAttention;
    if (focus != null && focus.character.trim().isNotEmpty) {
      final weakMatches = _matchingExercises(
        target: focus,
        allExercises: allExercises,
      );

      if (weakMatches.isNotEmpty) {
        return DailyChallengePlan(
          focus: focus,
          exercises: _buildWeakFocusPlan(
            target: focus,
            weakMatches: weakMatches,
            progressPool: recentPool,
          ),
        );
      }
    }

    final fallback = _buildProgressFallbackPlan(
      latestPool: latestPool,
      recentPool: recentPool,
      allExercises: allExercises,
    );
    if (fallback.isEmpty) return null;

    return DailyChallengePlan(
      focus: null,
      exercises: fallback,
    );
  }

  static List<Exercise> _buildWeakFocusPlan({
    required DailyCharacterPerformance target,
    required List<Exercise> weakMatches,
    required List<Exercise> progressPool,
  }) {
    final weakExercises = _fillFromPool(
      source: weakMatches,
      count: _weakFocusCount,
      seed: _seedForWeakTarget(target),
      targetOverride: target,
    );
    final reviewExercises = _fillFromPool(
      source: progressPool.isNotEmpty ? progressPool : weakMatches,
      count: _progressReviewCount,
      seed: _seedForReview(target),
    );

    final slots = List<Exercise?>.filled(targetExerciseCount, null);
    const reviewSlotIndexes = <int>[3, 7];

    var weakIndex = 0;
    var reviewIndex = 0;

    for (var i = 0; i < targetExerciseCount; i++) {
      if (reviewSlotIndexes.contains(i) && reviewIndex < reviewExercises.length) {
        slots[i] = reviewExercises[reviewIndex++];
      } else if (weakIndex < weakExercises.length) {
        slots[i] = weakExercises[weakIndex++];
      }
    }

    return _withRepeatSlots(slots.whereType<Exercise>().toList());
  }

  static List<Exercise> _buildProgressFallbackPlan({
    required List<Exercise> latestPool,
    required List<Exercise> recentPool,
    required List<Exercise> allExercises,
  }) {
    final primaryPool = _normalizedPool(
      latestPool.isNotEmpty
          ? latestPool
          : recentPool.isNotEmpty
          ? recentPool
          : allExercises,
    );
    final secondaryPool = _normalizedPool(
      recentPool.isNotEmpty ? recentPool : allExercises,
    );

    if (primaryPool.isEmpty || secondaryPool.isEmpty) {
      return const <Exercise>[];
    }

    final latestExercises = _fillFromPool(
      source: primaryPool,
      count: _latestProgressCount,
      seed: _seedForPool(primaryPool),
    );
    final mixedExercises = _fillFromPool(
      source: secondaryPool,
      count: targetExerciseCount - _latestProgressCount,
      seed: _seedForPool(secondaryPool) + 17,
    );

    final slots = List<Exercise?>.filled(targetExerciseCount, null);
    var latestIndex = 0;
    var mixedIndex = 0;

    for (var i = 0; i < targetExerciseCount; i++) {
      final shouldUseLatest = i.isEven;
      if (shouldUseLatest && latestIndex < latestExercises.length) {
        slots[i] = latestExercises[latestIndex++];
      } else if (mixedIndex < mixedExercises.length) {
        slots[i] = mixedExercises[mixedIndex++];
      } else if (latestIndex < latestExercises.length) {
        slots[i] = latestExercises[latestIndex++];
      }
    }

    return _withRepeatSlots(slots.whereType<Exercise>().toList());
  }

  static List<Exercise> _matchingExercises({
    required DailyCharacterPerformance target,
    required List<Exercise> allExercises,
  }) {
    final exact = allExercises
        .where((exercise) => _matchesTarget(exercise, target))
        .toList();
    if (exact.isNotEmpty) return exact;

    final normalizedType = (target.characterType ?? '').trim().toLowerCase();
    if (normalizedType.isEmpty) return const <Exercise>[];

    return allExercises
        .where(
          (exercise) =>
              (exercise.characterType ?? '').trim().toLowerCase() ==
              normalizedType,
        )
        .toList();
  }

  static List<Exercise> _fillFromPool({
    required List<Exercise> source,
    required int count,
    required int seed,
    DailyCharacterPerformance? targetOverride,
  }) {
    if (source.isEmpty || count <= 0) return const <Exercise>[];

    final shuffled = List<Exercise>.from(source)..shuffle(Random(seed));
    final output = <Exercise>[];
    for (var i = 0; i < count; i++) {
      final template = shuffled[i % shuffled.length];
      output.add(
        targetOverride == null
            ? template
            : template.copyWith(
                character: targetOverride.character,
                characterType:
                    targetOverride.characterType ?? template.characterType,
                mathOp: targetOverride.mathOp ?? template.mathOp,
              ),
      );
    }
    return output;
  }

  static List<Exercise> _withRepeatSlots(List<Exercise> source) {
    return source
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(repeatSlot: entry.key + 1))
        .toList();
  }

  static List<Exercise> _normalizedPool(List<Exercise> source) {
    if (source.isEmpty) return const <Exercise>[];

    final seen = <String>{};
    final output = <Exercise>[];
    for (final exercise in source) {
      final key =
          '${exercise.id}|${exercise.character}|${exercise.characterType ?? ''}|${exercise.mathOp ?? ''}';
      if (seen.add(key)) {
        output.add(exercise);
      }
    }
    return output;
  }

  static bool _matchesTarget(
    Exercise exercise,
    DailyCharacterPerformance target,
  ) {
    final exerciseType = (exercise.characterType ?? '').trim().toLowerCase();
    final targetType = (target.characterType ?? '').trim().toLowerCase();

    if (targetType.isNotEmpty &&
        exerciseType.isNotEmpty &&
        exerciseType != targetType) {
      return false;
    }

    if (_normalizedCharacter(exercise.character) ==
        _normalizedCharacter(target.character)) {
      return true;
    }

    if (exerciseType == 'math' || targetType == 'math') {
      return _normalizedMathToken(exercise.mathOp ?? exercise.character) ==
          _normalizedMathToken(target.mathOp ?? target.character);
    }

    return false;
  }

  static int _seedForWeakTarget(DailyCharacterPerformance target) {
    final raw =
        '${target.character}|${target.characterType ?? ''}|${target.mathOp ?? ''}';
    return raw.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  }

  static int _seedForReview(DailyCharacterPerformance target) {
    return _seedForWeakTarget(target) + 97;
  }

  static int _seedForPool(List<Exercise> source) {
    return source.fold<int>(
      source.length,
      (sum, exercise) =>
          sum +
          exercise.id +
          exercise.character.codeUnits.fold<int>(0, (a, b) => a + b),
    );
  }

  static String _normalizedCharacter(String value) {
    return value.trim().toLowerCase();
  }

  static String _normalizedMathToken(String value) {
    switch (value.trim().toLowerCase()) {
      case '+':
      case 'add':
      case 'math:add':
        return 'add';
      case '-':
      case 'sub':
      case 'math:sub':
        return 'sub';
      case '*':
      case 'x':
      case '\u00d7':
      case 'mul':
      case 'math:mul':
        return 'mul';
      case '/':
      case '\u00f7':
      case 'div':
      case 'math:div':
        return 'div';
      default:
        return value.trim().toLowerCase();
    }
  }

  static int get recentProgressWindow => _recentProgressWindow;
}
