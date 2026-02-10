import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';

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

  bool get _isKhmer {
    final locale = Get.locale ?? Get.deviceLocale;
    return (locale?.languageCode.toLowerCase() == 'km');
  }

  String _unitH(int v) => _isKhmer ? '$v ម' : '${v}h';
  String _unitM(int v) => _isKhmer ? '$v ន' : '${v}m';
  String _unitS(int v) => _isKhmer ? '$v វ' : '${v}s';
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
      return '$day/$month/$year';
    } catch (_) {
      return '—';
    }
  }

  String shortMonthLabel(DateTime d) {
    const months = [
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

    return '${months[d.month - 1]} ${d.year}';
  }
}

extension MonthLabelFormat on DateTime {
  String toShortMonthLabel() {
    const months = [
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
    return '${months[month - 1]} $year';
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
      default:
        return NumberFormatUtils.digitsByLocale(raw);
    }
  }
}
