import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobilepenpal/data/models/report/monthly_summary.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/core/utils/report_format.dart';

enum CharacterTypeFilter {
  all,
  consonant,
  vowelIndependent,
  vowelDependent,
  digit,
}

class ReportController extends GetxController {
  final HomeService _homeService = HomeService();

  final isLoading = false.obs;
  final selectedMonth = DateTime.now().obs;

  final monthly = Rxn<MonthlySummary>();

  final sortAccuracyDesc = false.obs;
  void toggleAccuracySort() => sortAccuracyDesc.value = !sortAccuracyDesc.value;

  String get monthKey => DateFormat('yyyy-MM').format(selectedMonth.value);
  String get monthLabel => selectedMonth.value.toShortMonthLabel();

  final charFilter = CharacterTypeFilter.all.obs;

  void setCharFilter(CharacterTypeFilter v) => charFilter.value = v;

  String charFilterLabel(CharacterTypeFilter v) {
    switch (v) {
      case CharacterTypeFilter.all:
        return 'all'.tr;
      case CharacterTypeFilter.consonant:
        return 'consonants'.tr;
      case CharacterTypeFilter.vowelIndependent:
        return 'independent_vowels'.tr;
      case CharacterTypeFilter.vowelDependent:
        return 'dependent_vowels'.tr;
      case CharacterTypeFilter.digit:
        return 'digits'.tr;
    }
  }

  bool matchCharFilter(String ch, CharacterTypeFilter filter) {
    if (filter == CharacterTypeFilter.all) return true;
    final type = _detectKhmerCharType(ch);
    return type == filter;
  }

  CharacterTypeFilter? _detectKhmerCharType(String ch) {
    if (ch.trim().isEmpty) return null;

    final rune = ch.runes.isEmpty ? null : ch.runes.first;
    if (rune == null) return null;

    // Digits: Khmer ០-៩ and also normal 0-9
    final isDigit =
        (rune >= 0x17E0 && rune <= 0x17E9) || (rune >= 0x30 && rune <= 0x39);
    if (isDigit) return CharacterTypeFilter.digit;

    // Khmer consonants: ក (U+1780) ... អ (U+17A2)
    final isConsonant = rune >= 0x1780 && rune <= 0x17A2;
    if (isConsonant) return CharacterTypeFilter.consonant;

    // Khmer independent vowels: U+17A3..U+17B3
    final isIndVowel = rune >= 0x17A3 && rune <= 0x17B3;
    if (isIndVowel) return CharacterTypeFilter.vowelIndependent;

    // Khmer dependent vowels: U+17B4..U+17C5
    final isDepVowel = rune >= 0x17B4 && rune <= 0x17C5;
    if (isDepVowel) return CharacterTypeFilter.vowelDependent;

    return null;
  }

  @override
  void onInit() {
    super.onInit();
    fetchMonthly();
  }

  Future<void> fetchMonthly() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final res = await _homeService.getMonthlySummary(month: monthKey);

      if (res.code == 200 && res.data != null) {
        monthly.value = res.data!;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void prevMonth() {
    final d = selectedMonth.value;
    selectedMonth.value = DateTime(d.year, d.month - 1, 1);
    fetchMonthly();
  }

  void nextMonth() {
    final d = selectedMonth.value;
    selectedMonth.value = DateTime(d.year, d.month + 1, 1);
    fetchMonthly();
  }
}
