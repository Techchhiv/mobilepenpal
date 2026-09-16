import 'dart:convert';
import 'dart:developer' as dev;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CountryCode {
  final String name;
  final String code; // ISO 3166-1 alpha-2
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  static const CountryCode defaultCountry = CountryCode(
    name: 'Cambodia',
    code: 'KH',
    dialCode: '+855',
    flag: '🇰🇭',
  );

  /// Comprehensive list of countries sorted in alphabetical order
  static final List<CountryCode> allCountries = [
    const CountryCode(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
    const CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    const CountryCode(name: 'Austria', code: 'AT', dialCode: '+43', flag: '🇦🇹'),
    const CountryCode(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
    const CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    const CountryCode(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
    const CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    const CountryCode(name: 'Brunei', code: 'BN', dialCode: '+673', flag: '🇧🇳'),
    const CountryCode(name: 'Cambodia', code: 'KH', dialCode: '+855', flag: '🇰🇭'),
    const CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    const CountryCode(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
    const CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    const CountryCode(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
    const CountryCode(name: 'Czech Republic', code: 'CZ', dialCode: '+420', flag: '🇨🇿'),
    const CountryCode(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
    const CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
    const CountryCode(name: 'Finland', code: 'FI', dialCode: '+358', flag: '🇫🇮'),
    const CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    const CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    const CountryCode(name: 'Greece', code: 'GR', dialCode: '+30', flag: '🇬🇷'),
    const CountryCode(name: 'Hong Kong', code: 'HK', dialCode: '+852', flag: '🇭🇰'),
    const CountryCode(name: 'Hungary', code: 'HU', dialCode: '+36', flag: '🇭🇺'),
    const CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    const CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    const CountryCode(name: 'Ireland', code: 'IE', dialCode: '+353', flag: '🇮🇪'),
    const CountryCode(name: 'Israel', code: 'IL', dialCode: '+972', flag: '🇮🇱'),
    const CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    const CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    const CountryCode(name: 'Jordan', code: 'JO', dialCode: '+962', flag: '🇯🇴'),
    const CountryCode(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
    const CountryCode(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
    const CountryCode(name: 'Laos', code: 'LA', dialCode: '+856', flag: '🇱🇦'),
    const CountryCode(name: 'Macau', code: 'MO', dialCode: '+853', flag: '🇲🇴'),
    const CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    const CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    const CountryCode(name: 'Mongolia', code: 'MN', dialCode: '+976', flag: '🇲🇳'),
    const CountryCode(name: 'Morocco', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
    const CountryCode(name: 'Myanmar', code: 'MM', dialCode: '+95', flag: '🇲🇲'),
    const CountryCode(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '🇳🇵'),
    const CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    const CountryCode(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
    const CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    const CountryCode(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
    const CountryCode(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
    const CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    const CountryCode(name: 'Peru', code: 'PE', dialCode: '+51', flag: '🇵🇪'),
    const CountryCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
    const CountryCode(name: 'Poland', code: 'PL', dialCode: '+48', flag: '🇵🇱'),
    const CountryCode(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '🇵🇹'),
    const CountryCode(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
    const CountryCode(name: 'Romania', code: 'RO', dialCode: '+40', flag: '🇷🇴'),
    const CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    const CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    const CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    const CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    const CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    const CountryCode(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '🇱🇰'),
    const CountryCode(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
    const CountryCode(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    const CountryCode(name: 'Taiwan', code: 'TW', dialCode: '+886', flag: '🇹🇼'),
    const CountryCode(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
    const CountryCode(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
    const CountryCode(name: 'Ukraine', code: 'UA', dialCode: '+380', flag: '🇺🇦'),
    const CountryCode(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    const CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    const CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    const CountryCode(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
  ];

  static CountryCode findByCode(String code) {
    final upper = code.trim().toUpperCase();
    return allCountries.firstWhere(
      (c) => c.code == upper,
      orElse: () => defaultCountry,
    );
  }

  static CountryCode findByDialCode(String dialCode) {
    final clean = dialCode.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final withPlus = clean.startsWith('+') ? clean : '+$clean';
    return allCountries.firstWhere(
      (c) => c.dialCode == withPlus,
      orElse: () => defaultCountry,
    );
  }

  /// Detects the user's country code based on device system region and background IP lookup
  static Future<CountryCode> detectUserCountry() async {
    // 1. Check device locale first (instant, 0ms)
    final deviceCountry = Get.deviceLocale?.countryCode;
    if (deviceCountry != null && deviceCountry.isNotEmpty) {
      final matched = allCountries.firstWhereOrNull(
        (c) => c.code.toUpperCase() == deviceCountry.toUpperCase(),
      );
      if (matched != null) {
        dev.log('Detected country from device locale: ${matched.name} (${matched.dialCode})', name: 'CountryCode');
        return matched;
      }
    }

    // 2. Try lightweight IP geolocation lookup with 2s timeout
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=countryCode'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ipCountry = data['countryCode']?.toString();
        if (ipCountry != null && ipCountry.isNotEmpty) {
          final matched = allCountries.firstWhereOrNull(
            (c) => c.code.toUpperCase() == ipCountry.toUpperCase(),
          );
          if (matched != null) {
            dev.log('Detected country from IP geolocation: ${matched.name} (${matched.dialCode})', name: 'CountryCode');
            return matched;
          }
        }
      }
    } catch (e) {
      dev.log('IP geolocation check skipped/failed: $e', name: 'CountryCode');
    }

    // 3. Fallback to Cambodia default
    return defaultCountry;
  }
}
