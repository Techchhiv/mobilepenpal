import 'dart:convert';

class Exercise {
  final int id;
  final String prompt;
  final String character;
  final String? example;
  final String question;
  final List<String> options;
  final String instruction;
  final String hint;
  final String? characterType;
  final String? difficulty;
  final String? mathOp;

  Exercise({
    required this.id,
    required this.prompt,
    required this.character,
    this.example,
    required this.question,
    required this.options,
    required this.instruction,
    required this.hint,
    this.characterType,
    this.difficulty,
    this.mathOp,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];

    try {
      final v = json['options'];
      if (v is List) {
        parsedOptions = v.map((e) => e.toString()).toList();
      } else if (v is String && v.isNotEmpty) {
        final decoded = jsonDecode(v);
        if (decoded is List) {
          parsedOptions = decoded.map((e) => e.toString()).toList();
        } else {
          parsedOptions = [v];
        }
      }
    } catch (_) {
      parsedOptions = [];
    }

    return Exercise(
      id: (json['id'] as num?)?.toInt() ?? 0,
      prompt: (json['prompt'] ?? '').toString(),
      character: (json['character'] ?? '').toString(),
      example: json['example']?.toString(),
      question: (json['question'] ?? '').toString(),
      options: parsedOptions,
      instruction: (json['instruction'] ?? '').toString(),
      hint: (json['hint'] ?? '').toString(),
      characterType: json['character_type']?.toString(),
      difficulty: json['difficulty']?.toString(),
      mathOp: json['math_op']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'character': character,
      'example': example,
      'question': question,
      'options': jsonEncode(options),
      'instruction': instruction,
      'hint': hint,
      'character_type': characterType,
      'difficulty': difficulty,
      'math_op': mathOp,
    };
  }

  /// Convert to a StageExercise-compatible map for the drawing board
  StageExerciseData toStageExerciseData({int orderIndex = 0}) {
    return StageExerciseData(
      id: id,
      prompt: prompt,
      character: character,
      example: example,
      question: question,
      options: options,
      instruction: instruction,
      hint: hint,
      characterType: characterType,
      difficulty: difficulty,
      mathOp: mathOp,
      orderIndex: orderIndex,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, character: $character, type: $characterType)';
  }
}

/// Lightweight data class matching StageExercise fields for the drawing board
class StageExerciseData {
  final int id;
  final String prompt;
  final String character;
  final String? example;
  final String question;
  final List<String> options;
  final String instruction;
  final String hint;
  final int orderIndex;
  final String? characterType;
  final String? difficulty;
  final String? mathOp;

  StageExerciseData({
    required this.id,
    required this.prompt,
    required this.character,
    this.example,
    required this.question,
    required this.options,
    required this.instruction,
    required this.hint,
    required this.orderIndex,
    this.characterType,
    this.difficulty,
    this.mathOp,
  });
}
