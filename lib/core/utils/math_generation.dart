import 'dart:math';

enum MathDifficulty { easy, medium, hard }

MathDifficulty parseMathDifficulty(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  switch (v) {
    case 'hard':
      return MathDifficulty.hard;
    case 'medium':
      return MathDifficulty.medium;
    case 'easy':
    default:
      return MathDifficulty.easy;
  }
}

class MathQuestion {
  final int a;
  final int b;

  /// Symbol for UI: + - × ÷
  final String op;

  /// For backend summary: add | sub | mul | div
  final String opKey;

  final int answer;

  const MathQuestion({
    required this.a,
    required this.b,
    required this.op,
    required this.opKey,
    required this.answer,
  });

  String toPrompt({bool withQuestionMark = false}) {
    final s = '$a $op $b';
    return withQuestionMark ? '$s = ?' : s;
  }

  String toToken() => '$a/$opKey/$b';
}

class MathGenerator {
  final Random _rand;

  MathGenerator({int? seed}) : _rand = Random(seed);

  static String normalizeOp(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'add':
      case '+':
        return 'add';
      case 'sub':
      case '-':
        return 'sub';
      case 'mul':
      case '*':
      case 'x':
      case '×':
        return 'mul';
      case 'div':
      case '/':
      case '÷':
        return 'div';
      default:
        return 'add';
    }
  }

  MathQuestion generate({
    required MathDifficulty difficulty,
    String? opKeyRaw,
    bool allowZero = true,
    int maxTries = 300,
  }) {
    final forcedOp = (opKeyRaw == null || opKeyRaw.trim().isEmpty)
        ? null
        : normalizeOp(opKeyRaw);

    if (forcedOp != null) {
      return _generateFromOps(
        ops: [forcedOp],
        allowZero: allowZero,
        maxTries: maxTries,
        forceOneDigitAnswer: difficulty != MathDifficulty.hard,
      );
    }

    switch (difficulty) {
      case MathDifficulty.easy:
        return _generateFromOps(
          ops: const ['add', 'sub'],
          allowZero: allowZero,
          maxTries: maxTries,
          forceOneDigitAnswer: true,
        );

      case MathDifficulty.medium:
        return _generateFromOps(
          ops: const ['mul', 'div'],
          allowZero: allowZero,
          maxTries: maxTries,
          forceOneDigitAnswer: true,
        );

      case MathDifficulty.hard:
        return _generateFromOps(
          ops: const ['add', 'sub', 'mul', 'div'],
          allowZero: allowZero,
          maxTries: maxTries,
          forceOneDigitAnswer: false,
        );
    }
  }

  MathQuestion _generateFromOps({
    required List<String> ops,
    required bool allowZero,
    required int maxTries,
    required bool forceOneDigitAnswer,
  }) {
    for (int i = 0; i < maxTries; i++) {
      final opKey = ops[_rand.nextInt(ops.length)];

      final q = switch (opKey) {
        'add' => _genAdd(
            allowZero: allowZero,
            forceOneDigitAnswer: forceOneDigitAnswer,
          ),
        'sub' => _genSub(allowZero: allowZero),
        'mul' => _genMul(
            allowZero: allowZero,
            forceOneDigitAnswer: forceOneDigitAnswer,
          ),
        'div' => _genDiv(),
        _ => null,
      };

      if (q != null) return q;
    }

    return const MathQuestion(a: 1, b: 1, op: '+', opKey: 'add', answer: 2);
  }

  MathQuestion? _genAdd({
    required bool allowZero,
    required bool forceOneDigitAnswer,
  }) {
    final min = allowZero ? 0 : 1;
    final a = _nextIntInclusive(min, 9);
    final b = _nextIntInclusive(min, 9);
    final ans = a + b;

    if (forceOneDigitAnswer && ans > 9) return null;

    return MathQuestion(a: a, b: b, op: '+', opKey: 'add', answer: ans);
  }

  MathQuestion? _genSub({required bool allowZero}) {
    final min = allowZero ? 0 : 1;
    var a = _nextIntInclusive(min, 9);
    var b = _nextIntInclusive(min, 9);

    if (b > a) {
      final tmp = a;
      a = b;
      b = tmp;
    }

    final ans = a - b;
    return MathQuestion(a: a, b: b, op: '-', opKey: 'sub', answer: ans);
  }

  MathQuestion? _genMul({
    required bool allowZero,
    required bool forceOneDigitAnswer,
  }) {
    final min = allowZero ? 0 : 1;
    final a = _nextIntInclusive(min, 9);
    final b = _nextIntInclusive(min, 9);
    final ans = a * b;

    if (forceOneDigitAnswer && ans > 9) return null;

    return MathQuestion(a: a, b: b, op: '×', opKey: 'mul', answer: ans);
  }

  MathQuestion? _genDiv() {
    final d = _nextIntInclusive(1, 9);
    final qMax = (9 / d).floor(); // ensures a<=9
    final q = _nextIntInclusive(0, qMax);
    final a = d * q;

    return MathQuestion(a: a, b: d, op: '÷', opKey: 'div', answer: q);
  }

  int _nextIntInclusive(int min, int max) {
    if (max < min) return min;
    return min + _rand.nextInt(max - min + 1);
  }
}
