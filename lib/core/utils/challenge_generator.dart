import 'dart:math';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/data/models/mini_game/question_template_model.dart';

/// Represents a single challenge presented to the user.
class Challenge {
  /// What to display on screen (e.g. "ក", "5", "2 + 3 = ?")
  final String display;

  /// The expected answer the user should draw/select (e.g. "ក", "5")
  final String target;

  // ── Optional metadata for special display types ──

  /// For `object_count` display: list of emoji strings to show.
  final List<String>? objectEmojis;

  /// For `missing_character` display: full word with blank placeholder.
  final String? wordWithBlank;

  /// For `missing_character` display: the complete word (for image/audio hint).
  final String? fullWord;

  /// For `missing_character` display: path to the image hint.
  final String? imagePath;

  /// For `math_equation` display: fruit image path used to visually
  /// represent numbers (e.g. show 3 apples + 2 apples).
  final String? fruitImage;

  /// For `math_equation` display: operand values for fruit rendering.
  final int? operandA;
  final int? operandB;
  final String? operator;

  /// For `word_problem` display: the full problem text shown to the user.
  final String? wordProblemText;

  /// For `word_problem` display: the fruit image used in the story.
  final String? wordProblemFruitImage;

  Challenge({
    required this.display,
    required this.target,
    this.objectEmojis,
    this.wordWithBlank,
    this.fullWord,
    this.imagePath,
    this.fruitImage,
    this.operandA,
    this.operandB,
    this.operator,
    this.wordProblemText,
    this.wordProblemFruitImage,
  });
}

/// Represents a single pair for drag-and-drop matching.
class DragMatchPair {
  final String id;
  final String source; // The character / number shown on left
  final String target; // The label / emoji shown on right
  final String? hint; // Optional meaning text
  bool matched;

  DragMatchPair({
    required this.id,
    required this.source,
    required this.target,
    this.hint,
    this.matched = false,
  });
}

/// Generates challenges based on the mini-game configuration.
class ChallengeGenerator {
  static final Random _rng = Random();

  // ── Question templates fetched from the backend ──────────────────
  static List<QuestionTemplateModel> _questionTemplates = [];

  /// Sets the bilingual question templates used by `_generateQuestionChallenge`.
  /// Should be called once during game initialization.
  static void setQuestionTemplates(List<QuestionTemplateModel> templates) {
    _questionTemplates = templates;
  }

