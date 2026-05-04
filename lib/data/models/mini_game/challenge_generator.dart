import 'dart:math';

import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';

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

  Challenge({
    required this.display,
    required this.target,
    this.objectEmojis,
    this.wordWithBlank,
    this.fullWord,
    this.imagePath,
  });
}

/// Represents a single pair for drag-and-drop matching.
class DragMatchPair {
  final String id;
  final String source;   // The character / number shown on left
  final String target;   // The label / emoji shown on right
  final String? hint;    // Optional meaning text
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

  /// Generate a random challenge from the given mini-game config.
  /// [difficulty] controls the complexity of the generated challenge.
  static Challenge generate(
    MiniGameModel game, {
    MiniGameDifficulty difficulty = MiniGameDifficulty.easy,
  }) {
    switch (game.displayType) {
      case 'math_equation':
        return _generateMathChallenge(game.config, difficulty);
      case 'object_count':
        return _generateObjectCountChallenge(game.config, difficulty);
      case 'missing_character':
        return _generateMissingCharacterChallenge(game.config, difficulty);
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
        count = 1 + _rng.nextInt(5);   // 1..5
        displayHint = 'neat';
        break;
      case MiniGameDifficulty.medium:
        count = 1 + _rng.nextInt(9);   // 1..9
        displayHint = 'scattered';
        break;
      case MiniGameDifficulty.hard:
        count = 1 + _rng.nextInt(9);   // 1..9
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
    {'word': 'កុក', 'missing': 'ក', 'blank': '_ុក', 'meaning': 'Egret', 'image': 'assets/images/consonants/ក_កុក.png'},
    {'word': 'ខ្លា', 'missing': 'ខ', 'blank': '_្លា', 'meaning': 'Tiger', 'image': 'assets/images/consonants/ខ_ខ្លា.png'},
    {'word': 'គោ', 'missing': 'គ', 'blank': '_ោ', 'meaning': 'Cow', 'image': 'assets/images/consonants/គ_គោ.png'},
    {'word': 'ឃ្មុំ', 'missing': 'ឃ', 'blank': '_្មុំ', 'meaning': 'Bee', 'image': 'assets/images/consonants/ឃ_ឃ្មុំ.png'},
    {'word': 'ងាវ', 'missing': 'ង', 'blank': '_ាវ', 'meaning': 'Clam', 'image': 'assets/images/consonants/ង_ងាវ.png'},
    {'word': 'ចាប', 'missing': 'ច', 'blank': '_ាប', 'meaning': 'Bird', 'image': 'assets/images/consonants/ច_ចាប.png'},
    {'word': 'ឆ្មា', 'missing': 'ឆ', 'blank': '_្មា', 'meaning': 'Cat', 'image': 'assets/images/consonants/ឆ_ឆ្មា.png'},
    {'word': 'ជ្រូក', 'missing': 'ជ', 'blank': '_្រូក', 'meaning': 'Pig', 'image': 'assets/images/consonants/ជ_ជ្រុក.png'},
    {'word': 'ឈ្លូស', 'missing': 'ឈ', 'blank': '_្លូស', 'meaning': 'Deer', 'image': 'assets/images/consonants/ឈ_ឈ្លូស.png'},
    {'word': 'ញញួរ', 'missing': 'ញ', 'blank': '_ញួរ', 'meaning': 'Hammer', 'image': 'assets/images/consonants/ញ_ញញួរ.png'},
    {'word': 'ដំរី', 'missing': 'ដ', 'blank': '_ំរី', 'meaning': 'Elephant', 'image': 'assets/images/consonants/ដ_ដំរី.png'},
    {'word': 'ឍាមរ៉ា', 'missing': 'ឍ', 'blank': '_ាមរ៉ា', 'meaning': 'Mallet', 'image': 'assets/images/consonants/ឍ_ឍាមរ៉ា.png'},
    {'word': 'កណ្ដឹង', 'missing': 'ណ', 'blank': 'ក_្ដឹង', 'meaning': 'Bell', 'image': 'assets/images/consonants/ណ_កណ្ដឹង.png'},
    {'word': 'ត្រី', 'missing': 'ត', 'blank': '_្រី', 'meaning': 'Fish', 'image': 'assets/images/consonants/ត_ត្រី.png'},
    {'word': 'ថូ', 'missing': 'ថ', 'blank': '_ូ', 'meaning': 'Vase', 'image': 'assets/images/consonants/ថ_ថូ.png'},
    {'word': 'ទា', 'missing': 'ទ', 'blank': '_ា', 'meaning': 'Duck', 'image': 'assets/images/consonants/ទ_ទា.png'},
    {'word': 'ធុង', 'missing': 'ធ', 'blank': '_ុង', 'meaning': 'Bucket', 'image': 'assets/images/consonants/ធ_ធុង.png'},
    {'word': 'នាគ', 'missing': 'ន', 'blank': '_ាគ', 'meaning': 'Dragon', 'image': 'assets/images/consonants/ន_នាគ.png'},
    {'word': 'បាល់', 'missing': 'ប', 'blank': '_ាល់', 'meaning': 'Ball', 'image': 'assets/images/consonants/ប_បាល់.png'},
    {'word': 'ផ្កា', 'missing': 'ផ', 'blank': '_្កា', 'meaning': 'Flower', 'image': 'assets/images/consonants/ផ_ផ្កា.png'},
    {'word': 'ពពែ', 'missing': 'ព', 'blank': '_ពែ', 'meaning': 'Goat', 'image': 'assets/images/consonants/ព_ពពែ.png'},
    {'word': 'ភេ', 'missing': 'ភ', 'blank': '_េ', 'meaning': 'Otter', 'image': 'assets/images/consonants/ភ_ភេ.png'},
    {'word': 'មាន់', 'missing': 'ម', 'blank': '_ាន់', 'meaning': 'Chicken', 'image': 'assets/images/consonants/ម_មាន់.png'},
    {'word': 'យក្ស', 'missing': 'យ', 'blank': '_ក្ស', 'meaning': 'Giant', 'image': 'assets/images/consonants/យ_យក្ស.png'},
    {'word': 'រុយ', 'missing': 'រ', 'blank': '_ុយ', 'meaning': 'Fly', 'image': 'assets/images/consonants/រ_រុយ.png'},
    {'word': 'លា', 'missing': 'ល', 'blank': '_ា', 'meaning': 'Donkey', 'image': 'assets/images/consonants/ល_លា.png'},
    {'word': 'វែនតា', 'missing': 'វ', 'blank': '_ែនតា', 'meaning': 'Glasses', 'image': 'assets/images/consonants/វ_វែនតា.png'},
    {'word': 'ស្វា', 'missing': 'ស', 'blank': '_្វា', 'meaning': 'Monkey', 'image': 'assets/images/consonants/ស_ស្វា.png'},
    {'word': 'យន្តហោះ', 'missing': 'ហ', 'blank': 'យន្ត_ោះ', 'meaning': 'Airplane', 'image': 'assets/images/consonants/ហ_យន្តហោះ.png'},
    {'word': 'ឡាន', 'missing': 'ឡ', 'blank': '_ាន', 'meaning': 'Car', 'image': 'assets/images/consonants/ឡ_ឡាន.png'},
    {'word': 'អណ្ដើក', 'missing': 'អ', 'blank': '_ណ្ដើក', 'meaning': 'Turtle', 'image': 'assets/images/consonants/អ_អណ្ដើក.png'},
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
    final meaning = entry['meaning']!;

    String displayHint;
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        displayHint = 'with_image';   // show blank word + picture
        break;
      case MiniGameDifficulty.medium:
        displayHint = 'word_only';    // show blank word, no picture
        break;
      case MiniGameDifficulty.hard:
        displayHint = 'audio';        // play audio of the word, hide text
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
    'ហ': {'emoji': 'assets/images/consonants/ហ_យន្តហោះ.png', 'hint': 'Airplane'},
    'ឡ': {'emoji': 'assets/images/consonants/ឡ_ឡាន.png', 'hint': 'Car'},
    'អ': {'emoji': 'assets/images/consonants/អ_អណ្ដើក.png', 'hint': 'Turtle'},
    // Digits
    '០': {'emoji': '🔲', 'hint': '0 Zero'},
    '១': {'emoji': '🌟', 'hint': '1 Star'},
    '២': {'emoji': '🌺🌺', 'hint': '2 Flowers'},
    '៣': {'emoji': '🦋🦋🦋', 'hint': '3 Butterflies'},
    '៤': {'emoji': '🍎🍎🍎🍎', 'hint': '4 Apples'},
    '៥': {'emoji': '⭐⭐⭐⭐⭐', 'hint': '5 Stars'},
    '៦': {'emoji': '🍓🍓🍓🍓🍓🍓', 'hint': '6 Strawberries'},
    '៧': {'emoji': '🌻🌻🌻🌻🌻🌻🌻', 'hint': '7 Sunflowers'},
    '៨': {'emoji': '🐠🐠🐠🐠🐠🐠🐠🐠', 'hint': '8 Fish'},
    '៩': {'emoji': '🍊🍊🍊🍊🍊🍊🍊🍊🍊', 'hint': '9 Oranges'},
    // Dependent Vowels
    'ា': {'emoji': '🌊', 'hint': 'Water'},
    'ិ': {'emoji': '🐟', 'hint': 'Fish'},
    'ី': {'emoji': '🌍', 'hint': 'Earth'},
    'ុ': {'emoji': '🌪️', 'hint': 'Wind'},
    'ូ': {'emoji': '🌙', 'hint': 'Moon'},
    'េ': {'emoji': '🔥', 'hint': 'Fire'},
    'ែ': {'emoji': '🌧️', 'hint': 'Rain'},
    'ំ': {'emoji': '🏡', 'hint': 'Home'},
    // Independent Vowels
    'ឥ': {'emoji': '🧘', 'hint': 'Hermit'},
    'ឧ': {'emoji': '🪵', 'hint': 'Firewood'},
    'ឪ': {'emoji': '👨', 'hint': 'Father'},
    'ឫ': {'emoji': '🌿', 'hint': 'Root'},
    'ឯ': {'emoji': '☝️', 'hint': 'One'},
  };

  /// Generate pairs for drag-and-drop matching.
  ///
  /// The pair layout adapts to the [displayType]:
  /// - `character` / default: Left = Image/Emoji, Right = Character
  /// - `object_count`: Left = Digit, Right = Counted Emojis
  /// - `missing_character`: Left = Image of word, Right = Characters (1 correct + distractors)
  ///
  /// Count: Easy = 3 pairs, Medium/Hard = 5 pairs.
  static List<DragMatchPair> generateDragMatchPairs({
    required List<String> pool,
    required MiniGameDifficulty difficulty,
    String displayType = 'character',
  }) {
    if (displayType == 'missing_character') {
      return _generateMissingCharDragPairs(pool, difficulty);
    }

    final count = difficulty == MiniGameDifficulty.easy ? 3 : 5;

    // Filter pool to items we have pair data for
    final available = pool.where((c) => _dragPairData.containsKey(c)).toList()
      ..shuffle(_rng);

    // Take up to `count` items
    final selected = available.take(count).toList();

    // If pool too small, pad from _dragPairData keys
    if (selected.length < count) {
      final extra = _dragPairData.keys
          .where((k) => !selected.contains(k))
          .toList()
        ..shuffle(_rng);
      for (final k in extra) {
        if (selected.length >= count) break;
        selected.add(k);
      }
    }

    return selected.asMap().entries.map((e) {
      final ch = e.value;
      final data = _dragPairData[ch]!;

      String source;
      String target;

      switch (displayType) {
        case 'object_count':
          // Left = Khmer digit, Right = counted emojis
          source = ch;
          target = data['emoji']!;
          break;
        default:
          // character / vowel / etc: Left = Image/Emoji, Right = Character
          source = data['emoji']!;
          target = ch;
          break;
      }

      return DragMatchPair(
        id: '${e.key}_$ch',
        source: source,
        target: target,
        hint: null,
      );
    }).toList();
  }

  /// Generate drag pairs for missing_character display.
  /// Left column = Image of the word + Blank Word, Right column = Correct Character
  static List<DragMatchPair> _generateMissingCharDragPairs(
    List<String> pool,
    MiniGameDifficulty difficulty,
  ) {
    final count = difficulty == MiniGameDifficulty.easy ? 3 : 5;

    // Pick words whose missing character is in the pool
    final availableWords = _khmerWords
        .where((w) => pool.contains(w['missing']))
        .toList()
      ..shuffle(_rng);

    // If not enough from pool, use any words
    if (availableWords.length < count) {
      final extra = _khmerWords
          .where((w) => !availableWords.contains(w))
          .toList()
        ..shuffle(_rng);
      for(var w in extra) {
         if (!availableWords.contains(w)) availableWords.add(w);
      }
    }

    final selected = availableWords.take(count).toList();

    return selected.asMap().entries.map((e) {
      final word = e.value;
      return DragMatchPair(
        id: '${e.key}_${word['missing']}',
        source: '${word['image']}|${word['blank']}', // Combine image and blank text
        target: word['missing']!, 
        hint: null,
      );
    }).toList();
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
