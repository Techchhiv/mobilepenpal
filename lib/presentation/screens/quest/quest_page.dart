import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_controller.dart';
import 'package:mobilepenpal/presentation/widgets/quest/quest_card.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

/// The main Quest screen that replaces the old Daily Challenge page.
///
/// Layout:
///   1. Top header with title + daily progress ring
///   2. Scrollable list of [QuestCard] widgets
///   3. Bonus section (separated visually)
///   4. Empty state when no quests are available
class QuestPage extends GetView<QuestController> {
  const QuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        isLoading: controller.isStartingQuest.value,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF0F4FF), // soft blue-white
                Color(0xFFFFF8F0), // warm peach-white
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative background bubbles
              _bubble(
                top: -40,
                right: -30,
                size: 130,
                color: const Color(0x22845EF7),
              ),
              _bubble(
                top: 240,
                left: -20,
                size: 90,
                color: const Color(0x224ECDC4),
              ),
              _bubble(
                bottom: 60,
                right: -20,
                size: 110,
                color: const Color(0x22FF6B6B),
              ),

              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Env.globalMaxWidth,
                    ),
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (controller.quests.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildQuestList();
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quest list with header ──────────────────────────────────────
  Widget _buildQuestList() {
    return RefreshIndicator(
      onRefresh: controller.refreshQuests,
      color: const Color(0xFF845EF7),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _buildHeader(),
          const SizedBox(height: 22),

          // ── Quest cards ─────────────────────────────────────
          ...controller.quests.map(
            (q) => QuestCard(
              quest: q,
              onStart: q.isCompleted ? null : () => controller.startQuest(q.id),
            ),
          ),

          // bottom breathing room
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Top header card ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF845EF7), Color(0xFF6C3CE1)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF845EF7).withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left section — title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗡️  ' + 'daily_quests'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    controller.allCompleted
                        ? 'all_quests_completed'.tr
                        : 'quests_done_today'.trParams({
                            'completed': controller.completedCount.toString(),
                            'total': controller.totalQuests.toString(),
                          }),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Streak + XP pills
                Row(
                  children: [
                    _miniPill(
                      icon: Icons.local_fire_department_rounded,
                      label: 'daily_streak_count'.trParams({
                        'streak': controller.dailyStreak.toString(),
                      }),
                      color: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 8),
                    _miniPill(
                      icon: Icons.monetization_on_rounded,
                      label: 'coins_count'.trParams({
                        'coins': controller.totalCoins.toString(),
                      }),
                      color: const Color(0xFFFFB347),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right section — circular progress
          _buildProgressRing(),
        ],
      ),
    );
  }

  // ── Circular progress ring ──────────────────────────────────────
  Widget _buildProgressRing() {
    return Obx(() {
      final total = controller.totalQuests;
      final done = controller.completedCount;
      final pct = total > 0 ? done / total : 0.0;

      return SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Track
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 7,
                color: Colors.white.withValues(alpha: 0.18),
                strokeCap: StrokeCap.round,
              ),
            ),
            // Fill
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: pct,
                strokeWidth: 7,
                color: Colors.white,
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
            // Label
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$done/$total',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'done'.tr.toLowerCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Small info pill widget ──────────────────────────────────────
  Widget _miniPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF845EF7).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 48,
                color: Color(0xFF845EF7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'no_quests_available'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3A3A5C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'complete_lessons_unlock_quests'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => controller.refreshQuests(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('refresh'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF845EF7),
                side: const BorderSide(color: Color(0xFF845EF7)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Decorative bubble ───────────────────────────────────────────
  Widget _bubble({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 26, spreadRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
