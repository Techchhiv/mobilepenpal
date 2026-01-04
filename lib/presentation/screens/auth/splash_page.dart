import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/theme/theme_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class SplashPage extends StatelessWidget {
  SplashPage({super.key});

  final ThemeController themeController = Get.find();
  final LocaleController localeController = Get.find();

  void _setLanguageAndNavigate(Locale locale) {
    localeController.changeLocale(locale);

    final box = GetStorage();
    final token = box.read('token');
    final hasToken = token != null && token.toString().trim().isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasToken) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Image.asset(
                      'assets/images/decorations/bg_circle_1.png',
                      width: 120,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 550,
                    right: 30,
                    child: Image.asset(
                      'assets/images/decorations/bg_square_1.png',
                      width: 120,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 300,
                    right: 0,
                    left: 0,
                    child: Image.asset(
                      'assets/images/decorations/bg_line_dash.png',
                      width: 120,
                    ),
                  ),
                  Positioned(
                    bottom: 280,
                    left: 0,
                    child: Image.asset(
                      'assets/images/decorations/bg_triangle_1.png',
                      width: 120,
                    ),
                  ),
                  Positioned(
                    bottom: 200,
                    right: 0,
                    child: Image.asset(
                      'assets/images/decorations/bg_circle_2.png',
                      width: 120,
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.asset(
                        'assets/images/decorations/bg_curvy_line_1.png',
                        width: 120,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 60.0,
                      left: 30.0,
                      right: 30.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'សូមស្វាគមន៍',
                          style: const TextStyle(
                            fontFamily: 'Battambang',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColors.textWhiteOff,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ចុះឈ្មោះប្រើប្រាស់ដើម្បីបង្កើតបទពិសោធន៏ \nនិងចំណេះដឹងផ្សេងៗ',
                          style: const TextStyle(
                            fontFamily: 'Battambang',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: AppColors.textWhiteOff,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: Image.asset(
                                  'assets/images/illustrations/writing.png',
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Khmer PenPal',
                                style: TextStyle(
                                  fontFamily: 'Battambang',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textWhiteOff,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    bottom: 30.0,
                    left: 20.0,
                    right: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'ជ្រើសរើសភាសា',
                        style: TextStyle(
                          fontFamily: 'Battambang',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: AppColors.textWhiteOff,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _setLanguageAndNavigate(const Locale('km', 'KH')),
                          child: const Text(
                            'ភាសាខ្មែរ',
                            style: TextStyle(
                              fontFamily: 'Battambang',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhiteOff,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _setLanguageAndNavigate(const Locale('en', 'US')),
                          child: const Text(
                            'English',
                            style: TextStyle(
                              fontFamily: 'Battambang',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhiteOff,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
