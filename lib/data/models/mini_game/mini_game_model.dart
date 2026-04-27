class MiniGameModel {
  final int id;
  final String title;
  final String? description;
  final String displayType;
  final String inputType;
  final bool isActive;
  final String? coverImageUrl;
  final Map<String, dynamic>? config;

  MiniGameModel({
    required this.id,
    required this.title,
    this.description,
    required this.displayType,
    required this.inputType,
    this.isActive = true,
    this.coverImageUrl,
    this.config,
  });

  /// Parse comma-separated display types into a list.
  List<String> get displayTypes =>
      displayType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// Parse comma-separated input types into a list.
  List<String> get inputTypes =>
      inputType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// Returns the subset of this game's input types that are compatible
  /// with the given [chosenDisplayType].
  ///
  /// Compatibility rules:
  /// - 'character' display → only 'drawing_board' (typing the shown char teaches nothing)
  /// - 'audio' / 'image' → all supported input types
  /// - 'math_equation'   → 'drawing_board', 'multiple_choice'
  List<String> compatibleInputTypes(String chosenDisplayType) {
    final all = inputTypes;
    switch (chosenDisplayType) {
      case 'character':
        // User wants to experiment with multiple choice for characters
        return all.where((t) => t == 'drawing_board' || t == 'multiple_choice').toList();
      case 'audio':
      case 'image':
        return all; // all input types are valid
      case 'math_equation':
        return all.where((t) => t != 'typing').toList();
      default:
        return all;
    }
  }

  factory MiniGameModel.fromJson(Map<String, dynamic> json) {
    return MiniGameModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      displayType: json['display_type'] as String,
      inputType: json['input_type'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      coverImageUrl: json['cover_image_url'] as String?,
      config: json['config'] is Map<String, dynamic>
          ? json['config'] as Map<String, dynamic>
          : null,
    );
  }
}
