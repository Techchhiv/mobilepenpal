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
    final bStr = b < 0 ? '($b)' : '$b';
    final s = '$a $op $bStr';
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
    switch (difficulty) {
      case MathDifficulty.easy:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (a + b > 9) return null;
        break;
      case MathDifficulty.medium:
        a = _nextIntInclusive(min, 99);
        b = _nextIntInclusive(min, 99);
        if (a + b > 99) return null;
        break;
      case MathDifficulty.hard:
        a = _nextIntInclusive(10, 99);
        b = _nextIntInclusive(10, 99);
        if (_rand.nextBool()) a = -a;
        if (_rand.nextBool()) b = -b;
        final ansAbs = (a + b).abs();
        if (ansAbs < 10 || ansAbs > 99) return null;
        break;
    }

    final ans = a + b;
    return MathQuestion(a: a, b: b, op: '+', opKey: 'add', answer: ans);
  }

  MathQuestion? _genSub({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final min = allowZero ? 0 : 1;
    int a, b;
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
        a = _nextIntInclusive(min, 99);
        b = _nextIntInclusive(min, 99);
        if (b > a) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        break;
      case MathDifficulty.hard:
        a = _nextIntInclusive(10, 99);
        b = _nextIntInclusive(10, 99);
        if (_rand.nextBool()) a = -a;
        if (_rand.nextBool()) b = -b;
        final ansAbs = (a - b).abs();
        if (ansAbs < 10 || ansAbs > 99) return null;
        break;
    }

    final ans = a - b;
    return MathQuestion(a: a, b: b, op: '-', opKey: 'sub', answer: ans);
  }

  MathQuestion? _genMul({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final min = allowZero ? 0 : 1;
    int a, b;
    switch (difficulty) {
      case MathDifficulty.easy:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 9);
        if (a * b > 9) return null;
        break;
      case MathDifficulty.medium:
        a = _nextIntInclusive(min, 9);
        b = _nextIntInclusive(min, 99);
        if (a * b > 99) return null;
        break;
      case MathDifficulty.hard:
        a = _nextIntInclusive(10, 99);
        b = _nextIntInclusive(10, 99);
        if (_rand.nextBool()) a = -a;
        if (_rand.nextBool()) b = -b;
        final ansAbs = (a * b).abs();
        if (ansAbs < 10 || ansAbs > 99) return null;
        break;
    }

    final ans = a * b;
    return MathQuestion(a: a, b: b, op: '×', opKey: 'mul', answer: ans);
  }

  MathQuestion? _genDiv({required MathDifficulty difficulty}) {
    int d, qMax, q;
    switch (difficulty) {
      case MathDifficulty.easy:
        d = _nextIntInclusive(1, 9);
        qMax = (9 / d).floor();
        q = _nextIntInclusive(0, qMax);
        break;
      case MathDifficulty.medium:
        d = _nextIntInclusive(1, 99);
        q = _nextIntInclusive(0, 99);
        if (d * q > 99) return null;
        break;
      case MathDifficulty.hard:
        d = _nextIntInclusive(10, 99);
        q = _nextIntInclusive(10, 99);
        if (_rand.nextBool()) d = -d;
        if (_rand.nextBool()) q = -q;
        final aAbs = (d * q).abs();
        if (aAbs < 10 || aAbs > 99) {
          return null;
        }
        break;
    }

    final a = d * q;
    return MathQuestion(a: a, b: d, op: '÷', opKey: 'div', answer: q);
  }

  int _nextIntInclusive(int min, int max) {
    if (max < min) return min;
    return min + _rand.nextInt(max - min + 1);
  }
}
