import 'dart:math';

enum MathDifficulty { easy, medium, hard, veryHard }

MathDifficulty parseMathDifficulty(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  switch (v) {
    case 'very_hard':
      return MathDifficulty.veryHard;
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
  final int? missingOperandIndex;

  const MathQuestion({
    required this.a,
    required this.b,
    required this.op,
    required this.opKey,
    required this.answer,
    this.missingOperandIndex,
  });

  String toPrompt({bool withQuestionMark = false}) {
    if (missingOperandIndex == 0) {
      final bStr = b < 0 ? '($b)' : '$b';
      return '? $op $bStr = $answer';
    } else if (missingOperandIndex == 1) {
      final aStr = a < 0 ? '($a)' : '$a';
      return '$aStr $op ? = $answer';
    } else {
      final bStr = b < 0 ? '($b)' : '$b';
      final s = '$a $op $bStr';
      return withQuestionMark ? '$s = ?' : s;
    }
  }

  int get expectedAnswer {
    if (missingOperandIndex == 0) return a;
    if (missingOperandIndex == 1) return b;
    return answer;
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

    List<String> ops;
    if (forcedOp != null) {
      ops = [forcedOp];
    } else {
      switch (difficulty) {
        case MathDifficulty.easy:
          ops = const ['add', 'sub'];
          break;
        case MathDifficulty.medium:
          ops = const ['mul', 'div'];
          break;
        case MathDifficulty.hard:
        case MathDifficulty.veryHard:
          ops = const ['add', 'sub', 'mul', 'div'];
          break;
      }
    }

    return _generateFromOps(
      ops: ops,
      allowZero: allowZero,
      maxTries: maxTries,
      difficulty: difficulty,
    );
  }

  MathQuestion _generateFromOps({
    required List<String> ops,
    required bool allowZero,
    required int maxTries,
    required MathDifficulty difficulty,
  }) {
    for (int i = 0; i < maxTries; i++) {
      final opKey = ops[_rand.nextInt(ops.length)];

      final q = switch (opKey) {
        'add' => _genAdd(allowZero: allowZero, difficulty: difficulty),
        'sub' => _genSub(allowZero: allowZero, difficulty: difficulty),
        'mul' => _genMul(allowZero: allowZero, difficulty: difficulty),
        'div' => _genDiv(difficulty: difficulty),
        _ => null,
      };

      if (q != null) return q;
    }

    return const MathQuestion(a: 1, b: 1, op: '+', opKey: 'add', answer: 2);
  }

  MathQuestion? _genAdd({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final min = allowZero ? 0 : 1;
    int a, b;
    int? missing;
    switch (difficulty) {
      case MathDifficulty.easy:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (a + b > 9) return null;
        break;
      case MathDifficulty.medium:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        break;
      case MathDifficulty.hard:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        missing = _rand.nextBool() ? 0 : 1;
        break;
      case MathDifficulty.veryHard:
        a = _nextIntInclusive(10, 99);
        b = _nextIntInclusive(10, 99);
        missing = _rand.nextBool() ? 0 : 1;
        break;
    }

    final ans = a + b;
    return MathQuestion(
      a: a,
      b: b,
      op: '+',
      opKey: 'add',
      answer: ans,
      missingOperandIndex: missing,
    );
  }

  MathQuestion? _genSub({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final min = allowZero ? 0 : 1;
    int a, b;
    int? missing;
    switch (difficulty) {
      case MathDifficulty.easy:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (b > a) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        break;
      case MathDifficulty.medium:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (a - b < -9) return null;
        break;
      case MathDifficulty.hard:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        missing = _rand.nextBool() ? 0 : 1;
        if (a - b < -9) return null;
        break;
      case MathDifficulty.veryHard:
        a = _nextIntInclusive(10, 99);
        b = _nextIntInclusive(10, 99);
        missing = _rand.nextBool() ? 0 : 1;
        if (a - b < -9) return null;
        break;
    }

    final ans = a - b;
    return MathQuestion(
      a: a,
      b: b,
      op: '-',
      opKey: 'sub',
      answer: ans,
      missingOperandIndex: missing,
    );
  }

  MathQuestion? _genMul({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final min = allowZero ? 0 : 1;
    int a, b;
    int? missing;
    switch (difficulty) {
      case MathDifficulty.easy:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (a * b > 9) return null;
        break;
      case MathDifficulty.medium:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        break;
      case MathDifficulty.hard:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (a == 0 || b == 0) return null;
        missing = _rand.nextBool() ? 0 : 1;
        break;
      case MathDifficulty.veryHard:
        a = _nextIntInclusive(10, 99);
        b = _nextIntInclusive(10, 99);
        // Avoid `0 * ? = 0` or `? * 0 = 0` which has infinite answers
        if (a == 0 || b == 0) return null;
        missing = _rand.nextBool() ? 0 : 1;
        break;
    }

    final ans = a * b;
    return MathQuestion(
      a: a,
      b: b,
      op: '×',
      opKey: 'mul',
      answer: ans,
      missingOperandIndex: missing,
    );
  }

  MathQuestion? _genDiv({required MathDifficulty difficulty}) {
    int d, qMax, q;
    int? missing;
    switch (difficulty) {
      case MathDifficulty.easy:
        d = _nextIntInclusive(1, 9);
        qMax = (9 / d).floor();
        q = _nextIntInclusive(0, qMax);
        break;
      case MathDifficulty.medium:
        d = _nextIntInclusive(1, 9);
        q = _nextIntInclusive(0, 9);
        break;
      case MathDifficulty.hard:
        d = _nextIntInclusive(1, 9);
        q = _nextIntInclusive(1, 9);
        missing = _rand.nextBool() ? 0 : 1;
        break;
      case MathDifficulty.veryHard:
        d = _nextIntInclusive(10, 99);
        q = _nextIntInclusive(10, 99);
        missing = _rand.nextBool() ? 0 : 1;
        break;
    }

    final a = d * q;
    return MathQuestion(
      a: a,
      b: d,
      op: '÷',
      opKey: 'div',
      answer: q,
      missingOperandIndex: missing,
    );
  }

  int _nextIntInclusive(int min, int max) {
    if (max < min) return min;
    return min + _rand.nextInt(max - min + 1);
  }
}
