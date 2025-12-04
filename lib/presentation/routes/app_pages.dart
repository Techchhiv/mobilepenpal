import 'package:get/get.dart';
import 'package:mobilepenpal/core/bindings/auth_binding.dart';
import 'package:mobilepenpal/core/bindings/home_binding.dart';
import 'package:mobilepenpal/core/bindings/level_binding.dart';
import 'package:mobilepenpal/core/bindings/otp_binding.dart';
import 'package:mobilepenpal/core/bindings/setting_binding.dart';
import 'package:mobilepenpal/core/bindings/stage_binding.dart';
import 'package:mobilepenpal/core/bindings/world_binding.dart';
import 'package:mobilepenpal/presentation/screens/auth/login_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/otp_verification_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/splash_page.dart';
import 'package:mobilepenpal/presentation/screens/home/home_page.dart';
import 'package:mobilepenpal/presentation/screens/settings/setting_page.dart';
import 'package:mobilepenpal/presentation/screens/world/course_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/world/level_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/world/stage_detail_page.dart';
import 'package:mobilepenpal/presentation/screens/world/stage_summary_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SplashPage()),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => OtpVerificationPage(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),

    GetPage(
      name: AppRoutes.setting,
      page: () => SettingPage(),
      binding: SettingBinding(),
    ),

    GetPage(
      name: AppRoutes.world,
      page: () => CourseDetailPage(),
      binding: WorldBinding(),
    ),

    GetPage(
      name: AppRoutes.level,
      page: () => LevelDetailPage(),
      binding: LevelBinding(),
    ),

    GetPage(
      name: AppRoutes.stage,
      page: () => StageDetailPage(),
      binding: StageBinding(),
    ),

    GetPage(name: AppRoutes.summary, page: () => StageSummaryPage()),
  ];
}
