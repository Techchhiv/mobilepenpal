import 'package:mobilepenpal/data/models/world/world_level.dart';

class World {
  final int id;
  final String name;
  final String description;
  final String image;
  final String? backgroundImage;
  final String? iconUrl;
  final String? mapImageUrl;
  final String? themeColor;
  final int levelsCompleted;
  final int levelsTotal;
  final int levelsRemaining;
  final List<WorldLevel> levels;

  World({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.backgroundImage,
    this.iconUrl,
    this.mapImageUrl,
    this.themeColor,
    required this.levelsCompleted,
    required this.levelsTotal,
    required this.levelsRemaining,
    required this.levels,
  });

  factory World.fromJson(Map<String, dynamic> json) {
    return World(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'] ?? '',
      backgroundImage: json['background_image'] ?? '',
      iconUrl: json['icon_url'],
      mapImageUrl: json['map_image_url'],
      themeColor: json['theme_color'],
      levelsCompleted: json['levels_completed'] ?? 0,
      levelsTotal: json['levels_total'] ?? 0,
      levelsRemaining: json['levels_remaining'] ?? 0,
      levels: (json['levels'] as List<dynamic>? ?? [])
          .map((level) => WorldLevel.fromJson(level))
          .toList(),
    );
  }

  double get progressPercentage {
    return levelsTotal > 0 ? levelsCompleted / levelsTotal : 0.0;
  }

  bool get isCompleted => levelsCompleted >= levelsTotal;
}