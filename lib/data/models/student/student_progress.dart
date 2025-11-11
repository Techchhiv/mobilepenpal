class StudentProgress {
  final int worldId;
  final String worldName;
  final String worldDescription;
  final String? worldImage;
  final String? backgroundImage;
  final bool isCompleted;
  final bool isActive;
  final int totalLessons;
  final int totalStages;
  final int completedLessons;
  final int completedStages;
  final int totalStars;
  final int remainingLessons;
  final int remainingStages;
  final double progressPercentage;

  StudentProgress({
    required this.worldId,
    required this.worldName,
    required this.worldDescription,
    this.worldImage,
    this.backgroundImage,
    required this.isCompleted,
    required this.isActive,
    required this.totalLessons,
    required this.totalStages,
    required this.completedLessons,
    required this.completedStages,
    required this.totalStars,
    required this.remainingLessons,
    required this.remainingStages,
    required this.progressPercentage,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      worldId: json['world_id'] ?? 0,
      worldName: json['world_name'] ?? '',
      worldDescription: json['world_description'] ?? '',
      worldImage: json['world_image'],
      backgroundImage: json['background_image'],
      isCompleted: (json['is_completed'] ?? 0) == 1,
      isActive: (json['is_active'] ?? 0) == 1,
      totalLessons: json['total_lessons'] ?? 0,
      totalStages: json['total_stages'] ?? 0,
      completedLessons: json['completed_lessons'] ?? 0,
      completedStages: json['completed_stages'] ?? 0,
      totalStars: json['total_stars'] ?? 0,
      remainingLessons: json['remaining_lessons'] ?? 0,
      remainingStages: json['remaining_stages'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'world_id': worldId,
      'world_name': worldName,
      'world_description': worldDescription,
      'world_image': worldImage,
      'background_image': backgroundImage,
      'is_completed': isCompleted ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'total_lessons': totalLessons,
      'total_stages': totalStages,
      'completed_lessons': completedLessons,
      'completed_stages': completedStages,
      'total_stars': totalStars,
      'remaining_lessons': remainingLessons,
      'remaining_stages': remainingStages,
      'progress_percentage': progressPercentage,
    };
  }
}