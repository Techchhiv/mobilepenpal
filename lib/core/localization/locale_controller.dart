import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleController extends GetxController {
  final _box = GetStorage();
  final _key = 'locale';

  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  void _loadLocale() {
    final storedLocale = _box.read(_key);
    if (storedLocale != null) {
      _locale = Locale(storedLocale['languageCode'], storedLocale['countryCode']);
    } else {
      _locale = const Locale('en', 'US');
    }
    Get.updateLocale(_locale);
  }

  void changeLocale(Locale newLocale) {
    _locale = newLocale;
    _saveLocaleToBox(newLocale);
    Get.updateLocale(newLocale);
  }

  void _saveLocaleToBox(Locale locale) {
    _box.write(_key, {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
    });
  }

  bool get isKhmer => _locale.languageCode == 'km';
}