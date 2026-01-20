import 'dart:convert';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';

Stage stageFromJson(String str) => Stage.fromJson(json.decode(str));
String stageToJson(Stage data) => json.encode(data.toJson());

class Stage {
  final int id;
  final String name;
  final String instruction;
  final String description;
  final int orderIndex;
  final int maxStars;
  final List<StageExercise> exercises;

  Stage({
    required this.id,
    required this.name,
    required this.instruction,
    required this.description,
    required this.orderIndex,
    required this.maxStars,
    required this.exercises,
  });

  factory Stage.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    final exercisesList = (rawExercises is List ? rawExercises : const [])
        .map((e) => StageExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return Stage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      instruction: (json['instruction'] ?? '').toString(), // ✅ was null
      description: (json['description'] ?? '').toString(), // ✅ was null
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      maxStars: (json['max_stars'] as num?)?.toInt() ?? 0,
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instruction': instruction,
      'description': description,
      'order_index': orderIndex,
      'max_stars': maxStars,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Stage(id: $id, name: $name, exercises: ${exercises.length})';
  }
}
