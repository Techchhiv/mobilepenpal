class WorldLevel {
  final int id;

  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;

  final int orderIndex;
  final int requiredStars;

  final int totalStages;
  final int completedStages;
  final int completionPercentage;

  final int totalStars;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isPremium;
  final bool isLockedBySubscription;

  WorldLevel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.orderIndex,
    required this.requiredStars,
    required this.totalStages,
    required this.completedStages,
    required this.completionPercentage,
    required this.totalStars,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isPremium,
    required this.isLockedBySubscription,
  });

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == "1" || value.toLowerCase() == "true";
    return false;
  }

  factory WorldLevel.fromJson(Map<String, dynamic> json) {
    return WorldLevel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      nameEn: (json['name_en'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      descriptionEn: (json['description_en'] ?? '') as String,
      orderIndex: (json['order_index'] ?? 0) as int,
      requiredStars: (json['required_stars'] ?? 0) as int,
      totalStages: (json['total_stages'] ?? 0) as int,
      completedStages: (json['completed_stages'] ?? 0) as int,
      completionPercentage: (json['completion_percentage'] ?? 0) as int,
      totalStars: (json['total_stars'] ?? 0) as int,
      isCompleted: _toBool(json['is_completed']),
      isUnlocked: _toBool(json['is_unlocked']),
      isPremium: _toBool(json['is_premium']),
      isLockedBySubscription: _toBool(json['is_locked_by_subscription']),
    );
  }

  double get progress => totalStages > 0 ? completedStages / totalStages : 0.0;
}
