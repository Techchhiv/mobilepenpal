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
      id: json['id'] as int,
      name: json['name'] as String,
      instruction: json['instruction'] as String,
      description: json['description'] as String,
      orderIndex: json['order_index'] as int,
      maxStars: json['max_stars'] as int,
      starsEarned: json['stars_earned'] as int,
      status: json['status'] as String,
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
