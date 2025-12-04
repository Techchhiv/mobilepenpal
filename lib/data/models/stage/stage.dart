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
    final exercisesList = (json['exercises'] as List)
        .map((exerciseJson) => StageExercise.fromJson(exerciseJson))
        .toList();

    return Stage(
      id: json['id'] as int,
      name: json['name'] as String,
      instruction: json['instruction'] as String,
      description: json['description'] as String,
      orderIndex: json['order_index'] as int,
      maxStars: json['max_stars'] as int,
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