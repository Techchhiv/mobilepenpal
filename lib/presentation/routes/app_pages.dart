import 'package:get/get.dart';
import 'package:mobilepenpal/core/bindings/adventure_stage_binding.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/adventure/adventure_stage_page.dart';
import 'package:mobilepenpal/core/bindings/auth_binding.dart';
import 'package:mobilepenpal/core/bindings/classroom_binding.dart';
import 'package:mobilepenpal/core/bindings/home_binding.dart';
import 'package:mobilepenpal/core/bindings/level_binding.dart';
import 'package:mobilepenpal/core/bindings/register_binding.dart';
import 'package:mobilepenpal/core/bindings/report_binding.dart';
import 'package:mobilepenpal/core/bindings/setting_binding.dart';
import 'package:mobilepenpal/core/bindings/stage_binding.dart';
import 'package:mobilepenpal/core/bindings/stage_summary_binding.dart';
import 'package:mobilepenpal/core/bindings/world_binding.dart';
import 'package:mobilepenpal/core/middleware/auth_middleware.dart';
import 'package:mobilepenpal/presentation/screens/auth/login_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/offline_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/register_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/splash_page.dart';
import 'package:mobilepenpal/presentation/screens/classroom/classroom_page.dart';
import 'package:mobilepenpal/presentation/screens/home/home_page.dart';
import 'package:mobilepenpal/presentation/screens/report/report_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/settings/setting_page.dart';
import 'package:mobilepenpal/presentation/screens/world/world_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/world/level_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/world/stage_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/world/stage_summary_page.dart';
import 'app_routes.dart';

import 'package:mobilepenpal/core/bindings/adventure_summary_binding.dart';
import 'package:mobilepenpal/core/bindings/dynamic_mini_game_binding.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/adventure/adventure_page.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/adventure/adventure_summary_page.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/dynamic_mini_game_page.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/mini_game_page.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SplashPage()),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    // GetPage(
    //   name: AppRoutes.otp,
    //   page: () => OtpVerificationPage(),
    //   binding: OtpBinding(),
    // ),
    GetPage(name: AppRoutes.offline, page: () => const OfflinePage()),

    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.setting,
      page: () => SettingPage(),
      binding: SettingBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.world,
      page: () => WorldDetailPage(),
      binding: WorldBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.level,
      page: () => LevelDetailPage(),
      binding: LevelBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.stage,
      page: () => StageDetailPage(),
      binding: StageBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.summary,
      page: () => StageSummaryPage(),
      binding: StageSummaryBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.parentReport,
      page: () => ReportDetailPage(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.classroom,
      page: () {
        final id = int.tryParse(Get.parameters['classroomId'] ?? '') ?? 0;
        return ClassroomPage(classroomId: id);
      },
      binding: ClassroomBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.adventureStage,
      page: () => const AdventureStagePage(),
      binding: AdventureStageBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adventureSummary,
      page: () => const AdventureSummaryPage(),
      binding: AdventureSummaryBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.miniGame,
      page: () => const MiniGamePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adventure,
      page: () => const AdventurePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.dynamicMiniGame,
      page: () => const DynamicMiniGamePage(),
      binding: DynamicMiniGameBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
