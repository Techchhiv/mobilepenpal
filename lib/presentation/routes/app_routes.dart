class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/verify_otp';
  static const offline = '/offline';

  static const home = '/home';

  static const world = '/world/:id';
  static const level = '/world/:worldId/level/:levelId';
  static const stage = '/world/:worldId/level/:levelId/stage/:stageId';
  static const summary =
      '/world/:worldId/level/:levelId/stage/:stageId/summary';

  static const parentReport = '/parent/report';

  static const classroom = '/classroom/:classroomId';

  static const questBoard = '/quest/board';
  static const questSummary = '/quest/summary';

  static const setting = '/setting';

  static const miniGame = '/mini-game';

  static const adventure = '/mini-game/adventure';
  static const adventureStage = '/mini-game/adventure/stage';
  static const adventureSummary = '/mini-game/adventure/summary';

  static const dynamicMiniGame = '/mini-game/play';
}
