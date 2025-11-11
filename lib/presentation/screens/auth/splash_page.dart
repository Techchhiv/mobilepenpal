import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/theme/theme_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatelessWidget {
  SplashPage({super.key});

  final ThemeController themeController = Get.find();
  final LocaleController localeController = Get.find();

  void _setLanguageAndNavigate(Locale locale) {
    localeController.changeLocale(locale);
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      style: GoogleFonts.battambang(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhiteOff,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ចុះឈ្មោះប្រើប្រាស់ដើម្បីបង្កើតបទពិសោធន៏ \nនិងចំណេះដឹងផ្សេងៗ',
                      style: GoogleFonts.battambang(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textWhiteOff,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF5ED3C6),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit_note,
                                size: 80,
                                color: Color(0xFF1B6A68),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Khmer PenPal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                  Text(
                    'ជ្រើសរើសភាសា',
                    style: GoogleFonts.battambang(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                      child: Text(
                        'ភាសាខ្មែរ',
                        style: GoogleFonts.battambang(
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
                      child: Text(
                        'English',
                        style: TextStyle(
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
    );
  }
}
