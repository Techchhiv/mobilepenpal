class KhmerCharUtils {
  /// The full list of Khmer dependent vowels as defined in standard Khmer orthography.
  static const List<String> dependentVowels = [
    '', // Base consonant
    'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ', 'ុំ', 'ំ', 'ាំ', 'ះ', 'ិះ', 'ុះ', 'េះ', 'ោះ'
  ];

  /// Generates a list of Khmer character combinations (vowel forms) for a given base consonant.
  static List<String> getVowelForms(String base) {
    if (base.isEmpty) return [];
    return dependentVowels.map((vowel) => '$base$vowel').toList();
  }
}
