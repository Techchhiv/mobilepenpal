import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:mobilepenpal/core/bindings/app_binding.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';

import 'package:mobilepenpal/core/theme/app_theme.dart';
import 'package:mobilepenpal/core/theme/theme_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_pages.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'core/localization/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GetStorage.init();

  const secure = FlutterSecureStorage();
  final token = await secure.read(key: Env.accessToken);
  final isLoggedIn = token != null && token.trim().isNotEmpty;

  await GetStorage().write('is_logged_in', isLoggedIn);

  runApp(MyApp(initialRoute: isLoggedIn ? AppRoutes.home : AppRoutes.splash));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({super.key, required this.initialRoute});

  final ThemeController themeController = Get.put(ThemeController());
  final LocaleController localeController = Get.put(LocaleController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      // ========= Transition ==========
      defaultTransition: Transition.cupertino,
      transitionDuration: Duration(milliseconds: 250),

      // ====== Message ======
      scaffoldMessengerKey: AppSnackbar.messengerKey,

      // ===== Translation =====
      translations: AppTranslations(),
      locale: localeController.locale,
      fallbackLocale: const Locale('en', 'US'),

      // ========= Route List =========
      initialRoute: initialRoute,
      getPages: AppPages.routes,

      // Initialize global dependencies
      initialBinding: AppBinding(),

      // ========= Theme ==========
      theme: AppTheme.lightTheme(localeController.locale.languageCode),
      darkTheme: AppTheme.darkTheme(localeController.locale.languageCode),
      themeMode: themeController.theme,
    );
  }
}
