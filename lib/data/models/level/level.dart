import 'package:mobilepenpal/data/models/level/level_stage.dart';

class Level {
  final int id;
  final String name;
  final String description;
  final int orderIndex;
  final String? backgroundImage;
  final String worldName;
  final List<LevelStage> stages;

  Level({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    this.backgroundImage,
    required this.worldName,
    required this.stages,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      backgroundImage: json['background_image'] as String?,
      worldName: (json['world_name'] ?? '').toString(),
      stages: (json['stages'] as List<dynamic>? ?? [])
          .map(
            (stageJson) =>
                LevelStage.fromJson(stageJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order_index': orderIndex,
      'background_image': backgroundImage,
      'world_name': worldName,
      'stages': stages.map((stage) => stage.toJson()).toList(),
    };
  }

  Level copyWith({
    int? id,
    String? name,
    String? description,
    int? orderIndex,
    String? backgroundImage,
    String? worldName,
    List<LevelStage>? stages,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      worldName: worldName ?? this.worldName,
      stages: stages ?? this.stages,
    );
  }
}