  /// Generate a random challenge from the given mini-game config.
  /// [difficulty] controls the complexity of the generated challenge.
  /// [locale] controls the language for question text ('en' or 'kh').
  static Challenge generate(
    MiniGameModel game, {
    MiniGameDifficulty difficulty = MiniGameDifficulty.easy,
    String locale = 'en',
  }) {
    switch (game.displayType) {
      case 'math_equation':
        return _generateMathChallenge(game.config, difficulty);
      case 'question':
        return _generateQuestionChallenge(game.config, difficulty, locale);
      case 'object_count':
        return _generateObjectCountChallenge(game.config, difficulty);
      case 'missing_character':
        return _generateMissingCharacterChallenge(game.config, difficulty);
      case 'character':
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

  // ── Fruit images for math displays ──────────────────────────────
  static const _fruitImages = [
    'assets/images/fruits/apple.png',
    'assets/images/fruits/orange.png',
    'assets/images/fruits/banana.png',
    'assets/images/fruits/strawberry.png',
    'assets/images/fruits/grape.png',
    'assets/images/fruits/watermelon.png',
  ];

  static String _randomFruit() =>
      _fruitImages[_rng.nextInt(_fruitImages.length)];

  // ── Math Challenge (Kindergarten Friendly, 1-digit answers) ──────

  /// Generates a kindergarten-friendly math challenge.
  ///
  /// - **Easy**: Addition and subtraction, result 0–9.
  /// - **Medium**: Multiplication and division, result 0–9.
  /// - **Hard**: "Missing number" problems (all four operations), result 0–9.
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

  /// Easy: addition AND subtraction, result 0–9.
  static Challenge _mathEasy() {
    final fruit = _randomFruit();
    final isAdd = _rng.nextBool();
    if (isAdd) {
      final a = _rng.nextInt(10); // 0..9
      final b = _rng.nextInt(10 - a); // ensures a+b ≤ 9
      final answer = a + b;
      return Challenge(
        display: '$a + $b = ?',
        target: answer.toString(),
        fruitImage: fruit,
        operandA: a,
        operandB: b,
        operator: '+',
      );
    } else {
      final a = _rng.nextInt(10); // 0..9
      final b = _rng.nextInt(a + 1); // ensures a-b ≥ 0
      final answer = a - b;
      return Challenge(
        display: '$a - $b = ?',
        target: answer.toString(),
        fruitImage: fruit,
        operandA: a,
        operandB: b,
        operator: '-',
      );
    }
  }

  /// Medium: multiplication and division, result 0–9.
  static Challenge _mathMedium() {
    final fruit = _randomFruit();
    final isMul = _rng.nextBool();
    if (isMul) {
      // a × b, where a,b ∈ {0..9} and a*b ≤ 9
      // Pick small factors to keep results ≤ 9
      final a = 1 + _rng.nextInt(3); // 1..3
      final maxB = (9 ~/ a).clamp(0, 9);
      final b = _rng.nextInt(maxB + 1); // 0..maxB
      final answer = a * b;
      return Challenge(
        display: '$a × $b = ?',
        target: answer.toString(),
        fruitImage: fruit,
        operandA: a,
        operandB: b,
        operator: '×',
      );
    } else {
      // a ÷ b = answer, all ≤ 9, no remainder
      final answer = _rng.nextInt(10); // 0..9
      final b = 1 + _rng.nextInt(3); // 1..3 (divisor, never 0)
      final a = answer * b; // dividend
      return Challenge(
        display: '$a ÷ $b = ?',
        target: answer.toString(),
        fruitImage: fruit,
        operandA: a,
        operandB: b,
        operator: '÷',
      );
    }
  }

  /// Hard: "Missing number" problems using all four operations.
  /// e.g. "2 + ? = 5", "? × 3 = 6", "? - 1 = 4"
  static Challenge _mathHard() {
    final fruit = _randomFruit();
    // Pick random operation: 0=add, 1=sub, 2=mul, 3=div
    final opType = _rng.nextInt(4);
    final missingFirst = _rng.nextBool();

    switch (opType) {
      case 0: // Addition: a + b = sum
        final sum = _rng.nextInt(10);
        final a = _rng.nextInt(sum + 1);
        final b = sum - a;
        if (missingFirst) {
          return Challenge(
            display: '? + $b = $sum',
            target: a.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '+',
          );
        } else {
          return Challenge(
            display: '$a + ? = $sum',
            target: b.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '+',
          );
        }
      case 1: // Subtraction: a - b = diff
        final a = _rng.nextInt(10);
        final b = _rng.nextInt(a + 1);
        final diff = a - b;
        if (missingFirst) {
          return Challenge(
            display: '? - $b = $diff',
            target: a.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '-',
          );
        } else {
          return Challenge(
            display: '$a - ? = $diff',
            target: b.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '-',
          );
        }
      case 2: // Multiplication: a × b = product
        final a = 1 + _rng.nextInt(3);
        final maxB = (9 ~/ a).clamp(0, 9);
        final b = _rng.nextInt(maxB + 1);
        final product = a * b;
        if (missingFirst) {
          return Challenge(
            display: '? × $b = $product',
            target: a.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '×',
          );
        } else {
          return Challenge(
            display: '$a × ? = $product',
            target: b.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '×',
          );
        }
      default: // Division: a ÷ b = answer
        final answer = _rng.nextInt(10);
        final b = 1 + _rng.nextInt(3);
        final a = answer * b;
        if (missingFirst) {
          return Challenge(
            display: '? ÷ $b = $answer',
            target: a.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '÷',
          );
        } else {
          return Challenge(
            display: '$a ÷ ? = $answer',
            target: b.toString(),
            fruitImage: fruit,
            operandA: a,
            operandB: b,
            operator: '÷',
          );
        }
    }
  }

  // ── Question Challenge (Dynamic bilingual templates) ─────────────

  /// Fruit names and their localized variants for placeholder substitution.
  static const _fruitData = [
    {
      'en': 'apples',
      'kh': 'ផ្លែប៉ោម',
      'image': 'assets/images/fruits/apple.png',
    },
    {
      'en': 'oranges',
      'kh': 'ផ្លែក្រូច',
      'image': 'assets/images/fruits/orange.png',
    },
    {
      'en': 'bananas',
      'kh': 'ផ្លែចេក',
      'image': 'assets/images/fruits/banana.png',
    },
    {
      'en': 'strawberries',
      'kh': 'ផ្លែស្ត្របឺរី',
      'image': 'assets/images/fruits/strawberry.png',
    },
    {
      'en': 'grapes',
      'kh': 'ផ្លែទំពាំងបាយជូរ',
      'image': 'assets/images/fruits/grape.png',
    },
  ];

  /// Maps operation codes from the DB to difficulty-aware number ranges.
  static Map<String, int> _operandsForOperation(String operation) {
    switch (operation) {
      case 'add':
        final a = 1 + _rng.nextInt(5); // 1..5
        final b = 1 + _rng.nextInt(9 - a); // sum <= 9
        return {'a': a, 'b': b, 'answer': a + b};
      case 'sub':
        final a = 2 + _rng.nextInt(8); // 2..9
        final b = 1 + _rng.nextInt(a - 1); // a-b >= 1
        return {'a': a, 'b': b, 'answer': a - b};
      case 'mul':
        final a = 1 + _rng.nextInt(3); // 1..3
        final b = 1 + _rng.nextInt(4); // 1..4
        return {'a': a, 'b': b, 'answer': a * b};
      case 'div':
        final answer = 1 + _rng.nextInt(4);
        final b = 2 + _rng.nextInt(3);
        return {'a': answer * b, 'b': b, 'answer': answer};
      default:
        return {'a': 1, 'b': 1, 'answer': 2};
    }
  }

  static Challenge _generateQuestionChallenge(
    Map<String, dynamic>? config,
    MiniGameDifficulty difficulty,
    String locale,
  ) {
    // 1. Filter templates by difficulty
    final difficultyStr = difficulty == MiniGameDifficulty.easy
        ? 'easy'
        : difficulty == MiniGameDifficulty.medium
            ? 'medium'
            : 'hard';

    List<QuestionTemplateModel> pool = _questionTemplates
        .where((t) => t.difficulty == difficultyStr)
        .toList();

    // Fallback: if no templates for this difficulty, use all templates
    if (pool.isEmpty) pool = List.from(_questionTemplates);

    // Ultimate fallback: if no templates at all, use legacy hardcoded logic
    if (pool.isEmpty) {
      return _legacyQuestionFallback(config, difficulty);
    }

    // 2. Pick a random template
    final template = pool[_rng.nextInt(pool.length)];

    // 3. Generate random numbers for the operation
    final operands = _operandsForOperation(template.operation);
    final a = operands['a']!;
    final b = operands['b']!;
    final answer = operands['answer']!;

    // 4. Pick a random fruit
    final fruit = _fruitData[_rng.nextInt(_fruitData.length)];
    final fruitName = locale == 'kh' ? fruit['kh']! : fruit['en']!;
    final fruitImg = fruit['image']!;

    // 5. Choose template text based on locale
    final rawText = locale == 'kh' ? template.questionKh : template.questionEn;

    // 6. Substitute placeholders
    final aStr = locale == 'kh' ? NumberFormatUtils.digitsByLocale(a.toString(), forceKhmer: true) : a.toString();
    final bStr = locale == 'kh' ? NumberFormatUtils.digitsByLocale(b.toString(), forceKhmer: true) : b.toString();
    final questionText = rawText
        .replaceAll('{a}', aStr)
        .replaceAll('{b}', bStr)
        .replaceAll('{fruit}', fruitName);

    // 7. Determine the context-appropriate illustration
    String problemImage = fruitImg;
    final englishTextLower = template.questionEn.toLowerCase();
    final khmerTextLower = template.questionKh;

    if (englishTextLower.contains('bird') || khmerTextLower.contains('បក្សី')) {
      problemImage = 'assets/images/illustrations/bird.png';
    } else if (englishTextLower.contains('sticker') || khmerTextLower.contains('ស្ទីកឃ័រ')) {
      problemImage = 'assets/images/illustrations/sticker.png';
    } else if (englishTextLower.contains('balloon') || khmerTextLower.contains('បាឡុង')) {
      problemImage = 'assets/images/illustrations/balloon.png';
    } else if (englishTextLower.contains('egg') || khmerTextLower.contains('ស៊ុត')) {
      problemImage = 'assets/images/illustrations/egg.png';
    } else if (englishTextLower.contains('cookie') || khmerTextLower.contains('នំ')) {
      problemImage = 'assets/images/illustrations/cookie.png';
    } else if (englishTextLower.contains('jar') || khmerTextLower.contains('ក្រឡ')) {
      problemImage = 'assets/images/illustrations/jar.png';
    } else if (englishTextLower.contains('box') || khmerTextLower.contains('ប្រអប់')) {
      problemImage = 'assets/images/illustrations/box.png';
    } else if (englishTextLower.contains('pencil') || khmerTextLower.contains('ខ្មៅដៃ')) {
      problemImage = 'assets/images/illustrations/pencil.png';
    }

    return Challenge(
      display: questionText,
      target: answer.toString(),
      wordProblemText: questionText,
      wordProblemFruitImage: problemImage,
    );
  }

  /// Fallback for when no templates have been fetched from the backend.
  static Challenge _legacyQuestionFallback(
    Map<String, dynamic>? config,
    MiniGameDifficulty difficulty,
  ) {
    final fruit = _fruitData[_rng.nextInt(_fruitData.length)];
    final fruitName = fruit['en']!;
    final fruitImg = fruit['image']!;

    final a = 1 + _rng.nextInt(5);
    final b = 1 + _rng.nextInt(9 - a);
    final answer = a + b;

    final questionText =
        'I have $a $fruitName and get $b more. How many do I have now?';

    return Challenge(
      display: questionText,
      target: answer.toString(),
      wordProblemText: questionText,
      wordProblemFruitImage: fruitImg,
    );
  }

  // ── Object Count Challenge ───────────────────────────────────────

  /// Possible emojis for counting games.
  static const _countEmojis = ['🍎', '⭐', '🌸', '🦋', '🐟', '🌺', '🍊', '🎈'];

  /// Generates a challenge that shows a number of objects.
  ///
  /// - **Easy**: 1–5 objects in a neat line.
  /// - **Medium**: 1–9 objects scattered (display hint = 'scattered').
  /// - **Hard**: 1–9 objects that fade away (display hint = 'memory').
  static Challenge _generateObjectCountChallenge(
    Map<String, dynamic>? config,
    MiniGameDifficulty difficulty,
  ) {
    final emoji = _countEmojis[_rng.nextInt(_countEmojis.length)];
    int count;
    String displayHint;

    switch (difficulty) {
      case MiniGameDifficulty.easy:
        count = 1 + _rng.nextInt(5); // 1..5
        displayHint = 'neat';
        break;
      case MiniGameDifficulty.medium:
        count = 1 + _rng.nextInt(9); // 1..9
        displayHint = 'scattered';
        break;
      case MiniGameDifficulty.hard:
        count = 1 + _rng.nextInt(9); // 1..9
        displayHint = 'memory';
        break;
    }

    final emojis = List.generate(count, (_) => emoji);

    // The target is the Khmer digit for that count
    final khmerDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    final target = khmerDigits[count];

    return Challenge(
      display: displayHint, // UI uses this to decide layout
      target: target,
      objectEmojis: emojis,
    );
  }

  // ── Missing Character Challenge ──────────────────────────────────

  /// Sample Khmer words with their constituent characters.
  /// Each entry: [fullWord, missingCharIndex, missingChar]
  static const _khmerWords = [
    {
      'word': 'កុក',
      'missing': 'ក',
      'blank': '_ុក',
      'meaning': 'Egret',
      'image': 'assets/images/consonants/ក_កុក.png',
    },
    {
      'word': 'ខ្លា',
      'missing': 'ខ',
      'blank': '_្លា',
      'meaning': 'Tiger',
      'image': 'assets/images/consonants/ខ_ខ្លា.png',
    },
    {
      'word': 'គោ',
      'missing': 'គ',
      'blank': '_ោ',
      'meaning': 'Cow',
      'image': 'assets/images/consonants/គ_គោ.png',
    },
    {
      'word': 'ឃ្មុំ',
      'missing': 'ឃ',
      'blank': '_្មុំ',
      'meaning': 'Bee',
      'image': 'assets/images/consonants/ឃ_ឃ្មុំ.png',
    },
    {
      'word': 'ងាវ',
      'missing': 'ង',
      'blank': '_ាវ',
      'meaning': 'Clam',
      'image': 'assets/images/consonants/ង_ងាវ.png',
    },
    {
      'word': 'ចាប',
      'missing': 'ច',
      'blank': '_ាប',
      'meaning': 'Bird',
      'image': 'assets/images/consonants/ច_ចាប.png',
    },
    {
      'word': 'ឆ្មា',
      'missing': 'ឆ',
      'blank': '_្មា',
      'meaning': 'Cat',
      'image': 'assets/images/consonants/ឆ_ឆ្មា.png',
    },
    {
      'word': 'ជ្រូក',
      'missing': 'ជ',
      'blank': '_្រូក',
      'meaning': 'Pig',
      'image': 'assets/images/consonants/ជ_ជ្រុក.png',
    },
    {
      'word': 'ឈ្លូស',
      'missing': 'ឈ',
      'blank': '_្លូស',
      'meaning': 'Deer',
      'image': 'assets/images/consonants/ឈ_ឈ្លូស.png',
    },
    {
      'word': 'ញញួរ',
      'missing': 'ញ',
      'blank': '_ញួរ',
      'meaning': 'Hammer',
      'image': 'assets/images/consonants/ញ_ញញួរ.png',
    },
    {
      'word': 'ដំរី',
      'missing': 'ដ',
      'blank': '_ំរី',
      'meaning': 'Elephant',
      'image': 'assets/images/consonants/ដ_ដំរី.png',
    },
    {
      'word': 'ឍាមរ៉ា',
      'missing': 'ឍ',
      'blank': '_ាមរ៉ា',
      'meaning': 'Mallet',
      'image': 'assets/images/consonants/ឍ_ឍាមរ៉ា.png',
    },
    {
      'word': 'កណ្ដឹង',
      'missing': 'ណ',
      'blank': 'ក_្ដឹង',
      'meaning': 'Bell',
      'image': 'assets/images/consonants/ណ_កណ្ដឹង.png',
    },
    {
      'word': 'ត្រី',
      'missing': 'ត',
      'blank': '_្រី',
      'meaning': 'Fish',
      'image': 'assets/images/consonants/ត_ត្រី.png',
    },
    {
      'word': 'ថូ',
      'missing': 'ថ',
      'blank': '_ូ',
      'meaning': 'Vase',
      'image': 'assets/images/consonants/ថ_ថូ.png',
    },
    {
      'word': 'ទា',
      'missing': 'ទ',
      'blank': '_ា',
      'meaning': 'Duck',
      'image': 'assets/images/consonants/ទ_ទា.png',
    },
    {
      'word': 'ធុង',
      'missing': 'ធ',
      'blank': '_ុង',
      'meaning': 'Bucket',
      'image': 'assets/images/consonants/ធ_ធុង.png',
    },
    {
      'word': 'នាគ',
      'missing': 'ន',
      'blank': '_ាគ',
      'meaning': 'Dragon',
      'image': 'assets/images/consonants/ន_នាគ.png',
    },
    {
      'word': 'បាល់',
      'missing': 'ប',
      'blank': '_ាល់',
      'meaning': 'Ball',
      'image': 'assets/images/consonants/ប_បាល់.png',
    },
    {
      'word': 'ផ្កា',
      'missing': 'ផ',
      'blank': '_្កា',
      'meaning': 'Flower',
      'image': 'assets/images/consonants/ផ_ផ្កា.png',
    },
    {
      'word': 'ពពែ',
      'missing': 'ព',
      'blank': '_ពែ',
      'meaning': 'Goat',
      'image': 'assets/images/consonants/ព_ពពែ.png',
    },
    {
      'word': 'ភេ',
      'missing': 'ភ',
      'blank': '_េ',
      'meaning': 'Otter',
      'image': 'assets/images/consonants/ភ_ភេ.png',
    },
    {
      'word': 'មាន់',
      'missing': 'ម',
      'blank': '_ាន់',
      'meaning': 'Chicken',
      'image': 'assets/images/consonants/ម_មាន់.png',
    },
    {
      'word': 'យក្ស',
      'missing': 'យ',
      'blank': '_ក្ស',
      'meaning': 'Giant',
      'image': 'assets/images/consonants/យ_យក្ស.png',
    },
    {
      'word': 'រុយ',
      'missing': 'រ',
      'blank': '_ុយ',
      'meaning': 'Fly',
      'image': 'assets/images/consonants/រ_រុយ.png',
    },
    {
      'word': 'លា',
      'missing': 'ល',
      'blank': '_ា',
      'meaning': 'Donkey',
      'image': 'assets/images/consonants/ល_លា.png',
    },
    {
      'word': 'វែនតា',
      'missing': 'វ',
      'blank': '_ែនតា',
      'meaning': 'Glasses',
      'image': 'assets/images/consonants/វ_វែនតា.png',
    },
    {
      'word': 'ស្វា',
      'missing': 'ស',
      'blank': '_្វា',
      'meaning': 'Monkey',
      'image': 'assets/images/consonants/ស_ស្វា.png',
    },
    {
      'word': 'យន្តហោះ',
      'missing': 'ហ',
      'blank': 'យន្ត_ោះ',
      'meaning': 'Airplane',
      'image': 'assets/images/consonants/ហ_យន្តហោះ.png',
    },
    {
      'word': 'ឡាន',
      'missing': 'ឡ',
      'blank': '_ាន',
      'meaning': 'Car',
      'image': 'assets/images/consonants/ឡ_ឡាន.png',
    },
    {
      'word': 'អណ្ដើក',
      'missing': 'អ',
      'blank': '_ណ្ដើក',
      'meaning': 'Turtle',
      'image': 'assets/images/consonants/អ_អណ្ដើក.png',
    },
  ];

  /// Generates a challenge where the user fills in a missing character.
  ///
  /// - **Easy**: word + blank + image hint in display.
  /// - **Medium**: word + blank only.
  /// - **Hard**: audio-only (display = 'audio').
  static Challenge _generateMissingCharacterChallenge(
    Map<String, dynamic>? config,
    MiniGameDifficulty difficulty,
  ) {
    final entry = _khmerWords[_rng.nextInt(_khmerWords.length)];
    final fullWord = entry['word']!;
    final missing = entry['missing']!;
    final blank = entry['blank']!;

    String displayHint;
    switch (difficulty) {
      case MiniGameDifficulty.easy:
      case MiniGameDifficulty.medium:
      case MiniGameDifficulty.hard:
        displayHint = 'with_image';
        break;
    }

    final imagePath = entry['image'];

    return Challenge(
      display: displayHint,
      target: missing,
      wordWithBlank: blank,
      fullWord: fullWord,
      imagePath: imagePath,
    );
  }

  // ── Drag-and-Drop pair generation ────────────────────────────────

  /// Emoji / meaning pairs mapped to Khmer characters for drag matching.
  static const Map<String, Map<String, String>> _dragPairData = {
    'ក': {'emoji': 'assets/images/consonants/ក_កុក.png', 'hint': 'Egret'},
    'ខ': {'emoji': 'assets/images/consonants/ខ_ខ្លា.png', 'hint': 'Tiger'},
    'គ': {'emoji': 'assets/images/consonants/គ_គោ.png', 'hint': 'Cow'},
    'ឃ': {'emoji': 'assets/images/consonants/ឃ_ឃ្មុំ.png', 'hint': 'Bee'},
    'ង': {'emoji': 'assets/images/consonants/ង_ងាវ.png', 'hint': 'Clam'},
    'ច': {'emoji': 'assets/images/consonants/ច_ចាប.png', 'hint': 'Bird'},
    'ឆ': {'emoji': 'assets/images/consonants/ឆ_ឆ្មា.png', 'hint': 'Cat'},
    'ជ': {'emoji': 'assets/images/consonants/ជ_ជ្រុក.png', 'hint': 'Pig'},
    'ឈ': {'emoji': 'assets/images/consonants/ឈ_ឈ្លូស.png', 'hint': 'Deer'},
    'ញ': {'emoji': 'assets/images/consonants/ញ_ញញួរ.png', 'hint': 'Hammer'},
    'ដ': {'emoji': 'assets/images/consonants/ដ_ដំរី.png', 'hint': 'Elephant'},
    'ឋ': {'emoji': 'assets/images/consonants/ឋ_សាលា.png', 'hint': 'School'},
    'ឌ': {'emoji': 'assets/images/consonants/ឌ_ដង្កូវ.png', 'hint': 'Worm'},
    'ឍ': {'emoji': 'assets/images/consonants/ឍ_ឍាមរ៉ា.png', 'hint': 'Mallet'},
    'ណ': {'emoji': 'assets/images/consonants/ណ_កណ្ដឹង.png', 'hint': 'Bell'},
    'ត': {'emoji': 'assets/images/consonants/ត_ត្រី.png', 'hint': 'Fish'},
    'ថ': {'emoji': 'assets/images/consonants/ថ_ថូ.png', 'hint': 'Vase'},
    'ទ': {'emoji': 'assets/images/consonants/ទ_ទា.png', 'hint': 'Duck'},
    'ធ': {'emoji': 'assets/images/consonants/ធ_ធុង.png', 'hint': 'Bucket'},
    'ន': {'emoji': 'assets/images/consonants/ន_នាគ.png', 'hint': 'Dragon'},
    'ប': {'emoji': 'assets/images/consonants/ប_បាល់.png', 'hint': 'Ball'},
    'ផ': {'emoji': 'assets/images/consonants/ផ_ផ្កា.png', 'hint': 'Flower'},
    'ព': {'emoji': 'assets/images/consonants/ព_ពពែ.png', 'hint': 'Goat'},
    'ភ': {'emoji': 'assets/images/consonants/ភ_ភេ.png', 'hint': 'Otter'},
    'ម': {'emoji': 'assets/images/consonants/ម_មាន់.png', 'hint': 'Chicken'},
    'យ': {'emoji': 'assets/images/consonants/យ_យក្ស.png', 'hint': 'Giant'},
    'រ': {'emoji': 'assets/images/consonants/រ_រុយ.png', 'hint': 'Fly'},
    'ល': {'emoji': 'assets/images/consonants/ល_លា.png', 'hint': 'Donkey'},
    'វ': {'emoji': 'assets/images/consonants/វ_វែនតា.png', 'hint': 'Glasses'},
    'ស': {'emoji': 'assets/images/consonants/ស_ស្វា.png', 'hint': 'Monkey'},
    'ហ': {
      'emoji': 'assets/images/consonants/ហ_យន្តហោះ.png',
      'hint': 'Airplane',
    },
    'ឡ': {'emoji': 'assets/images/consonants/ឡ_ឡាន.png', 'hint': 'Car'},
    'អ': {'emoji': 'assets/images/consonants/អ_អណ្ដើក.png', 'hint': 'Turtle'},
    // Digits — use fruit asset images with *count multiplier
    '០': {'emoji': 'assets/images/fruits/empty_basket.png', 'hint': '0 Zero'},
    '១': {'emoji': 'assets/images/fruits/apple.png*1', 'hint': '1 Apple'},
    '២': {'emoji': 'assets/images/fruits/orange.png*2', 'hint': '2 Oranges'},
    '៣': {'emoji': 'assets/images/fruits/grape.png*3', 'hint': '3 Grapes'},
    '៤': {'emoji': 'assets/images/fruits/banana.png*4', 'hint': '4 Bananas'},
    '៥': {
      'emoji': 'assets/images/fruits/strawberry.png*5',
      'hint': '5 Strawberries',
    },
    '៦': {
      'emoji': 'assets/images/fruits/watermelon.png*6',
      'hint': '6 Watermelons',
    },
    '៧': {'emoji': 'assets/images/fruits/apple.png*7', 'hint': '7 Apples'},
    '៨': {'emoji': 'assets/images/fruits/orange.png*8', 'hint': '8 Oranges'},
    '៩': {'emoji': 'assets/images/fruits/banana.png*9', 'hint': '9 Bananas'},
  };

  /// Generate pairs for drag-and-drop matching.
  ///
  /// The pair layout adapts to the [displayType]:
  /// - `character` / default: Left = Image/Emoji, Right = Character
  /// - `object_count`: Left = Digit, Right = Counted Emojis
  /// - `missing_character`: Left = Image of word, Right = Characters (1 correct + distractors)
  ///
  /// Count: Easy = 3 pairs, Medium = 5 pairs, Hard = 5 pairs + 2 distractors.
  static List<DragMatchPair> generateDragMatchPairs({
    required List<String> pool,
    required MiniGameDifficulty difficulty,
    String displayType = 'character',
  }) {
    if (displayType == 'missing_character') {
      return _generateMissingCharDragPairs(pool, difficulty);
    }

    final count = difficulty == MiniGameDifficulty.easy ? 3 : 5;
    final distractorCount = difficulty == MiniGameDifficulty.hard ? 2 : 0;

    // Filter pool to items we have pair data for
    final available = pool.where((c) => _dragPairData.containsKey(c)).toList();

    List<String> selected;
    if (difficulty == MiniGameDifficulty.easy || available.length < 2) {
      available.shuffle(_rng);
      selected = available.take(count).toList();
    } else {
      // Medium/Hard: try to pick similar characters for a greater challenge
      selected = _pickSimilarPool(available, count);
    }

    // Pad if not enough
    if (selected.length < count) {
      final extra =
          _dragPairData.keys.where((k) => !selected.contains(k)).toList()
            ..shuffle(_rng);
      for (final k in extra) {
        if (selected.length >= count) break;
        selected.add(k);
      }
    }

    // Create the real pairs
    final pairs = selected.asMap().entries.map((e) {
      final ch = e.value;
      final data = _dragPairData[ch]!;

      String source;
      String target;

      switch (displayType) {
        case 'object_count':
          source = ch;
          target = data['emoji']!;
          break;
        default:
          source = data['emoji']!;
          target = ch;
          break;
      }

      return DragMatchPair(id: '${e.key}_$ch', source: source, target: target);
    }).toList();

    // Add distractors for Hard difficulty — only from the same pool
    if (distractorCount > 0) {
      final unused =
          pool
              .where(
                (k) => _dragPairData.containsKey(k) && !selected.contains(k),
              )
              .toList()
            ..shuffle(_rng);

      for (int i = 0; i < distractorCount; i++) {
        if (i >= unused.length) break;
        final ch = unused[i];
        pairs.add(
          DragMatchPair(
            id: 'distractor_$i',
            source: '', // Empty source means it won't appear on the left column
            target: ch,
          ),
        );
      }
    }

    return pairs;
  }

  /// Picks a list of characters from the [available] pool, prioritizing visually similar ones.
  static List<String> _pickSimilarPool(List<String> available, int count) {
    if (available.isEmpty) return [];
    final selected = <String>{};

    // 1. Pick a random starting character from the pool
    final shuffled = List<String>.from(available)..shuffle(_rng);
    final start = shuffled.first;
    selected.add(start);

    // 2. Try to find its similar characters in the pool
    final similar =
        _khmerSimilarMap[start]?.where((s) => available.contains(s)).toList() ??
        [];
    similar.shuffle(_rng);
    for (final s in similar) {
      if (selected.length >= count) break;
      selected.add(s);
    }

    // 3. If still need more, pick another random character from the remainder and repeat
    while (selected.length < count && selected.length < available.length) {
      final remainder = available.where((c) => !selected.contains(c)).toList()
        ..shuffle(_rng);
      if (remainder.isEmpty) break;
      final next = remainder.first;
      selected.add(next);

      final nextSimilar =
          _khmerSimilarMap[next]
              ?.where((s) => available.contains(s) && !selected.contains(s))
              .toList() ??
          [];
      nextSimilar.shuffle(_rng);
      for (final s in nextSimilar) {
        if (selected.length >= count) break;
        selected.add(s);
      }
    }

    return selected.toList();
  }

  /// Generate drag pairs for missing_character display.
  /// Left column = Image of the word + Blank Word, Right column = Correct Character
  static List<DragMatchPair> _generateMissingCharDragPairs(
    List<String> pool,
    MiniGameDifficulty difficulty,
  ) {
    final count = difficulty == MiniGameDifficulty.easy ? 3 : 5;
    final distractorCount = difficulty == MiniGameDifficulty.hard ? 2 : 0;

    // Pick words whose missing character is in the pool
    // Prioritize similar characters on higher difficulties
    List<Map<String, String>> selected;
    if (difficulty == MiniGameDifficulty.easy) {
      final availableWords =
          _khmerWords.where((w) => pool.contains(w['missing'])).toList()
            ..shuffle(_rng);
      selected = availableWords.take(count).toList();
    } else {
      selected = _pickSimilarWords(pool, count);
    }

    // Pad if not enough
    if (selected.length < count) {
      final extra = _khmerWords.where((w) => !selected.contains(w)).toList()
        ..shuffle(_rng);
      for (var w in extra) {
        if (selected.length >= count) break;
        selected.add(w);
      }
    }

    final pairs = selected.asMap().entries.map((e) {
      final word = e.value;
      return DragMatchPair(
        id: '${e.key}_${word['missing']}',
        source:
            '${word['image']}|${word['blank']}', // Combine image and blank text
        target: word['missing']!,
      );
    }).toList();

    // Add distractors for Hard mode
    if (distractorCount > 0) {
      final usedChars = selected.map((w) => w['missing']).toSet();
      final unusedPool = pool.where((c) => !usedChars.contains(c)).toList()
        ..shuffle(_rng);

      for (int i = 0; i < distractorCount; i++) {
        if (i >= unusedPool.length) break;
        pairs.add(
          DragMatchPair(
            id: 'distractor_$i',
            source: '', // Won't show up as a source picture
            target: unusedPool[i],
          ),
        );
      }
    }

    return pairs;
  }

  /// Similar to _pickSimilarPool but for the _khmerWords list.
  static List<Map<String, String>> _pickSimilarWords(
    List<String> pool,
    int count,
  ) {
    final selected = <Map<String, String>>[];
    final usedChars = <String>{};

    final availableWords =
        _khmerWords.where((w) => pool.contains(w['missing'])).toList()
          ..shuffle(_rng);
    if (availableWords.isEmpty) return [];

    // Start with a random word
    final start = availableWords.first;
    selected.add(start);
    usedChars.add(start['missing']!);

    // Try to find words with similar characters
    final similarChars = _khmerSimilarMap[start['missing']] ?? [];
    for (final sim in similarChars) {
      if (selected.length >= count) break;
      final matches = availableWords.where(
        (w) => w['missing'] == sim && !usedChars.contains(sim),
      );
      final match = matches.isEmpty ? null : matches.first;
      if (match != null) {
        selected.add(match);
        usedChars.add(sim);
      }
    }

    // Fallback to random if not enough
    for (final w in availableWords) {
      if (selected.length >= count) break;
      if (!usedChars.contains(w['missing'])) {
        selected.add(w);
        usedChars.add(w['missing']!);
      }
    }

    return selected;
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
        return 9;
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
