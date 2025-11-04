import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mobilepenpal/core/theme/app_theme.dart';
import 'package:mobilepenpal/core/theme/theme_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_pages.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'core/localization/app_translations.dart';

void main() async{
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ThemeController themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      
      // ===== Translation =====
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // ========= Route List =========
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    
      // ========= Theme ==========
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.theme,
    );
  }
}