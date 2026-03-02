class StudentProgress {
  final int id;

  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;

  final bool isUnlocked;
  final bool isCompleted;
  final bool isPremium;
  final bool isLockedBySubscription;

  final int levelsCompleted;
  final int levelsTotal;
  final int levelsRemaining;

  StudentProgress({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isPremium,
    required this.isLockedBySubscription,
    required this.levelsCompleted,
    required this.levelsTotal,
    required this.levelsRemaining,
  });

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == "1" || v.toLowerCase() == "true";
    return false;
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      nameEn: (json['name_en'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      descriptionEn: (json['description_en'] ?? '') as String,
      isUnlocked: _toBool(json['is_unlocked']),
      isCompleted: _toBool(json['is_completed']),
      isPremium: _toBool(json['is_premium']),
      isLockedBySubscription: _toBool(json['is_locked_by_subscription']),
      levelsCompleted: (json['levels_completed'] ?? 0) as int,
      levelsTotal: (json['levels_total'] ?? 0) as int,
      levelsRemaining: (json['levels_remaining'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_en': nameEn,
    'description': description,
    'description_en': descriptionEn,
    'is_unlocked': isUnlocked,
    'is_completed': isCompleted,
    'is_premium': isPremium,
    'is_locked_by_subscription': isLockedBySubscription,
    'levels_completed': levelsCompleted,
    'levels_total': levelsTotal,
    'levels_remaining': levelsRemaining,
  };

  // optional helpers
  double get progress =>
      levelsTotal > 0 ? (levelsCompleted / levelsTotal) : 0.0;

  bool get completed => levelsTotal > 0 && levelsCompleted >= levelsTotal;
}
