import 'dart:math';

import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';

/// Represents a single challenge presented to the user.
class Challenge {
  /// What to display on screen (e.g. "ក", "5", "2 + 3 = ?")
  final String display;

  /// The expected answer the user should draw/select (e.g. "ក", "5")
  final String target;

  Challenge({required this.display, required this.target});
}

/// Generates challenges based on the mini-game configuration.
class ChallengeGenerator {
  static final Random _rng = Random();

  /// Generate a random challenge from the given mini-game config.
  /// [difficulty] controls the complexity of the generated challenge.
  static Challenge generate(
    MiniGameModel game, {
    MiniGameDifficulty difficulty = MiniGameDifficulty.easy,
  }) {
    switch (game.displayType) {
      case 'math_equation':
        return _generateMathChallenge(game.config, difficulty);
      case 'character':
      case 'letter':
      case 'number':
      case 'text':
      case 'image':
      default:
        return _generatePoolChallenge(game.config);
    }
  }

  /// Picks a random item from the pool.
  static Challenge _generatePoolChallenge(Map<String, dynamic>? config) {
    final pool = (config?['pool'] as List<dynamic>?) ?? [];
    if (pool.isEmpty) {
      return Challenge(display: '?', target: '?');
    }
    final item = pool[_rng.nextInt(pool.length)].toString();
    return Challenge(display: item, target: item);
  }

  // ── Math Challenge (Kindergarten Friendly, 1-digit answers) ──────

