class CharacterOptionUtils {
  static const List<String> khmerVowelExtensions = [
    '',
    'ា',
    'ិ',
    'ី',
    'ឹ',
    'ឺ',
    'ុ',
    'ូ',
    'ួ',
    'ើ',
    'ឿ',
    'ៀ',
    'េ',
    'ែ',
    'ៃ',
    'ោ',
    'ៅ',
    'ុំ',
    'ំ',
    'ាំ',
    'ះ',
    'ុះ',
    'េះ',
    'ោះ',
  ];

  static List<String> generateOptions({
    required String character,
    required String? type,
    String? example,
  }) {
    final t = (type ?? '').trim().toLowerCase();
    final target = character.trim();

    // 1. Handle Consonants: Generate vowel combinations
    if (t == 'consonants') {
      return khmerVowelExtensions.map((v) => '$target$v').toList();
    }

    // 2. Handle Digits: Add 'លេខ ' prefix
    if (t == 'digits') {
      const label = 'លេខ ';
      if (target.startsWith(label)) return [target];
      return ['$label$target'];
    }

    // 3. Handle Vowels: Add 'ស្រៈ ' prefix
    if (t == 'dependent_vowels' || t == 'independent_vowels' || t == 'vowels') {
      const label = 'ស្រៈ ';
      if (target.startsWith(label)) return [target];
      return ['$label$target'];
    }

    // 4. Default/Fallback: Split example string if provided (separated by '/')
    if (example != null && example.trim().isNotEmpty) {
      return example
          .split('/')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // If nothing else matches, just return the target as the only option
    return [target];
  }
}
