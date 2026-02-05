import 'package:mobilepenpal/data/models/world/world_level.dart';

class World {
  final int id;

  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;

  final int levelsCompleted;
  final int levelsTotal;
  final int levelsRemaining;

  final List<WorldLevel> levels;

  World({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.levelsCompleted,
    required this.levelsTotal,
    required this.levelsRemaining,
    required this.levels,
  });

  factory World.fromJson(Map<String, dynamic> json) {
    return World(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      nameEn: (json['name_en'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      descriptionEn: (json['description_en'] ?? '') as String,
      levelsCompleted: (json['levels_completed'] ?? 0) as int,
      levelsTotal: (json['levels_total'] ?? 0) as int,
      levelsRemaining: (json['levels_remaining'] ?? 0) as int,
      levels: (json['levels'] as List<dynamic>? ?? [])
          .map((level) => WorldLevel.fromJson(level as Map<String, dynamic>))
          .toList(),
    );
  }

  double get progressPercentage =>
      levelsTotal > 0 ? levelsCompleted / levelsTotal : 0.0;

  bool get isCompleted => levelsTotal > 0 && levelsCompleted >= levelsTotal;
}