  /// Generates a kindergarten-friendly math challenge.
  ///
  /// - **Easy**: Addition only, sum ≤ 5.
  /// - **Medium**: Addition or subtraction, result 0–9.
  /// - **Hard**: "Missing number" problems, result 0–9.
  static Challenge _generateMathChallenge(
    Map<String, dynamic>? config,
    MiniGameDifficulty difficulty,
  ) {
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        return _mathEasy();
      case MiniGameDifficulty.medium:
        return _mathMedium();
      case MiniGameDifficulty.hard:
        return _mathHard();
    }
  }

  /// Easy: addition only, sum ≤ 5.
  static Challenge _mathEasy() {
    final a = _rng.nextInt(6); // 0..5
    final b = _rng.nextInt(6 - a); // ensures a+b ≤ 5
    final answer = a + b;
    return Challenge(
      display: '$a + $b = ?',
      target: answer.toString(),
    );
  }

  /// Medium: addition or subtraction, result 0–9.
  static Challenge _mathMedium() {
    final isAdd = _rng.nextBool();
    if (isAdd) {
      final a = _rng.nextInt(10); // 0..9
      final b = _rng.nextInt(10 - a); // ensures a+b ≤ 9
      final answer = a + b;
      return Challenge(
        display: '$a + $b = ?',
        target: answer.toString(),
      );
    } else {
      final a = _rng.nextInt(10); // 0..9
      final b = _rng.nextInt(a + 1); // ensures a-b ≥ 0
      final answer = a - b;
      return Challenge(
        display: '$a - $b = ?',
        target: answer.toString(),
      );
    }
  }

  /// Hard: "Missing number" problems, result 0–9.
  /// e.g. "2 + ? = 5" or "? - 1 = 4"
  static Challenge _mathHard() {
    final isAdd = _rng.nextBool();
    final missingFirst = _rng.nextBool(); // which operand is missing

    if (isAdd) {
      // a + b = sum, where sum ≤ 9
      final sum = _rng.nextInt(10); // 0..9
      final a = _rng.nextInt(sum + 1);
      final b = sum - a;

      if (missingFirst) {
        // ? + b = sum  →  answer = a
        return Challenge(
          display: '? + $b = $sum',
          target: a.toString(),
        );
      } else {
        // a + ? = sum  →  answer = b
        return Challenge(
          display: '$a + ? = $sum',
          target: b.toString(),
        );
      }
    } else {
      // a - b = diff, where a ≤ 9 and diff ≥ 0
      final a = _rng.nextInt(10); // 0..9
      final b = _rng.nextInt(a + 1);
      final diff = a - b;

      if (missingFirst) {
        // ? - b = diff  →  answer = a
        return Challenge(
          display: '? - $b = $diff',
          target: a.toString(),
        );
      } else {
        // a - ? = diff  →  answer = b
        return Challenge(
          display: '$a - ? = $diff',
          target: b.toString(),
        );
      }
    }
  }

  // ── Multiple-choice distractor generation ────────────────────────

  /// Number of options to show based on difficulty.
  static int optionCount(MiniGameDifficulty difficulty) {
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        return 4;
      case MiniGameDifficulty.medium:
        return 6;
      case MiniGameDifficulty.hard:
        return 8;
    }
  }

  /// Visually similar Khmer characters grouped by shape resemblance.
  /// Used to generate confusing distractors on Medium & Hard.
  static const Map<String, List<String>> _khmerSimilarMap = {
    // Consonants
    'ក': ['ខ', 'គ', 'ឃ'],
    'ខ': ['ក', 'គ', 'ឃ'],
    'គ': ['ក', 'ខ', 'ឃ'],
    'ឃ': ['ក', 'ខ', 'គ'],
    'ង': ['ឯ', 'ញ'],
    'ច': ['ជ', 'ឆ'],
    'ឆ': ['ច', 'ជ'],
    'ជ': ['ច', 'ឆ'],
    'ញ': ['ង', 'ឯ'],
    'ដ': ['ឋ', 'ឌ'],
    'ឋ': ['ដ', 'ឌ'],
    'ឌ': ['ដ', 'ឋ'],
    'ណ': ['ន'],
    'ត': ['រ', 'ថ'],
    'ថ': ['ត', 'ផ', 'រ'],
    'ទ': ['ធ'],
    'ធ': ['ទ'],
    'ន': ['ណ'],
    'ប': ['ព', 'ហ'],
    'ផ': ['ថ', 'ព'],
    'ព': ['ប', 'ផ'],
    'ម': ['org'],
    'យ': ['រ'],
    'រ': ['ត', 'យ'],
    'ល': ['ឡ'],
    'វ': ['org'],
    'ស': ['org'],
    'ហ': ['ប'],
    'ឡ': ['ល'],
    'អ': ['org'],
    // Independent vowels
    'ឥ': ['ឦ'],
    'ឦ': ['ឥ'],
    'ឧ': ['ឩ', 'ឪ'],
    'ឩ': ['ឧ', 'ឪ'],
    'ឪ': ['ឧ', 'ឩ'],
    'ឫ': ['ឬ'],
    'ឬ': ['ឫ'],
    'ឭ': ['ឮ'],
    'ឮ': ['ឭ'],
    'ឯ': ['ង', 'ញ'],
    'ឱ': ['ឲ'],
    'ឲ': ['ឱ'],
    // Digits
    '០': ['៩'],
    '១': ['org'],
    '២': ['org'],
    '៣': ['org'],
    '៤': ['org'],
    '៥': ['org'],
    '៦': ['org'],
    '៧': ['org'],
    '៨': ['org'],
    '៩': ['០'],
  };

  /// Generate a list of options that includes the correct [target]
  /// plus distractors drawn from [pool].
  ///
  /// - **Easy**: random distractors from pool.
  /// - **Medium**: visually similar distractors + near numerics.
  /// - **Hard**: more visually similar distractors + near numerics.
  static List<String> generateOptions({
    required String target,
    required List<String> pool,
    required MiniGameDifficulty difficulty,
    Map<String, List<String>>? similarMap,
  }) {
    final count = optionCount(difficulty);
    final options = <String>{target};

    // Merge caller-provided map with built-in map
    final effectiveMap = <String, List<String>>{
      ..._khmerSimilarMap,
      if (similarMap != null) ...similarMap,
    };

    // 1. For medium/hard add "near" distractors when target is numeric
    if (difficulty != MiniGameDifficulty.easy) {
      final numTarget = int.tryParse(target);
      if (numTarget != null) {
        for (final delta in [1, -1, 2, -2]) {
          final near = numTarget + delta;
          if (near >= 0 && near <= 9) {
            options.add(near.toString());
          }
          if (options.length >= count) break;
        }
      }
    }

    // 2. For medium AND hard, add visually similar characters
    if (difficulty != MiniGameDifficulty.easy) {
      final similars = effectiveMap[target]
          ?.where((s) => s != 'org' && pool.contains(s))
          .toList();
      if (similars != null && similars.isNotEmpty) {
        similars.shuffle(_rng);
        // Medium: add up to 2 similar, Hard: add up to 4 similar
        final maxSimilar = difficulty == MiniGameDifficulty.hard ? 4 : 2;
        for (final s in similars) {
          if (options.length >= count) break;
          if (options.length - 1 >= maxSimilar) break;
          options.add(s);
        }
      }
    }

    // 3. Fill remaining from pool (shuffled)
    final shuffledPool = List<String>.from(pool)..shuffle(_rng);
    for (final item in shuffledPool) {
      if (options.length >= count) break;
      options.add(item);
    }

    // 4. Fallback: if pool was too small to reach count, pull from all known characters
    if (options.length < count) {
      final fallbackPool = effectiveMap.keys.toList()..shuffle(_rng);
      for (final item in fallbackPool) {
        if (options.length >= count) break;
        if (item != 'org') {
          options.add(item);
        }
      }
    }

    // Shuffle the final list so the correct answer isn't always first
    final result = options.toList()..shuffle(_rng);
    return result;
  }
}
