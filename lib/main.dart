import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Condition;
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mobilepenpal/core/bindings/app_binding.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:mobilepenpal/core/theme/app_theme.dart';
import 'package:mobilepenpal/core/theme/theme_controller.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/firebase_options.dart';
import 'package:mobilepenpal/presentation/routes/app_pages.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'core/localization/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GetStorage.init();

  String? token;
  bool readSuccessful = false;
  try {
    const secure = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
    token = await secure.read(key: Env.accessToken);
    readSuccessful = true;
  } catch (e) {
    debugPrint('SECURE STORAGE ERROR AT STARTUP: $e');
  }

  final storedLoggedIn = GetStorage().read('is_logged_in') == true;
  final storedHasToken = GetStorage().read('has_token') == true;

  final isLoggedIn = readSuccessful
      ? (token != null && token.trim().isNotEmpty)
      : (storedLoggedIn && storedHasToken);

  if (readSuccessful) {
    await GetStorage().write('is_logged_in', isLoggedIn);
    await GetStorage().write('has_token', isLoggedIn);
  }

  OnnxInferenceService.instance.init();

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

      // ========= Responsive Scaling ==========
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: Builder(
          builder: (context) {
            final mediaQuery = MediaQuery.of(context);
            final isLandscape = mediaQuery.orientation == Orientation.landscape;

            if (isLandscape) {
              final isTablet =
                  mediaQuery.size.shortestSide > AppConstants.mobileBreakpoint;
              final designHeight = isTablet
                  ? AppConstants.tabletDesignHeight
                  : AppConstants.mobileDesignHeight;

              final virtualWidth =
                  mediaQuery.size.width *
                  (designHeight / mediaQuery.size.height);

              return ResponsiveScaledBox(width: virtualWidth, child: child!);
            }

            return ResponsiveScaledBox(
              width: ResponsiveValue<double>(
                context,
                defaultValue: AppConstants.mobileDesignWidth,
                conditionalValues: [
                  Condition<double>.between(
                    start: 0,
                    end: AppConstants.mobileBreakpoint,
                    value: AppConstants.mobileDesignWidth,
                  ),
                  Condition<double>.between(
                    start: AppConstants.mobileBreakpoint + 1,
                    end: AppConstants.tabletBreakpoint,
                    value: AppConstants.tabletDesignWidth,
                  ),
                  Condition<double>.largerThan(
                    name: TABLET,
                    value: AppConstants.desktopDesignWidth,
                  ),
                ],
              ).value,
              child: child!,
            );
          },
        ),
        breakpoints: [
          Breakpoint(
            start: 0,
            end: AppConstants.mobileBreakpoint.toDouble(),
            name: MOBILE,
          ),
          Breakpoint(
            start: (AppConstants.mobileBreakpoint + 1).toDouble(),
            end: AppConstants.tabletBreakpoint.toDouble(),
            name: TABLET,
          ),
          Breakpoint(
            start: (AppConstants.tabletBreakpoint + 1).toDouble(),
            end: double.infinity,
            name: DESKTOP,
          ),
        ],
      ),

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

      // Firebase Analytics Route Observer
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],

      // ========= Theme ==========
      theme: AppTheme.lightTheme(localeController.locale.languageCode),
      darkTheme: AppTheme.darkTheme(localeController.locale.languageCode),
      themeMode: themeController.theme,
    );
  }
}
