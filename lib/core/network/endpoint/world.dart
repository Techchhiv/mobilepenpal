class WorldEndpoints {
  static const String _base = '/student/v01';

  // Worlds
  static const String worlds = '$_base/worlds';
  static const String world = '$_base/worlds:id';
  static const String level  = '$_base/worlds/level';
  static const String stage  = '$_base/worlds/level/stage';
  static const String submitExercise  = '$_base/worlds/exercise/submit';
  static const String exercises = '$_base/worlds/exercises';

  static String getWorldById(int id) => '$worlds/$id';
  static String getLevelById(int levelId) => '$level/$levelId';
  static String getStageById(int stageId) => '$stage/$stageId';
}
