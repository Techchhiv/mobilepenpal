import 'package:get/get.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';

String pickLang({
  String? km,
  String? en,
  String fallback = '—',
}) {
  final lc = Get.find<LocaleController>();
  final primary = lc.isKhmer ? km : en;
  final secondary = lc.isKhmer ? en : km;

  if (primary != null && primary.trim().isNotEmpty) return primary.trim();
  if (secondary != null && secondary.trim().isNotEmpty) return secondary.trim();
  return fallback;
}