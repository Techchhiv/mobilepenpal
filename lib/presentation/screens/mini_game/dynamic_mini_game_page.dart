import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_drawing_board.dart';

class DynamicMiniGamePage extends GetView<DynamicMiniGameController> {
  const DynamicMiniGamePage({super.key});

  void _showPauseDialog(BuildContext context) {
    controller.pauseGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => _PauseDialog(
        onResume: () {
          Navigator.of(ctx).pop();
          controller.resumeGame();
        },
        onQuit: () {
          Navigator.of(ctx).pop();
          controller.endGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (controller.isGameActive.value && !controller.isGameOver.value) {
            _showPauseDialog(context);
          } else {
            Get.back();
          }
        }
      },
      child: Scaffold(
        body: Obx(() {
          if (controller.isLoading.value) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2C5364), AppColors.textGray80],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
              ),
            );
          }

          if (controller.isGameOver.value) {
            return _buildGameOverScreen();
          }

          return Stack(
            children: [
              _buildGameUI(context),
              Obx(
                () => controller.isCountingDown.value
                    ? _buildCountdownOverlay()
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Countdown ──────────────────────────────────────────────────────
  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: AnimatedBuilder(
            animation: controller.countdownAnimCtrl,
            builder: (_, __) {
              final scale = 1.0 +
                  (1.0 - controller.countdownAnimCtrl.value) * 0.5;
              final opacity =
                  (1.0 - controller.countdownAnimCtrl.value * 0.3)
                      .clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Obx(() {
                    final val = controller.countdownValue.value;
                    final text = val > 0 ? '$val' : 'GO!';
                    final color =
                        val > 0 ? Colors.white : const Color(0xFF4ECDC4);

                    return Text(
                      text,
                      style: TextStyle(
                        color: color,
                        fontSize: val > 0 ? 120 : 80,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 30,
                          ),
                          Shadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Main Game UI ──────────────────────────────────────────────────
  Widget _buildGameUI(BuildContext context) {
    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C5364), AppColors.textGray80],
              ),
            ),
          ),
        ),

        // Game content
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _buildGameTopBar(context),
                    const SizedBox(height: 6),
                    Obx(() => _buildTimerBar()),
                    const SizedBox(height: 4),
                    Obx(() => _buildComboIndicator()),
                    const SizedBox(height: 8),

                    // ── DISPLAY MODULE (top half) ──
                    Obx(() => _buildDisplayModule()),
                    const SizedBox(height: 12),

                    // ── INPUT MODULE (bottom half) ──
                    Expanded(
                      flex: 18,
                      child: _buildInputModule(),
                    ),
                    const Spacer(),
                    _buildBottomButtons(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating feedback text
        _buildFeedbackOverlay(),
      ],
    );
  }

  // ── Display Module ────────────────────────────────────────────────
  Widget _buildDisplayModule() {
    final challenge = controller.currentChallenge.value;
    if (challenge == null) return const SizedBox(height: 60);

    return AnimatedBuilder(
      animation: controller.promptBounceCtrl,
      builder: (_, child) {
        final dy = -3 * controller.promptBounceCtrl.value;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Text(
              _getDisplayLabel(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              challenge.display,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayLabel() {
    final isDrawing = controller.currentInputType.value == 'drawing_board';
    final action = isDrawing ? 'Draw' : 'Select';
    
    switch (controller.currentMiniGame.value?.displayType) {
      case 'math_equation':
        return 'Solve & $action the answer';
      case 'character':
        return '$action this character';
      case 'number':
        return '$action this number';
      case 'letter':
        return '$action this character';
      case 'text':
        return 'Write this text';
      case 'image':
        return 'What is this?';
      default:
        return '$action this';
    }
  }

  // ── Input Module ──────────────────────────────────────────────────
  Widget _buildInputModule() {
    return Obx(() {
      switch (controller.currentInputType.value) {
        case 'drawing_board':
          return _buildDrawingBoardInput();
        case 'multiple_choice':
          return _buildMultipleChoiceInput();
        default:
          return _buildDrawingBoardInput();
      }
    });
  }

  Widget _buildDrawingBoardInput() {
    return Obx(
      () => StageDrawingBoard(
        boardWidth: controller.boardWidth.value,
        boardHeight: controller.boardHeight.value,
        onUpdateBoardSize: controller.updateBoardSize,
        drawingControllers: [controller.drawingController],
        letterSubpathsNorm:
            controller.currentMiniGame.value?.displayType != 'math_equation'
                ? controller.letterSubpathsNorm.toList()
                : const [],
        scale: controller.boardWidth.value / 340.0,
        onPointerDown: (e, _) => controller.onRawPointerDown(e),
        onPointerMove: (e, _) => controller.onRawPointerMove(e),
        onPointerUp: (e, _) => controller.onRawPointerUp(e),
        attemptLeft: 0,
        maxAttempts: 0,
        feedbackState: controller.anim.feedback.value,
        praiseFeedbackState: controller.anim.praiseFeedback.value,
        shakeOffset: controller.anim.shakeOffset.value,
        praiseText: '',
        confettiController: controller.anim.confettiController,
        guideCirclePx: controller.anim.guideCirclePx.value,
        isGuiding: controller.anim.isGuiding.value,
        showGuiding: controller.currentMiniGame.value?.displayType != 'math_equation',
        activeBoardCount: 1,
        useExpanded: false,
      ),
    );
  }

  Widget _buildMultipleChoiceInput() {
    return Obx(() {
      final options = controller.currentOptions;
      if (options.isEmpty) return const SizedBox();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine grid constraints based on number of options (usually 4)
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => controller.submitMultipleChoice(option),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }

  // ── Top Bar ────────────────────────────────────────────────────────
  Widget _buildGameTopBar(BuildContext context) {
    return Row(
      children: [
        _buildCircleButton(
          icon: Icons.pause_rounded,
          onTap: () => _showPauseDialog(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(
            () => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFD700),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${controller.score.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildCircleButton(
          icon: Icons.close_rounded,
          onTap: () {
            if (controller.isGameActive.value &&
                !controller.isGameOver.value) {
              _showPauseDialog(context);
            } else {
              Get.back();
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    final fraction = controller.timerFraction;
    final Color barColor;
    if (fraction > 0.5) {
      barColor = const Color(0xFF4ECDC4);
    } else if (fraction > 0.25) {
      barColor = const Color(0xFFFFD700);
    } else {
      barColor = const Color(0xFFFF6B6B);
    }

    return Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              colors: [barColor, barColor.withValues(alpha: 0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: barColor.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComboIndicator() {
    final comboVal = controller.combo.value;
    if (comboVal < 2) return const SizedBox(height: 20);

    return Container(
      height: 20,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: comboVal >= 5
                ? const Color(0xFFFF6B6B)
                : const Color(0xFFFFD700),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${comboVal}x COMBO',
            style: TextStyle(
              color: comboVal >= 5
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Obx(() {
      if (controller.currentInputType.value != 'drawing_board') {
        return const SizedBox.shrink();
      }

      return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Clear',
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFFF6B6B),
            onTap: () => controller.clearBoard(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Submit',
            icon: Icons.check_rounded,
            color: const Color(0xFF4ECDC4),
            onTap: () => controller.forceSubmit(),
          ),
        ),
      ],
    );
    });
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
      ),
    );
  }

  // ── Feedback overlay ──────────────────────────────────────────────
  Widget _buildFeedbackOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller.feedbackAnimCtrl,
          builder: (_, __) {
            if (controller.feedbackAnimCtrl.value == 0) {
              return const SizedBox.shrink();
            }

            return Obx(() {
              final text = controller.feedbackText.value;
              if (text.isEmpty) return const SizedBox.shrink();

              final isCorrect = controller.isCorrectFeedback.value;
              final color = isCorrect
                  ? const Color(0xFF4ECDC4)
                  : const Color(0xFFFF6B6B);
              final opacity =
                  (1.0 - controller.feedbackAnimCtrl.value).clamp(0.0, 1.0);

              final t = controller.feedbackAnimCtrl.value;
              final scaleVal = 0.5 + (math.sin(t * math.pi * 0.5) * 0.7);
              final yOffset = -40 * t;

              return Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Transform.scale(
                      scale: scaleVal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: color,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  // ── Game Over ─────────────────────────────────────────────────────
  Widget _buildGameOverScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFE94560),
                            Color(0xFFFF6B6B),
                            Color(0xFFFFD700),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.miniGames.length == 1
                            ? controller.miniGames.first.title
                            : 'Custom Mix (${controller.miniGames.length} games)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stats
                      _buildStatCard('Score', '${controller.score.value}',
                          const Color(0xFFFFD700)),
                      const SizedBox(height: 12),
                      _buildStatCard('Best Combo', '${controller.bestCombo.value}x',
                          const Color(0xFFFF6B6B)),
                      const SizedBox(height: 12),
                      _buildStatCard(
                          'Accuracy',
                          '${controller.accuracy.toStringAsFixed(1)}%',
                          const Color(0xFF4ECDC4)),
                      const SizedBox(height: 12),
                      _buildStatCard(
                          'Answered',
                          '${controller.correctCount.value}/${controller.totalAnswered.value}',
                          const Color(0xFF6C63FF)),

                      const SizedBox(height: 32),

                      // High score
                      Obx(() {
                        final isNewHigh =
                            controller.score.value >= controller.highScore.value &&
                                controller.score.value > 0;
                        if (!isNewHigh) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'NEW HIGH SCORE!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Exit',
                              icon: Icons.arrow_back_rounded,
                              color: const Color(0xFFFF6B6B),
                              onTap: () => Get.back(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Play Again',
                              icon: Icons.refresh_rounded,
                              color: const Color(0xFF4ECDC4),
                              onTap: () {
                                controller.startGame();
                                controller.pauseGame();
                                controller.startCountdown();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pause Dialog ──────────────────────────────────────────────────────
class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                color: Color(0xFF4ECDC4), size: 48),
            const SizedBox(height: 16),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'RESUME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onQuit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'QUIT',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
