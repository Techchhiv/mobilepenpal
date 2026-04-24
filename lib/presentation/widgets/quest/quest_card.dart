import 'package:flutter/material.dart';
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

  // ── Color palette per quest type ────────────────────────────────
  static const Map<QuestType, List<Color>> _gradients = {
    QuestType.weakestCharacters: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    QuestType.recentReview: [Color(0xFF4ECDC4), Color(0xFF6EE7DE)],
    QuestType.randomReview: [Color(0xFF845EF7), Color(0xFFA78BFA)],
    QuestType.bonus: [Color(0xFFFFB347), Color(0xFFFFD080)],
  };

  static const Map<QuestType, IconData> _icons = {
    QuestType.weakestCharacters: Icons.whatshot_rounded,
    QuestType.recentReview: Icons.history_rounded,
    QuestType.randomReview: Icons.shuffle_rounded,
    QuestType.bonus: Icons.auto_awesome_rounded,
  };

  List<Color> get _gradient =>
      _gradients[quest.type] ?? [Colors.blueGrey, Colors.blueGrey.shade300];
  IconData get _icon => _icons[quest.type] ?? Icons.quiz_rounded;
  Color get _primary => _gradient.first;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: quest.isCompleted ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: quest.isCompleted
                ? Colors.grey.shade200
                : _primary.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: quest.isCompleted
                  ? Colors.black.withValues(alpha: 0.03)
                  : _primary.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // ── Header strip ──────────────────────────────────
              _buildHeader(),
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
                    _buildFooter(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: quest.isCompleted
              ? [Colors.grey.shade300, Colors.grey.shade200]
              : _gradient,
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              quest.isCompleted ? Icons.check_circle_rounded : _icon,
              color: Colors.white,
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
                  quest.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  quest.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
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

  // ── Colorful XP reward badge ────────────────────────────────────
  Widget _buildRewardBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '+${quest.rewardXp} XP',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
            color: quest.isCompleted
                ? Colors.grey.shade100
                : _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: quest.isCompleted
                  ? Colors.grey.shade200
                  : _primary.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            char,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: quest.isCompleted ? Colors.grey.shade400 : _primary,
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
              quest.isCompleted ? 'Completed!' : 'Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: quest.isCompleted
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade600,
              ),
            ),
            Text(
              '${quest.progress}/${quest.total}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: quest.isCompleted ? const Color(0xFF4CAF50) : _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Track
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                // Background track
                Container(
                  decoration: BoxDecoration(
                    color: quest.isCompleted
                        ? Colors.green.shade50
                        : _primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: quest.isCompleted
                            ? [const Color(0xFF66BB6A), const Color(0xFF4CAF50)]
                            : _gradient,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Start / completed button ────────────────────────────────────
  Widget _buildFooter() {
    if (quest.isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text('Completed'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50),
            disabledForegroundColor: const Color(0xFF4CAF50),
            side: const BorderSide(color: Color(0xFF4CAF50), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('Start Quest'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
