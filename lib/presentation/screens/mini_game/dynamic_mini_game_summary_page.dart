import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/presentation/widgets/mini_game/dynamic_game_widgets.dart';

class DynamicMiniGameSummaryPage extends GetView<DynamicMiniGameController> {
  const DynamicMiniGameSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Go back to mini game hub
        Get.back();
        Get.back();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Game Background (sky + hills + clouds)
            const GameBackground(),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppConstants.globalMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Trophy / Game Over Icon
                        _buildIcon(),
                        const SizedBox(height: 10),

                        Text(
                          'game_over'.tr.toUpperCase(),
                          style: TextStyle(
                            color: GameColors.softRed,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 4,
                          ),
                        ),

                        // Score section centered in the space between Game Over and stats container
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'score'.tr.toUpperCase(),
                                  style: TextStyle(
                                    color: GameColors.textDark.withValues(alpha: 0.55),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 2,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [GameColors.purple, GameColors.teal],
                                  ).createShader(bounds),
                                  child: Text(
                                    '${controller.score.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),

                                // High score badge
                                if (controller.score.value >= controller.highScore.value && controller.score.value > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFF2B024), Color(0xFFD29004)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'new_high_score'.tr.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Stats Grid in a premium container consistent with stage summary card, wrapped in Expanded flex 2
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _resultStat('🎯', 'accuracy'.tr, '${controller.accuracy.toStringAsFixed(0)}%'),
                                      ),
                                      Expanded(
                                        child: _resultStat('🪙', 'coins_earned'.tr, '${controller.earnedCoins.value}'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _resultStat('🔥', 'best_combo'.tr, '${controller.bestCombo.value}x'),
                                      ),
                                      Expanded(
                                        child: _resultStat('🏆', 'best_score'.tr, '${controller.highScore.value}'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Colors.black12),
                                  const SizedBox(height: 12),
                                  // Answered breakdown row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _ratingChip('answered'.tr, '${controller.totalAnswered.value}', GameColors.teal),
                                      _ratingChip('correct'.tr, '${controller.correctCount.value}', GameColors.green),
                                      _ratingChip('wrong'.tr, '${controller.wrongCount.value}', GameColors.softRed),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Replay/Continue bottom buttons similar to StageSummaryPage
                        _buildBottomButtons(),
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
      child: Lottie.asset("assets/animated/trophy.json", repeat: false),
    );
  }

  Widget _resultStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: GameColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: GameColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

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

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.startGame();
              controller.pauseGame();
              controller.startCountdown();
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
        Expanded(
          child: GestureDetector(
            onTap: () {
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
