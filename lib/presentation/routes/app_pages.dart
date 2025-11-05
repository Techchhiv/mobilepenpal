import 'package:get/get.dart';
import 'package:mobilepenpal/core/bindings/auth_binding.dart';
import 'package:mobilepenpal/core/bindings/home_binding.dart';
import 'package:mobilepenpal/core/bindings/otp_binding.dart';
import 'package:mobilepenpal/presentation/screens/auth/login_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/otp_verification_page.dart';
import 'package:mobilepenpal/presentation/screens/auth/splash_page.dart';
import 'package:mobilepenpal/presentation/screens/home/home_page.dart';
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
  ];
}
