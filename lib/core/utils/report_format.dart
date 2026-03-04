import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';

bool get _isKhmerLocale {
  final locale = Get.locale ?? Get.deviceLocale;
  return (locale?.languageCode.toLowerCase() == 'km');
}

const _monthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthsKm = [
  'មករា',
  'កុម្ភៈ',
  'មីនា',
  'មេសា',
  'ឧសភា',
  'មិថុនា',
  'កក្កដា',
  'សីហា',
  'កញ្ញា',
  'តុលា',
  'វិច្ឆិកា',
  'ធ្នូ',
];

extension StudyTimeFormat on int {
  String toStudyTime() {
    final seconds = this;
    if (seconds <= 0) return _unitM(0);

    final s = seconds % 60;
    final totalMinutes = seconds ~/ 60;
    final m = totalMinutes % 60;
    final h = totalMinutes ~/ 60;

    if (h > 0) return '${_unitH(h)} ${_unitM(m)}';
    if (m > 0) return s > 0 ? '${_unitM(m)} ${_unitS(s)}' : _unitM(m);
    return _unitS(s);
  }

  String _unitH(int v) => _isKhmerLocale
      ? '${NumberFormatUtils.intText(v, forceKhmer: true)}ម'
      : '${v}h';

  String _unitM(int v) => _isKhmerLocale
      ? '${NumberFormatUtils.intText(v, forceKhmer: true)}ន'
      : '${v}m';

  String _unitS(int v) => _isKhmerLocale
      ? '${NumberFormatUtils.intText(v, forceKhmer: true)}វ'
      : '${v}s';
}

extension StudyDateFormat on String? {
  String toDdMmYy() {
    final iso = this;
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = (d.year % 100).toString().padLeft(2, '0');
      return NumberFormatUtils.digitsByLocale('$day/$month/$year');
    } catch (_) {
      return '—';
    }
  }
}

extension JoinDateLabelOnDateTime on DateTime? {
  String toJoinDateLabel() {
    final d = this;
    if (d == null) return '—';

    final monthName = (_isKhmerLocale ? _monthsKm : _monthsEn)[d.month - 1];
    final day = NumberFormatUtils.digitsByLocale(d.day.toString());
    final year = NumberFormatUtils.digitsByLocale(d.year.toString());

    return '$day $monthName $year';
  }
}

extension MonthLabelFormat on DateTime {
  String toShortMonthLabel() => '${_monthsEn[month - 1]} $year';
}

extension MonthLabelLocaleFormat on String {
  String toMonthLabelByLocale() {
    final raw = trim();
    if (raw.isEmpty) return raw;

    if (!_isKhmerLocale) return NumberFormatUtils.digitsByLocale(raw);

    String out = raw;

    String rep(RegExp r, String km) {
      out = out.replaceAllMapped(r, (_) => km);
      return out;
    }

    rep(RegExp(r'\bjan(?:uary)?\b', caseSensitive: false), 'មករា');
    rep(RegExp(r'\bfeb(?:ruary)?\b', caseSensitive: false), 'កុម្ភៈ');
    rep(RegExp(r'\bmar(?:ch)?\b', caseSensitive: false), 'មីនា');
    rep(RegExp(r'\bapr(?:il)?\b', caseSensitive: false), 'មេសា');
    rep(RegExp(r'\bmay\b', caseSensitive: false), 'ឧសភា');
    rep(RegExp(r'\bjun(?:e)?\b', caseSensitive: false), 'មិថុនា');
    rep(RegExp(r'\bjul(?:y)?\b', caseSensitive: false), 'កក្កដា');
    rep(RegExp(r'\baug(?:ust)?\b', caseSensitive: false), 'សីហា');
    rep(RegExp(r'\bsep(?:tember)?\b', caseSensitive: false), 'កញ្ញា');
    rep(RegExp(r'\boct(?:ober)?\b', caseSensitive: false), 'តុលា');
    rep(RegExp(r'\bnov(?:ember)?\b', caseSensitive: false), 'វិច្ឆិកា');
    rep(RegExp(r'\bdec(?:ember)?\b', caseSensitive: false), 'ធ្នូ');

    return NumberFormatUtils.digitsByLocale(out, forceKhmer: true);
  }
}

extension ReportCharacterFormat on String? {
  String toReportCharacterLabel() {
    final raw = (this ?? '').trim();
    if (raw.isEmpty) return '—';

    final key = raw.contains(':')
        ? raw.split(':').last.trim().toLowerCase()
        : raw.toLowerCase();

    switch (key) {
      case 'add':
        return '+';
      case 'sub':
        return '-';
      case 'mul':
        return '×';
      case 'div':
        return '÷';
      case 'math':
        return 'math'.tr;
      default:
        return NumberFormatUtils.digitsByLocale(raw);
    }
  }
}
