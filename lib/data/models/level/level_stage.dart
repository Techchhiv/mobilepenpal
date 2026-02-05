class LevelStage {
  final int id;

  final String name;
  final String? nameEn;

  final String description;
  final String? descriptionEn;

  final int orderIndex;
  final int starsEarned;
  final String status;

  LevelStage({
    required this.id,
    required this.name,
    this.nameEn,
    required this.description,
    this.descriptionEn,
    required this.orderIndex,
    required this.starsEarned,
    required this.status,
  });

  factory LevelStage.fromJson(Map<String, dynamic> json) {
    return LevelStage(
      id: (json['id'] as num?)?.toInt() ?? 0,

      name: (json['name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString().isEmpty
          ? null
          : (json['name_en'] ?? '').toString(),

      description: (json['description'] ?? '').toString(),
      descriptionEn: (json['description_en'] ?? '').toString().isEmpty
          ? null
          : (json['description_en'] ?? '').toString(),

      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      starsEarned: (json['stars_earned'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'locked').toString(),
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
      'stars_earned': starsEarned,
      'status': status,
    };
  }

  LevelStage copyWith({
    int? id,
    String? name,
    String? nameEn,
    String? description,
    String? descriptionEn,
    int? orderIndex,
    int? starsEarned,
    String? status,
  }) {
    return LevelStage(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      orderIndex: orderIndex ?? this.orderIndex,
      starsEarned: starsEarned ?? this.starsEarned,
      status: status ?? this.status,
    );
  }
}
