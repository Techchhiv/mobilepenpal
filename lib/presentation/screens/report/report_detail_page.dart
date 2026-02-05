import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/report/report_controller.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key});

  String _d(String s) => NumberFormatUtils.digitsByLocale(s);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ReportController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            const SizedBox(height: 14),

            Expanded(
              child: RefreshIndicator(
                onRefresh: c.fetchMonthly,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSummaryCards(c),
                    const SizedBox(height: 14),

                    _buildChartCard(c),
                    const SizedBox(height: 14),

                    _buildCharacterCard(c),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ReportController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.offNamed('/home'),
            icon: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'report_detail_title'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          _MonthSwitcher(
            label: () => c.monthLabel,
            onPrev: c.prevMonth,
            onNext: c.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final loading = c.isLoading.value && c.monthly.value == null;
        final m = c.monthly.value;

        if (loading) {
          final base = Colors.grey.shade300;
          final highlight = Colors.grey.shade100;

          Widget box({double h = 86, double r = 18}) => Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(r),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(h: 18, r: 8),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: box()),
                  const SizedBox(width: 12),
                  Expanded(child: box()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: box()),
                  const SizedBox(width: 12),
                  Expanded(child: box()),
                ],
              ),
              const SizedBox(height: 12),
              box(h: 56),
            ],
          );
        }

        final attempts = m?.totalStagesCompleted ?? 0;
        final stars = m?.totalStarsEarned ?? 0;
        final accuracy = m?.accuracy ?? 0.0;
        final time = _formatStudyTime(m?.totalTimeSpentSeconds ?? 0);
        final days = m?.practiceDays ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'monthly_summary'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'total_exercises'.tr,
                    value: _d('$attempts'),
                    icon: Icons.menu_book_rounded,
                    tint: const Color(0xFF00897B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'stars'.tr,
                    value: _d('$stars'),
                    icon: Icons.star_rounded,
                    tint: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'practice_days'.tr,
                    value: _d('$days'),
                    icon: Icons.calendar_today_rounded,
                    tint: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'accuracy'.tr,
                    value: _d('${(accuracy * 100).round()}%'),
                    icon: Icons.verified_rounded,
                    tint: const Color(0xFF3B82F6),
                    bottom: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: accuracy.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WideCard(
              title: 'total_study_time'.tr,
              value: _d(time),
              icon: Icons.schedule_rounded,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildChartCard(ReportController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final m = c.monthly.value;
        final loading = c.isLoading.value && m == null;

        final weekly = (m?.weeklyChart ?? [])
          ..sort(
            (a, b) => ((a['week'] as num?)?.toInt() ?? 0).compareTo(
              (b['week'] as num?)?.toInt() ?? 0,
            ),
          );

        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CardIcon(icon: Icons.bar_chart_rounded),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'weekly_exercises_in_month'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              if (loading)
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                )
              else if (weekly.isEmpty)
                SizedBox.shrink()
              else
                SizedBox(
                  height: 190,
                  child: _WeeklyAttemptsBarChart(weekly: weekly),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCharacterCard(ReportController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final m = c.monthly.value;
        final loading = c.isLoading.value && m == null;

        final allRaw = (m?.charactersSummary ?? []);
        final all = allRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final filter = c.charFilter.value;

        final filtered = all.where((e) {
          final char = (e['character'] ?? '').toString();
          return c.matchCharFilter(char, filter);
        }).toList();

        final desc = c.sortAccuracyDesc.value;

        filtered.sort((a, b) {
          final aa = (a['accuracy'] as num?)?.toDouble() ?? 0.0;
          final bb = (b['accuracy'] as num?)?.toDouble() ?? 0.0;
          final cmp = desc ? bb.compareTo(aa) : aa.compareTo(bb);
          if (cmp != 0) return cmp;

          final atA = (a['attempts'] as num?)?.toInt() ?? 0;
          final atB = (b['attempts'] as num?)?.toInt() ?? 0;
          return desc ? atB.compareTo(atA) : atA.compareTo(atB);
        });

        final visibleCount = filtered.length > 5 ? 5 : filtered.length;

        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CardIcon(icon: Icons.insights_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'characters'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Filter button
                  PopupMenuButton<CharacterTypeFilter>(
                    initialValue: c.charFilter.value,
                    onSelected: c.setCharFilter,
                    itemBuilder: (_) =>
                        [
                              CharacterTypeFilter.all,
                              CharacterTypeFilter.consonant,
                              CharacterTypeFilter.vowelIndependent,
                              CharacterTypeFilter.vowelDependent,
                              CharacterTypeFilter.digit,
                            ]
                            .map(
                              (v) => PopupMenuItem(
                                value: v,
                                child: Text(c.charFilterLabel(v)),
                              ),
                            )
                            .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: Colors.grey[800],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.charFilterLabel(c.charFilter.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  InkWell(
                    onTap: c.toggleAccuracySort,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: desc
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(
                        desc
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (loading) ...[
                ReportDetailPage._shimmerLine(),
                const SizedBox(height: 10),
                ReportDetailPage._shimmerLine(),
                const SizedBox(height: 10),
                ReportDetailPage._shimmerLine(),
              ] else ...[
                if (filtered.isEmpty)
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'no_character_data'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: visibleCount * 60.0,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        final char = (e['character'] ?? '—').toString();

                        final accuracy =
                            ((e['accuracy'] as num?)?.toDouble() ?? 0.0).clamp(
                              0.0,
                              1.0,
                            );

                        final attempts = (e['attempts'] as num?)?.toInt() ?? 0;
                        final pct = (accuracy * 100).round();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00897B,
                                  ).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _d('$pct%  •  $attempts ') + 'times'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: accuracy,
                                        minHeight: 6,
                                        backgroundColor: Colors.black
                                            .withValues(alpha: 0.06),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  static Widget _shimmerLine() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static String _formatStudyTime(int seconds) {
    final isKh = Get.find<LocaleController>().isKhmer;

    final hUnit = isKh ? ' ម' : 'h';
    final mUnit = isKh ? ' ន' : 'm';
    final sUnit = isKh ? ' វ' : 's';

    if (seconds <= 0) return '0$mUnit';

    final s = seconds % 60;
    final totalMinutes = seconds ~/ 60;
    final m = totalMinutes % 60;
    final h = totalMinutes ~/ 60;

    if (h > 0) {
      return m > 0 ? '$h$hUnit $m$mUnit' : '$h$hUnit';
    }

    if (m > 0) {
      return s > 0 ? '$m$mUnit $s$sUnit' : '$m$mUnit';
    }

    return '$s$sUnit';
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String Function() label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TinyIconButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
          const SizedBox(width: 6),
          Obx(
            () => Text(
              NumberFormatUtils.digitsByLocale(label()),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          _TinyIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  const _TinyIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF00897B);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.bar_chart_rounded, color: brand, size: 18),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
    this.bottom,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color tint;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 6, child: bottom ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  const _WideCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF00897B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            NumberFormatUtils.digitsByLocale(value),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAttemptsBarChart extends StatelessWidget {
  const _WeeklyAttemptsBarChart({required this.weekly});
  final List<Map<String, dynamic>> weekly;

  @override
  Widget build(BuildContext context) {
    final groups = weekly.map((e) {
      final week = (e['week'] as num?)?.toInt() ?? 1;
      final attempts = (e['attempts'] as num?)?.toDouble() ?? 0;

      return BarChartGroupData(
        x: week,
        barRods: [
          BarChartRodData(
            toY: attempts,
            width: 18,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.buttonPrimary,
          ),
        ],
      );
    }).toList();

    final maxY = weekly
        .map((e) => (e['attempts'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxY <= 5 ? 1 : null,
              getTitlesWidget: (value, meta) => Text(
                NumberFormatUtils.digitsByLocale(value.toInt().toString()),
                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final w = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    NumberFormatUtils.digitsByLocale('${'week'.tr} $w'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                NumberFormatUtils.digitsByLocale('${'week'.tr} ${group.x}\n'),
                TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                children: [
                  TextSpan(
                    text: NumberFormatUtils.digitsByLocale(
                      '${rod.toY.toInt()} ${'attempts'.tr}',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }
}
