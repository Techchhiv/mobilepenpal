import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/core/utils/report_format.dart';
import 'package:mobilepenpal/data/controllers/report/report_controller.dart';
import 'package:shimmer/shimmer.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key});

  static const Color _brand = Color(0xFF00897B);

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
                color: _brand,
                onRefresh: () => c.fetchMonthly(force: true),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'report_detail_title'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
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
          final base = Colors.grey.shade200;
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
                  const SizedBox(width: 10),
                  Expanded(child: box()),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: box()),
                  const SizedBox(width: 10),
                  Expanded(child: box()),
                ],
              ),
              const SizedBox(height: 10),
              box(h: 56),
            ],
          );
        }

        final attempts = m?.totalStagesCompleted ?? 0;
        final stars = m?.totalStarsEarned ?? 0;
        final accuracy = m?.accuracy ?? 0.0;
        final time = (m?.totalTimeSpentSeconds ?? 0).toStudyTime();
        final days = m?.practiceDays ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'monthly_summary'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'total_exercises'.tr,
                    value: _d('$attempts'),
                    icon: Icons.menu_book_rounded,
                    tint: _brand,
                  ),
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 10),
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
                const SizedBox(width: 10),
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
                        backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'weekly_exercises_in_month'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (loading)
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
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
                const SizedBox.shrink()
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
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),

                  // Filter button
                  PopupMenuButton<CharacterTypeFilter>(
                    initialValue: c.charFilter.value,
                    onSelected: c.setCharFilter,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    itemBuilder: (_) =>
                        [
                              CharacterTypeFilter.all,
                              CharacterTypeFilter.consonant,
                              CharacterTypeFilter.vowelIndependent,
                              CharacterTypeFilter.vowelDependent,
                              CharacterTypeFilter.digit,
                              // CharacterTypeFilter.math, // TODO: re-enable when math is added
                            ]
                            .map(
                              (v) => PopupMenuItem(
                                value: v,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c.charFilter.value == v
                                            ? _brand
                                            : Colors.transparent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.charFilterLabel(v),
                                      style: TextStyle(
                                        fontWeight: c.charFilter.value == v
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: c.charFilter.value == v
                                            ? _brand
                                            : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _brand.withValues(alpha: 0.08),
                            _brand.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _brand.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: _brand,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.charFilterLabel(c.charFilter.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _brand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: c.toggleAccuracySort,
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: desc
                                ? [
                                    _brand.withValues(alpha: 0.12),
                                    _brand.withValues(alpha: 0.06),
                                  ]
                                : [
                                    Colors.black.withValues(alpha: 0.05),
                                    Colors.black.withValues(alpha: 0.03),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: desc
                                ? _brand.withValues(alpha: 0.18)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Icon(
                          desc
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 16,
                          color: desc ? _brand : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'no_character_data'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: visibleCount * 68.0,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.grey.withValues(alpha: 0.12),
                              Colors.grey.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.15, 0.85, 1.0],
                          ),
                        ),
                      ),
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        final charRaw = (e['character'] ?? '—').toString();
                        final char = charRaw.toReportCharacterLabel();

                        final accuracy =
                            ((e['accuracy'] as num?)?.toDouble() ?? 0.0).clamp(
                              0.0,
                              1.0,
                            );

                        final attempts = (e['attempts'] as num?)?.toInt() ?? 0;
                        final pct = (accuracy * 100).round();

                        // Color based on accuracy
                        final accColor = accuracy >= 0.8
                            ? const Color(0xFF16A34A)
                            : accuracy >= 0.5
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              // Character avatar
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _brand.withValues(alpha: 0.12),
                                      _brand.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _brand.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _d('$pct%'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: accColor,
                                          ),
                                        ),
                                        Text(
                                          '  •  ',
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _d('$attempts ') + 'times'.tr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: accuracy,
                                        minHeight: 5,
                                        backgroundColor: accColor.withValues(alpha: 0.10),
                                        color: accColor,
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
      baseColor: Colors.grey.shade200,
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

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
              label().toMonthLabelByLocale(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF1A1A2E),
              ),
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
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Gradient accent bar at top
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00897B),
                    Color(0xFF26A69A),
                    Color(0xFF4DB6AC),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00897B),
            Color(0xFF26A69A),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.07),
            tint.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: tint),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.50),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.5,
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

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _brand.withValues(alpha: 0.08),
            _brand.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brand.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _brand, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          Text(
            NumberFormatUtils.digitsByLocale(value),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1A1A2E),
            ),
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
            width: 20,
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFF00897B),
                Color(0xFF26A69A),
              ],
            ),
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY <= 5 ? 1 : null,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
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
              maxIncluded: false,
              reservedSize: 32,
              interval: maxY <= 5 ? 1 : null,
              getTitlesWidget: (value, meta) => Text(
                NumberFormatUtils.digitsByLocale(value.toInt().toString()),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
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
                      color: Colors.grey[500],
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
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                NumberFormatUtils.digitsByLocale('${'week'.tr} ${group.x}\n'),
                const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
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
