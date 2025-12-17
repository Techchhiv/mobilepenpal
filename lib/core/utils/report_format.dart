extension StudyTimeFormat on int {
  /// API gives seconds.
  /// <60s => "45s"
  /// <60m => "1m 16s"
  /// >=60m => "1h 10m"
  String toStudyTime() {
    if (this <= 0) return '0m';

    final s = this % 60;
    final totalMinutes = this ~/ 60;
    final m = totalMinutes % 60;
    final h = totalMinutes ~/ 60;

    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return s > 0 ? '${m}m ${s}s' : '${m}m';
    return '${s}s';
  }
}

extension StudyDateFormat on String? {
  /// ISO date "YYYY-MM-DD" -> "dd/MM/yy"
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
