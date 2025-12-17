import 'dart:convert';

StageExercise stageExerciseFromJson(String str) => StageExercise.fromJson(json.decode(str));
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
  // final String? audioUrl;
  // final String? imageUrl;

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
    // this.audioUrl,
    // this.imageUrl,
  });

  factory StageExercise.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    
    try {
      if (json['options'] != null) {
        if (json['options'] is String) {
          final optionsString = json['options'] as String;
          final cleanedString = optionsString.replaceAll(r'\"', '"');
          final decodedList = jsonDecode(cleanedString) as List;
          parsedOptions = decodedList.map((e) => e.toString()).toList();
        } else if (json['options'] is List) {
          parsedOptions = (json['options'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      parsedOptions = []; 
    }

    return StageExercise(
      id: json['id'] as int,
      prompt: json['prompt'] as String,
      character: json['character'] as String,
      example: json['example'] as String,
      question: json['question'] as String,
      options: parsedOptions,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String,
      orderIndex: json['order_index'] as int,
      characterType: json['character_type'] as String?,
      // audioUrl: json['audio_url'] as String?,
      // imageUrl: json['image_url'] as String?,
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
      // 'audio_url': audioUrl,
      // 'image_url': imageUrl,
    };
  }

  @override
  String toString() {
    return 'StageExercise(id: $id, character: $character, orderIndex: $orderIndex)';
  }
}