class WorldLevel {
  final int id;
  final String name;
  final String description;
  final int orderIndex;
  final String backgroundImage;
  final int requiredStars;
  final int totalStages;
  final int completedStages;
  final int completionPercentage;
  final int totalStars;
  final bool isCompleted;
  final bool isUnlocked;

  WorldLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.backgroundImage,
    required this.requiredStars,
    required this.totalStages,
    required this.completedStages,
    required this.completionPercentage,
    required this.totalStars,
    required this.isCompleted,
    required this.isUnlocked,
  });

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == "1";
    return false;
  }

  factory WorldLevel.fromJson(Map<String, dynamic> json) {
    return WorldLevel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      orderIndex: json['order_index'] ?? 0,
      backgroundImage: json['background_image'] ?? '',
      requiredStars: json['required_stars'] ?? 0,
      totalStages: json['total_stages'] ?? 0,
      completedStages: json['completed_stages'] ?? 0,
      completionPercentage: json['completion_percentage'] ?? 0,
      totalStars: json['total_stars'] ?? 0,

      isCompleted: WorldLevel._toBool(json['is_completed']),
      isUnlocked: WorldLevel._toBool(json['is_unlocked']),
    );
  }

  double get progress {
    return totalStages > 0 ? completedStages / totalStages : 0.0;
  }
}
