import 'package:mobilepenpal/data/models/level/level_stage.dart';

class Level {
  final int id;

  final String name;
  final String? nameEn;

  final String description;
  final String? descriptionEn;

  final int orderIndex;
  final String? backgroundImage;

  final String worldName;
  final String? worldNameEn;

  final List<LevelStage> stages;

  Level({
    required this.id,
    required this.name,
    this.nameEn,
    required this.description,
    this.descriptionEn,
    required this.orderIndex,
    this.backgroundImage,
    required this.worldName,
    this.worldNameEn,
    required this.stages,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: (json['id'] as num?)?.toInt() ?? 0,

      name: (json['name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString().isEmpty ? null : (json['name_en'] ?? '').toString(),

      description: (json['description'] ?? '').toString(),
      descriptionEn: (json['description_en'] ?? '').toString().isEmpty ? null : (json['description_en'] ?? '').toString(),

      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      backgroundImage: json['background_image'] as String?,

      worldName: (json['world_name'] ?? '').toString(),
      worldNameEn: (json['world_name_en'] ?? '').toString().isEmpty ? null : (json['world_name_en'] ?? '').toString(),

      stages: (json['stages'] as List<dynamic>? ?? [])
          .map((stageJson) => LevelStage.fromJson(stageJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'description': description,
      'description_en': descriptionEn,
      'order_index': orderIndex,
      'background_image': backgroundImage,
      'world_name': worldName,
      'world_name_en': worldNameEn,
      'stages': stages.map((stage) => stage.toJson()).toList(),
    };
  }

  Level copyWith({
    int? id,
    String? name,
    String? nameEn,
    String? description,
    String? descriptionEn,
    int? orderIndex,
    String? backgroundImage,
    String? worldName,
    String? worldNameEn,
    List<LevelStage>? stages,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      orderIndex: orderIndex ?? this.orderIndex,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      worldName: worldName ?? this.worldName,
      worldNameEn: worldNameEn ?? this.worldNameEn,
      stages: stages ?? this.stages,
    );
  }
}