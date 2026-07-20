import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/data/controllers/ai_writing/ai_writing_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AI WRITING SUMMARY PAGE
//  Shown after the user finishes all writing practice repetitions.
//  Matches the visual theme of the stage & mini-game summary pages.
// ═══════════════════════════════════════════════════════════════════════════

class AiWritingSummaryPage extends StatelessWidget {
  const AiWritingSummaryPage({super.key});

  // ── Theme colours (consistent with GameColors & stage summary) ─────────
  static const Color _teal = Color(0xFF3CBBB1);
  static const Color _green = Color(0xFF5DC97E);
  static const Color _softRed = Color(0xFFF87171);
  static const Color _purple = Color(0xFFA78BFA);
  static const Color _textDark = Color(0xFF3D405B);
  static const Color _textMuted = Color(0xFF8E91A4);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiWritingController>();

    final int correct = controller.totalCorrect.value;
    final int attempted = controller.totalAttempted.value;
    final double accuracy =
        attempted > 0 ? (correct / attempted * 100) : 0.0;
    final int totalChars = controller.characters.length;
    final int repeatCount = controller.repeatCount;
    final int coins = controller.earnedCoins.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Pop summary + practice page
        Get.back();
        Get.back();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── Background matching the writing practice theme ──────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/ai_writing_practice_background.png',
                fit: BoxFit.cover,
              ),
            ),

            // ── Soft gradient overlay for readability ────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2B7A78).withValues(alpha: 0.85),
                      const Color(0xFF6B9F8E).withValues(alpha: 0.0),
                    ],
                    stops: const [0.15, 0.45],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // ── Trophy icon ─────────────────────────────────
                        _buildIcon(),
                        const SizedBox(height: 12),

                        // ── "GREAT JOB" title ───────────────────────────
                        Text(
                          'great_job'.tr.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: Get.locale?.languageCode == 'km'
                                ? 0
                                : 4,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Score fraction ──────────────────────────────
                        Text(
                          'score'.tr.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: Get.locale?.languageCode == 'km'
                                ? 0
                                : 2,
                          ),
                        ),
                        const SizedBox(height: 0),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_purple, _teal],
                          ).createShader(bounds),
                          child: Text(
                            '$correct / $attempted',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Stats card ──────────────────────────────────
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _resultStat(
                                          '🎯',
                                          'accuracy'.tr,
                                          '${accuracy.toStringAsFixed(0)}%',
                                        ),
                                      ),
                                      Expanded(
                                        child: _resultStat(
                                          '🪙',
                                          'coins_earned'.tr,
                                          '$coins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _resultStat(
                                          '✍️',
                                          'total_characters'.tr,
                                          '$totalChars',
                                        ),
                                      ),
                                      Expanded(
                                        child: _resultStat(
                                          '🔄',
                                          'repetitions'.tr,
                                          '${repeatCount}x',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(
                                      height: 1, color: Colors.black12),
                                  const SizedBox(height: 12),

                                  // Answered breakdown row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _ratingChip(
                                        'answered'.tr,
                                        '$attempted',
                                        _teal,
                                      ),
                                      _ratingChip(
                                        'correct'.tr,
                                        '$correct',
                                        _green,
                                      ),
                                      _ratingChip(
                                        'wrong'.tr,
                                        '${attempted - correct}',
                                        _softRed,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Bottom buttons ──────────────────────────────
                        _buildBottomButtons(controller),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trophy icon ─────────────────────────────────────────────────────────
  Widget _buildIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Lottie.asset('assets/animated/trophy.json', repeat: false),
    );
  }

  // ── Stat tile ───────────────────────────────────────────────────────────
  Widget _resultStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Rating chip ─────────────────────────────────────────────────────────
  Widget _ratingChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Bottom action buttons ───────────────────────────────────────────────
  Widget _buildBottomButtons(AiWritingController controller) {
    return Row(
      children: [
        // Retry button
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Reset session stats for a fresh retry
              controller.totalCorrect.value = 0;
              controller.totalAttempted.value = 0;
              controller.earnedCoins.value = 0;
              controller.charIndex.value = 0;
              controller.rep.value = 0;
              controller.repResults
                  .assignAll(List<bool?>.filled(controller.repeatCount, null));
              controller.clearBoard();
              controller.attemptLeft.value = 3;
              // Pop back to the practice page (which is still in the stack)
              Get.back();
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1FB9FF),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.replay, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Continue / exit button
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Pop summary + practice pages → back to character select
              Get.back();
              Get.back();
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
