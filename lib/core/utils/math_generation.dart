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
    final minVal = allowZero ? 0 : 1;
    final maxVal = (difficulty == MathDifficulty.easy || difficulty == MathDifficulty.hard) ? 4 : 9;
    
    int? missing;
    if (difficulty == MathDifficulty.hard || difficulty == MathDifficulty.veryHard) {
      missing = _rand.nextBool() ? 0 : 1;
    }

    final a = _nextIntInclusive(minVal, maxVal);
    final b = _nextIntInclusive(minVal, maxVal - a);

    return MathQuestion(
      a: a,
      b: b,
      op: '+',
      opKey: 'add',
      answer: a + b,
      missingOperandIndex: missing,
    );
  }

  MathQuestion? _genSub({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final minVal = allowZero ? 0 : 1;
    final maxVal = (difficulty == MathDifficulty.easy || difficulty == MathDifficulty.hard) ? 4 : 9;
    
    int? missing;
    if (difficulty == MathDifficulty.hard || difficulty == MathDifficulty.veryHard) {
      missing = _rand.nextBool() ? 0 : 1;
    }

    final a = _nextIntInclusive(minVal, maxVal);
    final b = _nextIntInclusive(minVal, a);

    return MathQuestion(
      a: a,
      b: b,
      op: '-',
      opKey: 'sub',
      answer: a - b,
      missingOperandIndex: missing,
    );
  }

  MathQuestion? _genMul({
    required bool allowZero,
    required MathDifficulty difficulty,
  }) {
    final minVal = allowZero ? 0 : 1;
    final maxVal = (difficulty == MathDifficulty.easy || difficulty == MathDifficulty.hard) ? 4 : 9;
    
    int? missing;
    if (difficulty == MathDifficulty.hard || difficulty == MathDifficulty.veryHard) {
      missing = _rand.nextBool() ? 0 : 1;
    }

    int a = _nextIntInclusive(minVal, maxVal);
    if (missing != null && a == 0) {
      a = _nextIntInclusive(1, maxVal);
    }
    
    final maxB = a == 0 ? maxVal : (maxVal ~/ a);
    if (maxB < minVal) return null;
    
    int b = _nextIntInclusive(minVal, maxB);
    if (missing != null && b == 0) {
      if (maxB < 1) return null;
      b = _nextIntInclusive(1, maxB);
    }

    return MathQuestion(
      a: a,
      b: b,
      op: '×',
      opKey: 'mul',
      answer: a * b,
      missingOperandIndex: missing,
    );
  }

  MathQuestion? _genDiv({required MathDifficulty difficulty}) {
    final maxVal = (difficulty == MathDifficulty.easy || difficulty == MathDifficulty.hard) ? 4 : 9;
    
    int? missing;
    if (difficulty == MathDifficulty.hard || difficulty == MathDifficulty.veryHard) {
      missing = _rand.nextBool() ? 0 : 1;
    }

    final b = _nextIntInclusive(1, maxVal);
    final maxQ = maxVal ~/ b;
    final minQ = (missing == 1) ? 1 : 0;
    
    if (maxQ < minQ) return null;
    final q = _nextIntInclusive(minQ, maxQ);
    
    final a = b * q;

    return MathQuestion(
      a: a,
      b: b,
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
