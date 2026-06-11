import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/mini_game/adventure/adventure_stage_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_drawing_board.dart';

class AdventureStagePage extends GetView<AdventureStageController> {
  const AdventureStagePage({super.key});

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

          // Show game over overlay
          if (controller.isGameOver.value) {
            return _buildGameOverScreen();
          }

          // Main game UI (with countdown overlay if counting down)
          return Stack(
            children: [
              _buildGameUI(context),
              // Countdown overlay
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

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: AnimatedBuilder(
            animation: controller.countdownAnimCtrl,
            builder: (_, __) {
              final scale =
                  1.0 +
                  (1.0 - controller.countdownAnimCtrl.value) *
                      0.5; // starts big, shrinks
              final opacity = (1.0 - controller.countdownAnimCtrl.value * 0.3)
                  .clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Obx(() {
                    final val = controller.countdownValue.value;
                    final text = val > 0 ? '$val' : 'GO!';
                    final color = val > 0
                        ? Colors.white
                        : const Color(0xFF4ECDC4);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildGameTopBar(context),
                    const SizedBox(height: 6),
                    Obx(() => _buildTimerBar()),
                    const SizedBox(height: 4),
                    Obx(() => _buildComboIndicator()),
                    const SizedBox(height: 8),
                    Obx(() => _buildPromptArea()),
                    const SizedBox(height: 24),
                    Expanded(
                      flex: 18,
                      child: Obx(
                        () => StageDrawingBoard(
                          boardWidth: controller.boardWidth.value,
                          boardHeight: controller.boardHeight.value,
                          onUpdateBoardSize: controller.updateBoardSize,
                          drawingControllers: controller.drawingControllers,
                          letterSubpathsNorm: controller.showShadowGuide
                              ? controller.letterSubpathsNorm.toList()
                              : const [],
                          scale: controller.scale,
                          onPointerDown: controller.onRawPointerDown,
                          onPointerMove: controller.onRawPointerMove,
                          onPointerUp: controller.onRawPointerUp,
                          attemptLeft: 0,
                          maxAttempts: 0,
                          feedbackState: controller.anim.feedback.value,
                          praiseFeedbackState:
                              controller.anim.praiseFeedback.value,
                          shakeOffset: controller.anim.shakeOffset.value,
                          praiseText: '',
                          confettiController:
                              controller.anim.confettiController,
                          guideCirclePx: controller.anim.guideCirclePx.value,
                          isGuiding: controller.anim.isGuiding.value,
                          showGuiding: controller.showShadowGuide,
                          activeBoardCount: controller.activeBoardCount,
                          useExpanded: false,
                          showMorph: controller.anim.showMorph.value,
                          morphProgress: controller.anim.morphProgress.value,
                          userMorphStrokes: controller.anim.userMorphStrokes,
                          templateMorphStrokes: controller.anim.templateMorphStrokes,
                          stampImage: controller.currentStampImage,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildActiveBuffsRow(),
                    const Spacer(),
                    _buildBottomButtons(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Spawned power-up
        _buildSpawnedPowerUp(),

        // Floating feedback text
        _buildFeedbackOverlay(),
      ],
    );
  }

  Widget _buildGameTopBar(BuildContext context) {
    return Row(
      children: [
        // Pause
        _buildCircleButton(
          icon: Icons.pause_rounded,
          onTap: () => _showPauseDialog(context),
        ),
        const SizedBox(width: 12),

        // Score
        Expanded(
          child: Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

        // Avatar
        _buildAvatarCircle(),
      ],
    );
  }

  Widget _buildBottomButtons() {
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
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
      ),
    );
  }

  Widget _buildAvatarCircle() {
    Widget avatarContent = const Icon(
      Icons.person,
      size: 22,
      color: Colors.white70,
    );
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      final shopAvatar = home.currentShopAvatar;
      if (shopAvatar != null && shopAvatar.id != 'default') {
        if (shopAvatar.assetPath != null) {
          avatarContent = Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(shopAvatar.assetPath!, fit: BoxFit.cover),
          );
        }
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipOval(child: avatarContent),
    );
  }

  Widget _buildTimerBar() {
    final fraction = controller.timerFraction;
    final Color barColor;
    if (controller.isFreezeActive.value) {
      barColor = const Color(0xFF64B5F6);
    } else if (fraction > 0.5) {
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

  Widget _buildActiveBuffsRow() {
    return SizedBox(
      height: 80,
      child: Obx(() {
        final buffs = <Widget>[];

        if (controller.isScore2xActive.value) {
          buffs.add(
            _buildCircularBuff(
              icon: Icons.star_rounded,
              color: const Color(0xFFFFD700),
              progress:
                  controller.score2xTimeLeft.value /
                  controller.score2xMaxDuration.value,
            ),
          );
        }

        if (controller.isFreezeActive.value) {
          buffs.add(
            _buildCircularBuff(
              icon: Icons.ac_unit_rounded,
              color: const Color(0xFF4ECDC4),
              progress:
                  controller.freezeTimeLeft.value /
                  controller.freezeMaxDuration.value,
            ),
          );
        }

        if (controller.hasShield.value) {
          buffs.add(
            _buildCircularBuff(
              icon: Icons.shield_rounded,
              color: const Color(0xFF6C63FF),
              progress: 1.0,
            ),
          );
        }

        if (buffs.isEmpty) return const SizedBox(height: 80);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buffs
              .map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: b,
                ),
              )
              .toList(),
        );
      }),
    );
  }

  Widget _buildCircularBuff({
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    const double outerSize = 64;
    const double innerSize = 48;
    const double iconSize = 48;
    const double strokeWidth = 5;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: outerSize,
            height: outerSize,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: color.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(
            width: outerSize,
            height: outerSize,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ],
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

  Widget _buildPromptArea() {
    final char = controller.selectedCharacter.value;
    if (char.isEmpty) return const SizedBox(height: 60);

    final showLetter = controller.showLetterPrompt;

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
              showLetter ? 'Draw this character' : 'Listen & Draw',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showLetter)
              Text(
                char,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    // Replay audio on tap
                    controller.audio.playCharacterGuarded(
                      type: controller.currentCharacterType.value,
                      ch: controller.selectedCharacter.value,
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF6C63FF),
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpawnedPowerUp() {
    return Obx(() {
      final type = controller.spawnedPowerUp.value;
      if (type == null) return const SizedBox.shrink();

      IconData icon;
      Color color;

      switch (type) {
        case PowerUpType.timePlus:
          icon = Icons.favorite_rounded;
          color = const Color(0xFFFF6B6B);
          break;
        case PowerUpType.score2x:
          icon = Icons.star_rounded;
          color = const Color(0xFFFFD700);
          break;
        case PowerUpType.freeze:
          icon = Icons.ac_unit_rounded;
          color = const Color(0xFF4ECDC4);
          break;
        case PowerUpType.shield:
          icon = Icons.shield_rounded;
          color = const Color(0xFF6C63FF);
          break;
      }

      return Align(
        alignment: controller.powerUpAlignment.value,
        child: GestureDetector(
          onTap: () => controller.collectPowerUp(),
          child: AnimatedBuilder(
            animation:
                controller.promptBounceCtrl, // Reusing bounce for pulsing
            builder: (_, child) {
              final scale = 1.0 + (controller.promptBounceCtrl.value * 0.15);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFeedbackOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller.feedbackAnimCtrl,
          builder: (_, __) {
            if (controller.feedbackAnimCtrl.value == 0)
              return const SizedBox.shrink();

            return Obx(() {
              final text = controller.lastRatingText.value;
              final rating = controller.lastRating.value;
              if (text.isEmpty || rating == null)
                return const SizedBox.shrink();

              final color = _ratingColor(rating);
              final opacity = (1.0 - controller.feedbackAnimCtrl.value).clamp(
                0.0,
                1.0,
              );

              // More dynamic transform: pops up and then drifts
              final t = controller.feedbackAnimCtrl.value;
              final scaleVal =
                  0.5 + (math.sin(t * math.pi * 0.5) * 0.7); // Scale pop
              final yOffset = -40 * t; // Upward drift

              return Align(
                alignment: controller.lastRatingAlignment.value,
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

  Color _ratingColor(DrawRating rating) {
    switch (rating) {
      case DrawRating.perfect:
        return const Color(0xFFFFD700);
      case DrawRating.good:
        return const Color(0xFF4ECDC4);
      case DrawRating.okay:
        return Colors.white70;
      case DrawRating.miss:
        return const Color(0xFFFF6B6B);
    }
  }

  // ── Game Over Screen ──

  Widget _buildGameOverScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C5364), AppColors.textGray80],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Final Score
                  Text(
                    'SCORE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
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

                  // High score indicator
                  if (controller.score.value >= controller.highScore.value &&
                      controller.score.value > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFD700),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'NEW HIGH SCORE!',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Stats grid
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _resultStat(
                                '🏆',
                                'Best Score',
                                '${controller.highScore.value}',
                              ),
                            ),
                            Expanded(
                              child: _resultStat(
                                '🪙',
                                'Coins Earned',
                                '${controller.earnedCoins.value}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _resultStat(
                                '🔥',
                                'Best Combo',
                                '${controller.bestCombo.value}',
                              ),
                            ),
                            Expanded(
                              child: _resultStat(
                                '🎯',
                                'Accuracy',
                                '${controller.accuracy.toStringAsFixed(0)}%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Rating breakdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ratingChip(
                              'Perfect',
                              '${controller.perfectCount.value}',
                              const Color(0xFFFFD700),
                            ),
                            _ratingChip(
                              'Good',
                              '${controller.goodCount.value}',
                              const Color(0xFF4ECDC4),
                            ),
                            _ratingChip(
                              'Okay',
                              '${controller.okayCount.value}',
                              Colors.white54,
                            ),
                            _ratingChip(
                              'Miss',
                              '${controller.missCount.value}',
                              const Color(0xFFFF6B6B),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Characters practiced
                  if (controller.charactersPracticed.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Characters Practiced',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: controller.charactersPracticed.map((ch) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6C63FF,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  ch,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _gameOverButton(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          color: Colors.white.withValues(alpha: 0.08),
                          textColor: Colors.white70,
                          onTap: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _gameOverButton(
                          label: 'Play Again',
                          icon: Icons.replay_rounded,
                          color: const Color(0xFF6C63FF),
                          textColor: Colors.white,
                          onTap: () => controller.startGame(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _gameOverButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
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
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pause Dialog ──
class _PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const _PauseDialog({required this.onResume, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: Color(0xFF4ECDC4),
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Resume',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onQuit,
                icon: const Icon(Icons.home_rounded, size: 20),
                label: const Text(
                  'Quit',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
