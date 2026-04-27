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
  static Challenge generate(MiniGameModel game) {
    switch (game.displayType) {
      case 'math_equation':
        return _generateMathChallenge(game.config);
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

  /// Generates a random math equation where the answer fits
  /// within the configured digit constraints.
  static Challenge _generateMathChallenge(Map<String, dynamic>? config) {
    final maxDigits = (config?['max_answer_digits'] as int?) ?? 1;
    final allowDecimals = (config?['allow_decimals'] as bool?) ?? false;
    final ops = (config?['ops'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['+'];

    final maxAnswer = _maxForDigits(maxDigits);
    final op = ops[_rng.nextInt(ops.length)];

    if (allowDecimals) {
      return _generateDecimalMath(op, maxAnswer);
    } else {
      return _generateIntMath(op, maxAnswer);
    }
  }

  static int _maxForDigits(int digits) {
    // 1 digit -> 9, 2 digits -> 99, etc.
    int result = 0;
    for (int i = 0; i < digits; i++) {
      result = result * 10 + 9;
    }
    return result == 0 ? 9 : result;
  }

  static Challenge _generateIntMath(String op, int maxAnswer) {
    int a, b, answer;

    switch (op) {
      case '-':
        // Ensure a >= b so result >= 0
        a = _rng.nextInt(maxAnswer + 1);
        b = _rng.nextInt(a + 1);
        answer = a - b;
        break;
      case '*':
        // Keep factors small so answer fits within maxAnswer
        final maxFactor = (maxAnswer > 9) ? 9 : maxAnswer;
        a = _rng.nextInt(maxFactor + 1);
        b = a == 0 ? 0 : _rng.nextInt((maxAnswer ~/ a).clamp(0, maxFactor) + 1);
        answer = a * b;
        break;
      case '+':
      default:
        a = _rng.nextInt(maxAnswer + 1);
        b = _rng.nextInt(maxAnswer + 1 - a);
        answer = a + b;
        break;
    }

    return Challenge(
      display: '$a $op $b = ?',
      target: answer.toString(),
    );
  }

  static Challenge _generateDecimalMath(String op, int maxAnswer) {
    // Generate with one decimal place
    double a = (_rng.nextInt(maxAnswer * 10) / 10.0);
    double b;
    double answer;

    switch (op) {
      case '-':
        b = (_rng.nextInt((a * 10).toInt() + 1)) / 10.0;
        answer = double.parse((a - b).toStringAsFixed(1));
        break;
      case '+':
      default:
        final remaining = maxAnswer - a;
        b = (_rng.nextInt((remaining * 10).toInt().clamp(0, maxAnswer * 10) + 1)) /
            10.0;
        answer = double.parse((a + b).toStringAsFixed(1));
        break;
    }

    final aStr = a == a.roundToDouble() ? a.toInt().toString() : a.toStringAsFixed(1);
    final bStr = b == b.roundToDouble() ? b.toInt().toString() : b.toStringAsFixed(1);
    final ansStr =
        answer == answer.roundToDouble() ? answer.toInt().toString() : answer.toStringAsFixed(1);

    return Challenge(
      display: '$aStr $op $bStr = ?',
      target: ansStr,
    );
  }
}
