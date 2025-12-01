class StudentProgress {
  int id;
  String name;
  String description;
  String? iconUrl;
  String? mapImageUrl;
  String themeColor;
  bool isUnlocked;
  bool isCompleted;
  int levelsCompleted;
  int levelsTotal;
  int levelsRemaining;

  StudentProgress({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.mapImageUrl,
    required this.themeColor,
    required this.isUnlocked,
    required this.isCompleted,
    required this.levelsCompleted,
    required this.levelsTotal,
    required this.levelsRemaining,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      mapImageUrl: json['map_image_url'] as String?,
      themeColor: json['theme_color'] as String? ?? '#000000',
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      levelsCompleted: json['levels_completed'] as int? ?? 0,
      levelsTotal: json['levels_total'] as int? ?? 0,
      levelsRemaining: json['levels_remaining'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['icon_url'] = iconUrl;
    data['map_image_url'] = mapImageUrl;
    data['theme_color'] = themeColor;
    data['is_unlocked'] = isUnlocked;
    data['is_completed'] = isCompleted;
    data['levels_completed'] = levelsCompleted;
    data['levels_total'] = levelsTotal;
    data['levels_remaining'] = levelsRemaining;
    return data;
  }
}