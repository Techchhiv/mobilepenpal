import 'dart:convert';

StageExercise stageExerciseFromJson(String str) =>
    StageExercise.fromJson(json.decode(str));
String stageExerciseToJson(StageExercise data) => json.encode(data.toJson());

class StageExercise {
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

  StageExercise({
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
  });

  factory StageExercise.fromJson(Map<String, dynamic> json) {
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

    return StageExercise(
      id: (json['id'] as num?)?.toInt() ?? 0,
      prompt: (json['prompt'] ?? '').toString(),
      character: (json['character'] ?? '').toString(),
      example: json['example']?.toString(),
      question: (json['question'] ?? '').toString(),
      options: parsedOptions,
      instruction: (json['instruction'] ?? '').toString(),
      hint: (json['hint'] ?? '').toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      characterType: json['character_type']?.toString(),
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
      'order_index': orderIndex,
      'character_type': characterType,
    };
  }

  @override
  String toString() {
    return 'StageExercise(id: $id, character: $character, orderIndex: $orderIndex)';
  }
}
