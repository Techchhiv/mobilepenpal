import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/core/utils/report_format.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/report/daily_summary.dart';
import 'package:mobilepenpal/data/models/report/weekly_summary.dart';
import 'package:shimmer/shimmer.dart';

class ParentSummaryCard extends StatelessWidget {
  final HomeController homeController;
  const ParentSummaryCard({super.key, required this.homeController});

  static const Color _brand = Color(0xFF00897B);
  static const double _metricBottomHeight = 6;
  static const double _metricBottomSpacing = 10;
  String _d(String s) => NumberFormatUtils.digitsByLocale(s);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "summary".tr,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 24),
        Obx(() {
          final showDaily =
              homeController.summaryView.value == SummaryView.daily;

          final dailyLoading = homeController.isSummaryLoading.value;
          final weeklyLoading = homeController.isWeeklyLoading.value;

          final DailySummary? daily = homeController.dailySummary.value;
          final WeeklySummary? weekly = homeController.weeklySummary.value;

          final showShimmer = showDaily
              ? (dailyLoading && daily == null)
              : (weeklyLoading && weekly == null);

          return _cardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  showDaily: showDaily,
                  dailyDate: daily == null ? '—' : _d(daily.date.toDdMmYy()),
                  weeklyRange: weekly == null
                      ? '—'
                      : _d(
                          '${weekly.fromDate.toDdMmYy()}  →  ${weekly.toDate.toDdMmYy()}',
                        ),
                  isBusy: showDaily ? dailyLoading : weeklyLoading,
                ),
                SizedBox(height: 14),
                _buildAnimatedBody(
                  showDaily: showDaily,
                  showShimmer: showShimmer,
                  daily: daily,
                  weekly: weekly,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: child,
    );
  }

  Widget _buildHeader({
    required bool showDaily,
    required String dailyDate,
    required String weeklyRange,
    required bool isBusy,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.bar_chart_rounded, color: _brand, size: 18),
        ),
        SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showDaily ? 'summary_daily'.tr : 'summary_weekly'.tr,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              SizedBox(height: 2),
              Text(
                showDaily ? dailyDate : weeklyRange,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        _buildToggleIcon(
          isDaily: showDaily,
          isBusy: isBusy,
          onTap: () async => _toggleAndFetch(showDaily),
        ),
      ],
    );
  }

  Widget _buildToggleIcon({
    required bool isDaily,
    required bool isBusy,
    required Future<void> Function() onTap,
  }) {
    final icon = isDaily ? Icons.today_rounded : Icons.date_range_rounded;
    final tooltip = isDaily ? 'weekly'.tr : 'daily'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : () => onTap(),
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: isDaily ? 0.10 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brand.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: isBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _brand,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: Duration(milliseconds: 220),
                      child: Icon(
                        icon,
                        key: ValueKey(icon),
                        color: _brand,
                        size: 20,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAndFetch(bool showDaily) async {
    final next = showDaily ? SummaryView.weekly : SummaryView.daily;
    homeController.summaryView.value = next;

    if (next == SummaryView.daily &&
        homeController.dailySummary.value == null &&
        !homeController.isSummaryLoading.value) {
      await homeController.fetchDailySummary();
    }

    if (next == SummaryView.weekly &&
        homeController.weeklySummary.value == null &&
        !homeController.isWeeklyLoading.value) {
      await homeController.fetchWeeklySummary();
    }
  }

  Widget _buildAnimatedBody({
    required bool showDaily,
    required bool showShimmer,
    required DailySummary? daily,
    required WeeklySummary? weekly,
  }) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: Offset(0.02, 0.02),
          end: Offset.zero,
        ).animate(anim);

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: showDaily
          ? _buildDailyBody(
              key: ValueKey('daily'),
              showShimmer: showShimmer,
              daily: daily,
            )
          : _buildWeeklyBody(
              key: ValueKey('weekly'),
              showShimmer: showShimmer,
              weekly: weekly,
            ),
    );
  }

  Widget _buildDailyBody({
    required Key key,
    required bool showShimmer,
    required DailySummary? daily,
  }) {
    if (showShimmer) return _SummaryShimmer(key: ValueKey('shimmer'));

    return Column(
      key: key,
      children: [
        _buildMetricGrid(
          children: [
            _buildMetricTile(
              title: "lesson_completed".tr,
              value: daily == null ? '—' : _d('${daily.stagesCompleted}'),
              icon: Icons.menu_book_rounded,
              tint: _brand,
            ),
            _buildMetricTile(
              title: "stars".tr,
              value: daily == null ? '—' : _d('${daily.starsEarned}'),
              icon: Icons.star_rounded,
              tint: Color(0xFFF59E0B),
            ),
            _buildMetricTile(
              title: "time".tr,
              value: daily == null
                  ? '—'
                  : _d(daily.timeSpentSeconds.toStudyTime()),
              icon: Icons.schedule_rounded,
              tint: Color(0xFF22C55E),
            ),
            _buildMetricTile(
              title: "accuracy".tr,
              value: daily == null
                  ? '—'
                  : _d('${(daily.accuracy * 100).round()}%'),
              icon: Icons.verified_rounded,
              tint: Color(0xFF3B82F6),
              bottom: daily == null
                  ? null
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: daily.accuracy.clamp(0.0, 1.0),
                        minHeight: _metricBottomHeight,
                        backgroundColor: Colors.grey[200],
                        color: Color(0xFF3B82F6),
                      ),
                    ),
            ),
          ],
        ),

        SizedBox(height: 14),
        Divider(color: Colors.black.withValues(alpha: 0.06)),
        SizedBox(height: 10),

        _buildInsightRow(
          left: _buildInsightChip(
            label: 'best'.tr,
            value: _formatDailyInsight(daily?.bestCharacter),
            icon: Icons.trending_up_rounded,
            color: Color(0xFF16A34A),
          ),
          right: _buildInsightChip(
            label: 'need'.tr,
            value: _formatDailyInsight(daily?.needsAttention),
            icon: Icons.priority_high_rounded,
            color: Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  String _formatDailyInsight(Map<String, dynamic>? insight) {
    if (insight == null) return '—';
    final c = insight['character']?.toString() ?? '—';
    final a = insight['accuracy'];
    final p = a == null ? null : ((a as num).toDouble() * 100).round();
    return p == null ? c : _d('$c  •  $p%');
  }

  Widget _buildWeeklyBody({
    required Key key,
    required bool showShimmer,
    required WeeklySummary? weekly,
  }) {
    if (showShimmer) return _SummaryShimmer(key: ValueKey('shimmer'));

    return Column(
      key: key,
      children: [
        _buildMetricGrid(
          children: [
            _buildMetricTile(
              title: "lesson_completed".tr,
              value: weekly == null
                  ? '—'
                  : _d('${weekly.totalStagesCompleted}'),
              icon: Icons.menu_book_rounded,
              tint: _brand,
            ),
            _buildMetricTile(
              title: "stars".tr,
              value: weekly == null ? '—' : _d('${weekly.totalStarsEarned}'),
              icon: Icons.star_rounded,
              tint: Color(0xFFF59E0B),
            ),
            _buildMetricTile(
              title: "practice_days".tr,
              value: weekly == null ? '—' : _d('${weekly.practiceDays}'),
              icon: Icons.calendar_today_rounded,
              tint: Color(0xFF22C55E),
            ),
            _buildMetricTile(
              title: "accuracy".tr,
              value: weekly == null
                  ? '—'
                  : _d('${(weekly.accuracy * 100).round()}%'),
              icon: Icons.verified_rounded,
              tint: Color(0xFF3B82F6),
              bottom: weekly == null
                  ? null
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: weekly.accuracy.clamp(0.0, 1.0),
                        minHeight: _metricBottomHeight,
                        backgroundColor: Colors.grey[200],
                        color: Color(0xFF3B82F6),
                      ),
                    ),
            ),
          ],
        ),

        SizedBox(height: 14),
        Divider(color: Colors.black.withValues(alpha: 0.06)),
        SizedBox(height: 10),

        _buildInsightRow(
          left: _buildInsightChip(
            label: 'mastered'.tr,
            value: _topChars(weekly?.topMasteredCharacters),
            icon: Icons.auto_awesome_rounded,
            color: Color(0xFF16A34A),
          ),
          right: _buildInsightChip(
            label: 'review'.tr,
            value: _topChars(weekly?.charactersToReview),
            icon: Icons.replay_rounded,
            color: Color(0xFFF97316),
          ),
        ),
      ],
    );
  }

  String _topChars(List<Map<String, dynamic>>? list) {
    final items = list ?? [];
    if (items.isEmpty) return '—';
    final chars = items
        .take(3)
        .map((e) => e['character'])
        .whereType<String>()
        .toList();
    return chars.isEmpty ? '—' : chars.join(' • ');
  }

  Widget _buildMetricGrid({required List<Widget> children}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: children[0]),
            SizedBox(width: 12),
            Expanded(child: children[1]),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: children[2]),
            SizedBox(width: 12),
            Expanded(child: children[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
    Widget? bottom,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: _metricBottomSpacing),
          SizedBox(
            height: _metricBottomHeight,
            child: bottom ?? SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildInsightChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget box({double? w, required double h, double r = 12}) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r),
          ),
        ),
      );
    }

    Widget metricTile() {
      return Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                box(w: 18, h: 18, r: 6),
                SizedBox(width: 8),
                Expanded(child: box(h: 12, r: 8)),
              ],
            ),
            SizedBox(height: 10),
            box(w: 70, h: 22, r: 10),
            SizedBox(height: 10),
            box(h: 6, r: 99),
          ],
        ),
      );
    }

    Widget chip() {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            box(w: 30, h: 30, r: 12),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(w: 50, h: 10, r: 8),
                  SizedBox(height: 6),
                  box(h: 12, r: 8),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: metricTile()),
            SizedBox(width: 12),
            Expanded(child: metricTile()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: metricTile()),
            SizedBox(width: 12),
            Expanded(child: metricTile()),
          ],
        ),
        SizedBox(height: 14),
        Divider(color: Colors.black.withValues(alpha: 0.06)),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: chip()),
            SizedBox(width: 12),
            Expanded(child: chip()),
          ],
        ),
      ],
    );
  }
}
