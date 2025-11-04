import 'package:get/get.dart';
import 'en_US.dart';
import 'km_KH.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'km_KH': kmKH,
      };
}
