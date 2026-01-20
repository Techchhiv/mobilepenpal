class LevelStage {
  final int id;
  final String name;
  final String instruction;
  final String description;
  final int orderIndex;
  final int maxStars;
  final int starsEarned;
  final String status;

  LevelStage({
    required this.id,
    required this.name,
    required this.instruction,
    required this.description,
    required this.orderIndex,
    required this.maxStars,
    required this.starsEarned,
    required this.status,
  });

  factory LevelStage.fromJson(Map<String, dynamic> json) {
    return LevelStage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      instruction: (json['instruction'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      maxStars: (json['max_stars'] as num?)?.toInt() ?? 0,
      starsEarned: (json['stars_earned'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'locked').toString(),
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
      'stars_earned': starsEarned,
      'status': status,
    };
  }

  LevelStage copyWith({
    int? id,
    String? name,
    String? instruction,
    String? description,
    int? orderIndex,
    int? maxStars,
    int? starsEarned,
    String? status,
  }) {
    return LevelStage(
      id: id ?? this.id,
      name: name ?? this.name,
      instruction: instruction ?? this.instruction,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      maxStars: maxStars ?? this.maxStars,
      starsEarned: starsEarned ?? this.starsEarned,
      status: status ?? this.status,
    );
  }
}
