class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/verify_otp';
  static const home = '/home';

  static const world = '/world/:id';
  static const level = '/world/:worldId/level/:levelId';
  static const stage = '/world/:worldId/level/:levelId/stage/:stageId';
  static const summary = '/world/:worldId/level/:levelId/stage/:stageId/summary';

  static const setting = '/setting';
}
