import 'package:get/get.dart';

class NumberFormatUtils {
  NumberFormatUtils._();

  static const Map<String, String> _latinToKhmer = {
    '0': '០',
    '1': '១',
    '2': '២',
    '3': '៣',
    '4': '៤',
    '5': '៥',
    '6': '៦',
    '7': '៧',
    '8': '៨',
    '9': '៩',
  };

  static const Map<String, int> _khmerToLatin = {
    '០': 0,
    '១': 1,
    '២': 2,
    '៣': 3,
    '៤': 4,
    '៥': 5,
    '៦': 6,
    '៧': 7,
    '៨': 8,
    '៩': 9,
  };

  static bool get _isKhmerLocale {
    final locale = Get.locale ?? Get.deviceLocale;
    return (locale?.languageCode.toLowerCase() == 'km');
  }

  static String digitsByLocale(String input, {bool? forceKhmer}) {
    final useKh = forceKhmer ?? _isKhmerLocale;
    if (!useKh) return input;

    final buf = StringBuffer();
    for (final ch in input.split('')) {
      buf.write(_latinToKhmer[ch] ?? ch);
    }
    return buf.toString();
  }

  static String fraction(int a, int b, {bool? forceKhmer}) {
    return digitsByLocale('$a/$b', forceKhmer: forceKhmer);
  }

  static String intText(int n, {bool? forceKhmer}) {
    return digitsByLocale(n.toString(), forceKhmer: forceKhmer);
  }

  static int? parseSingleDigitAny(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final ascii = int.tryParse(s);
    if (ascii != null && ascii >= 0 && ascii <= 9) return ascii;

    if (s.length == 1) return _khmerToLatin[s];
    return null;
  }

  static int? parseIntAny(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final buf = StringBuffer();

    for (final ch in s.split('')) {
      final ascii = int.tryParse(ch);
      if (ascii != null && ascii >= 0 && ascii <= 9) {
        buf.write(ch);
        continue;
      }

      final kh = _khmerToLatin[ch];
      if (kh != null) {
        buf.write(kh.toString());
        continue;
      }
    }

    final out = buf.toString();
    if (out.isEmpty) return null;

    return int.tryParse(out);
  }
}
