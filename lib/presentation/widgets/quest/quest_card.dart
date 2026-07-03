import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/models/quest/quest.dart';
import 'package:mobilepenpal/data/models/quest/quest_type.dart';

/// A richly styled, reusable card that displays a single [Quest].
///
/// Shows the quest title, subtitle/reason, a preview of characters to
/// practice, a progress bar, XP reward badge, and a start/completed button.
/// Completed quests get distinct muted styling.
class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onStart;

  const QuestCard({super.key, required this.quest, this.onStart});

  static const Map<QuestType, IconData> _icons = {
    QuestType.weakestCharacters: Icons.whatshot_rounded,
    QuestType.recentReview: Icons.history_rounded,
    QuestType.randomReview: Icons.shuffle_rounded,
    QuestType.masteryShowcase: Icons.star_rounded,
    QuestType.deepMemory: Icons.psychology_rounded,
  };

  IconData get _icon => _icons[quest.type] ?? Icons.quiz_rounded;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: quest.isCompleted ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: quest.isCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF1E293B),
            width: 3.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E293B),
              offset: Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // ── Header strip ──────────────────────────────────
              _buildHeader(),
              // Divider border line
              Container(
                height: 2.5,
                color: const Color(0xFF1E293B),
              ),
              // ── Body ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCharacterPreview(),
                    const SizedBox(height: 14),
                    _buildProgressSection(),
                    const SizedBox(height: 14),
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with icon, title, subtitle ───────────────────────────
  Widget _buildHeader() {
    final titleColor = const Color(0xFF1E293B);
    final subtitleColor = const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: quest.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFDDD6FE),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1E293B),
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              quest.isCompleted ? Icons.check_circle_rounded : _icon,
              color: quest.isCompleted ? const Color(0xFF10B981) : const Color(0xFF845EF7),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  quest.subtitle.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          // Reward badge
          _buildRewardBadge(),
        ],
      ),
    );
  }

  // ── Coin reward badge ───────────────────────────────────────────
  Widget _buildRewardBadge() {
    final badgeColor = quest.isCompleted ? const Color(0xFF64748B) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, size: 14, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            '+${NumberFormatUtils.intText(quest.rewardCoins)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Character preview bubbles ───────────────────────────────────
  Widget _buildCharacterPreview() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: quest.previewCharacters.map((char) {
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: quest.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E293B),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1E293B),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            char,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: quest.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Progress bar + label ────────────────────────────────────────
  Widget _buildProgressSection() {
    final pct = quest.progressFraction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              quest.isCompleted ? 'completed_exclamation'.tr : 'progress'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: quest.isCompleted
                    ? const Color(0xFF10B981)
                    : const Color(0xFF64748B),
              ),
            ),
            Text(
              NumberFormatUtils.fraction(quest.progress, quest.total),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: quest.isCompleted ? const Color(0xFF10B981) : const Color(0xFF845EF7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Outlined Track
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF1E293B), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    color: Colors.white,
                  ),
                  // Filled portion
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        color: quest.isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF845EF7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Start / completed button ────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    if (quest.isCompleted) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B), width: 2.5),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                'completed_exclamation'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onStart,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF845EF7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E293B),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'start_quest'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
