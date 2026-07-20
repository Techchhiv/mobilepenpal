import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/core/utils/challenge_generator.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/presentation/widgets/mini_game/dynamic_game_widgets.dart';
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
                  colors: [GameColors.skyTop, GameColors.skyBot],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
              ),
            );
          }

          if (controller.isGameOver.value) {
            return _buildGameUI(context);
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
    return CountdownOverlay(
      controller: controller,
      countdownValue: controller.countdownValue.value,
      animCtrl: controller.countdownAnimCtrl,
    );
  }

  // ── Main Game UI ──────────────────────────────────────────────────
  Widget _buildGameUI(BuildContext context) {
    return Stack(
      children: [
        const GameBackground(),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.globalMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildGameTopBar(context),
                    const SizedBox(height: 16),
                    Obx(() => TimerBar(fraction: controller.timerFraction)),
                    const SizedBox(height: 4),
                    Obx(() => ComboIndicator(combo: controller.combo.value)),
                    const SizedBox(height: 12),

                    // ── DISPLAY MODULE (top half) ──
                    Flexible(flex: 0, child: Obx(() => _buildDisplayModule())),
                    const SizedBox(height: 12),

                    // ── INPUT MODULE (bottom half) ──
                    Expanded(flex: 18, child: _buildInputModule(context)),
                    const Spacer(),
                    _buildBottomButtons(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        FeedbackOverlay(controller: controller),
        FloatingScoreOverlay(controller: controller),
      ],
    );
  }

  // ── Display Module ──────────────────────────────────────────────────
  Widget _buildDisplayModule() {
    final displayType = controller.currentMiniGame.value?.displayType;

    if (controller.currentInputType.value == 'drag_and_drop') {
      return const SizedBox.shrink();
    }

    final challenge = controller.currentChallenge.value;
    if (challenge == null) return const SizedBox(height: 60);

    // Route to specialised display builders
    if (displayType == 'object_count') return _buildObjectCountDisplay();
    if (displayType == 'missing_character') return _buildMissingCharacterDisplay();
    if (displayType == 'math_equation') return _buildMathEquationDisplay();
    if (displayType == 'question') return _buildQuestionDisplay();

    return _buildDefaultDisplay(challenge, displayType);
  }

  /// Default display for character / math_equation / image / etc.
  Widget _buildDefaultDisplay(Challenge challenge, String? displayType) {
    return AnimatedBuilder(
      animation: controller.promptBounceCtrl,
      builder: (_, child) {
        final dy = -3 * controller.promptBounceCtrl.value;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: GameColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: GameColors.cardBorder, width: 3),
          boxShadow: [
            BoxShadow(color: GameColors.textDark.withValues(alpha: 0.05), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InstructionBadge(inputType: controller.currentInputType.value),
              const SizedBox(height: 8),
              Obx(() {
                final alwaysShow = displayType == 'math_equation' || displayType == 'image';
                final diff = controller.difficulty.value;
                final isVis = controller.isPromptVisible.value;

                final bool promptVisible;
                if (alwaysShow) {
                  promptVisible = true;
                } else if (diff == MiniGameDifficulty.easy) {
                  promptVisible = true;
                } else if (diff == MiniGameDifficulty.hard) {
                  promptVisible = false;
                } else {
                  promptVisible = isVis;
                }

                return Column(
                  children: [
                    if (diff == MiniGameDifficulty.medium && promptVisible)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: AnimatedBuilder(
                          animation: controller.mediumTimerCtrl,
                          builder: (context, child) {
                            return SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: controller.mediumTimerCtrl.value,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                        ),
                      ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 400),
                      crossFadeState: promptVisible
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Text(
                        challenge.display,
                        style: const TextStyle(
                          color: GameColors.textDark,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      secondChild: diff == MiniGameDifficulty.medium
                          ? const Text(
                              '?',
                              style: TextStyle(
                                color: GameColors.textMuted,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            )
                          : GestureDetector(
                              onTap: controller.replayPromptAudio,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up_rounded,
                                    color: GameColors.teal,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'tap_to_listen_again'.tr,
                                    style: const TextStyle(
                                      color: GameColors.teal,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Object Count Display ─────────────────────────────────────────
  Widget _buildObjectCountDisplay() {
    return Obx(() {
      final emojis = controller.objectCountEmojis;
      final layout = controller.objectCountLayout.value;
      final memoryVisible = controller.objectCountMemoryVisible.value;

      return AnimatedBuilder(
        animation: controller.promptBounceCtrl,
        builder: (_, child) {
          final dy = -3 * controller.promptBounceCtrl.value;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameColors.cardBorder, width: 3),
            boxShadow: [
              BoxShadow(color: GameColors.textDark.withValues(alpha: 0.05), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              InstructionBadge(inputType: controller.currentInputType.value),
              const SizedBox(height: 12),
              if (layout == 'memory')
                MemoryObjectsDisplay(
                  emojis: emojis,
                  memoryVisible: memoryVisible,
                  duration: const Duration(seconds: 3),
                )
              else
                layout == 'scattered'
                    ? _buildScatteredEmojis(emojis)
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: emojis
                            .map((e) => Text(e, style: const TextStyle(fontSize: 36)))
                            .toList(),
                      ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildScatteredEmojis(List<String> emojis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Padding around edges so emojis aren't cut off
        const padding = 32.0;
        final minX = padding;
        final maxX = math.max(minX + 10.0, width - padding - 32.0);
        const minY = 5.0;
        final maxY = math.max(minY + 10.0, 80.0 - 5.0 - 32.0);

        final rng = math.Random(emojis.length);
        final positions = <Offset>[];
        const minDistance = 30.0; // Distance between emoji centers to prevent overlap

        for (int i = 0; i < emojis.length; i++) {
          double x = 0;
          double y = 0;
          bool overlap = true;
          int attempts = 0;
          double currentMinDist = minDistance;

          while (overlap && attempts < 100) {
            attempts++;
            // Generate candidate position
            x = minX + rng.nextDouble() * (maxX - minX);
            y = minY + rng.nextDouble() * (maxY - minY);

            overlap = false;
            for (final pos in positions) {
              final dist = (Offset(x, y) - pos).distance;
              if (dist < currentMinDist) {
                overlap = true;
                break;
              }
            }

            // Gradually decrease minimum distance if it's hard to find a free space
            if (attempts % 10 == 0) {
              currentMinDist = (currentMinDist - 2.0).clamp(10.0, minDistance);
            }
          }
          positions.add(Offset(x, y));
        }

        return SizedBox(
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: emojis.asMap().entries.map((e) {
              final idx = e.key;
              final emoji = e.value;
              final pos = positions[idx];
              final rotation = (rng.nextDouble() - 0.5) * 0.4;
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: Transform.rotate(
                  angle: rotation,
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Missing Character Display ────────────────────────────────────
  Widget _buildMissingCharacterDisplay() {
    return Obx(() {
      final hint = controller.missingCharDisplayHint.value;
      final blank = controller.missingCharWordBlank.value;
      final fullWord = controller.missingCharFullWord.value;

      return AnimatedBuilder(
        animation: controller.promptBounceCtrl,
        builder: (_, child) {
          final dy = -3 * controller.promptBounceCtrl.value;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameColors.cardBorder, width: 3),
            boxShadow: [
              BoxShadow(color: GameColors.textDark.withValues(alpha: 0.05), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4)),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InstructionBadge(inputType: controller.currentInputType.value),
                const SizedBox(height: 8),
                if (hint == 'audio')
                  // Hard: audio only
                  GestureDetector(
                    onTap: controller.replayPromptAudio,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'tap_to_listen'.tr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...
                  [
                    // If there's an image or text hint, show it first (above the word)
                    if (hint == 'with_image') ...
                      [
                        controller.currentChallenge.value?.imagePath != null
                            ? Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: GameColors.teal.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  controller.currentChallenge.value!.imagePath!,
                                  height: 70,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'hint_text'.trParams({'word': fullWord}),
                                  style: const TextStyle(
                                    color: Color(0xFF4ECDC4),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                      ],

                    // Easy & Medium: show word with blank below the image
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: GameColors.textDark,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                        children: _buildBlankWordSpans(blank),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ),
      );
    });
  }

  List<InlineSpan> _buildBlankWordSpans(String blankWord) {
    // Replace the '_' placeholder with a styled box
    final spans = <InlineSpan>[];
    for (int i = 0; i < blankWord.length; i++) {
      if (blankWord[i] == '_') {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 64,
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: GameColors.cardBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameColors.cardBorder,
                width: 3,
              ),
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: blankWord[i]));
      }
    }
    return spans;
  }

  // ── Math Equation Display (with fruit images) ────────────────────
  Widget _buildMathEquationDisplay() {
    return Obx(() {
      final challenge = controller.currentChallenge.value;
      if (challenge == null) return const SizedBox(height: 60);

      final fruitImage = controller.mathFruitImage.value;

      return AnimatedBuilder(
        animation: controller.promptBounceCtrl,
        builder: (_, child) {
          final dy = -3 * controller.promptBounceCtrl.value;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameColors.cardBorder, width: 3),
            boxShadow: [
              BoxShadow(color: GameColors.textDark.withValues(alpha: 0.05), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              InstructionBadge(inputType: controller.currentInputType.value),
              const SizedBox(height: 10),
              // Visual Equation
              if (fruitImage.isNotEmpty)
                _buildVisualEquation(challenge.display, fruitImage)
              else
                Text(
                  challenge.display,
                  style: TextStyle(
                    color: GameColors.textDark,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 2,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// Parses the equation string (e.g., "3 + ? = 5") and builds a visual row.
  /// Numbers are replaced by a cluster of fruit images.
  Widget _buildVisualEquation(String display, String fruitImage) {
    final tokens = display.split(' ');
    
    // Use FittedBox to ensure the entire equation stays on one single row,
    // scaling down gracefully if it's too wide for the screen.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: tokens.asMap().entries.map((entry) {
          final index = entry.key;
          final token = entry.value;
          
          Widget childWidget;
          
          if (['+', '-', '×', '÷', '='].contains(token)) {
            childWidget = Text(
              token,
              style: TextStyle(
                color: GameColors.textDark.withValues(alpha: 0.6),
                fontSize: 40, // Slightly larger operator for better visibility
                fontWeight: FontWeight.w900,
              ),
            );
          } else if (token == '?') {
            childWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: GameColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GameColors.teal, width: 3),
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  color: GameColors.teal,
                  fontSize: 36, // Larger question mark
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          } else {
            // It's a number
            final count = int.tryParse(token);
            if (count == 0) {
              childWidget = Image.asset(
                'assets/images/fruits/empty_basket.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              );
            } else if (count != null) {
              // Fruits in a grid-like Wrap (max 3 per row)
              childWidget = Container(
                constraints: const BoxConstraints(maxWidth: 120), // 3 fruits (36px) + spacing (4px) = 116px width
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                    count,
                    (_) => Image.asset(fruitImage, width: 36, height: 36), // Big fruits
                  ),
                ),
              );
            } else {
              childWidget = const SizedBox.shrink(); // Fallback for unparseable tokens
            }
          }
          
          // Add spacing between tokens, but not after the last one
          return Padding(
            padding: EdgeInsets.only(right: index < tokens.length - 1 ? 16.0 : 0.0),
            child: childWidget,
          );
        }).toList(),
      ),
    );
  }


  // ── Question Display ─────────────────────────────────────────
  Widget _buildQuestionDisplay() {
    return Obx(() {
      final text = controller.questionText.value;
      final fruitImage = controller.questionFruitImage.value;
      if (text.isEmpty) return const SizedBox(height: 60);

      return AnimatedBuilder(
        animation: controller.promptBounceCtrl,
        builder: (_, child) {
          final dy = -3 * controller.promptBounceCtrl.value;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameColors.cardBorder, width: 3),
            boxShadow: [
              BoxShadow(color: GameColors.textDark.withValues(alpha: 0.05), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              InstructionBadge(inputType: controller.currentInputType.value),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fruit illustration on the left
                  if (fruitImage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, top: 4),
                      child: Image.asset(
                        fruitImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  // Problem text
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: GameColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Question mark badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: GameColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GameColors.gold.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '? = ',
                  style: TextStyle(
                    color: GameColors.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Input Module ──────────────────────────────────────────────────
  Widget _buildInputModule(BuildContext context) {
    return Obx(() {
      switch (controller.currentInputType.value) {
        case 'drawing_board':
          return _buildDrawingBoardInput();
        case 'multiple_choice':
          return _buildMultipleChoiceInput(context);
        case 'drag_and_drop':
          return _buildDragAndDropInput(context);
        default:
          return _buildDrawingBoardInput();
      }
    });
  }

  Widget _buildDrawingBoardInput() {
    return Obx(() {
      final showGuide = controller.showShadowGuide;
      final displayType = controller.currentMiniGame.value?.displayType;
      // Accessing the RxList directly or via .value to ensure GetX tracks it correctly
      // We map over it to create a hard copy so StageDrawingBoard sees a new list
      final subpaths = controller.letterSubpathsNorm
          .map((e) => e.toList())
          .toList();

      return StageDrawingBoard(
        boardWidth: controller.boardWidth.value,
        boardHeight: controller.boardHeight.value,
        onUpdateBoardSize: controller.updateBoardSize,
        drawingControllers: [controller.drawingController],
        letterSubpathsNorm: subpaths,
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
        isGuiding: controller.anim.isGuiding.value && showGuide,
        showGuiding: displayType != 'math_equation' && displayType != 'question' && showGuide,
        activeBoardCount: 1,
        useExpanded: false,
        showMorph: controller.anim.showMorph.value,
        morphProgress: controller.anim.morphProgress.value,
        userMorphStrokes: controller.anim.userMorphStrokes,
        templateMorphStrokes: controller.anim.templateMorphStrokes,
      );
    });
  }

  Widget _buildMultipleChoiceInput(BuildContext context) {
    return Obx(() {
      final options = controller.currentOptions;
      if (options.isEmpty) return const SizedBox();

      final screenWidth = MediaQuery.of(context).size.width;

      // Determine columns based on option count
      final int crossAxisCount;
      if (options.length <= 4) {
        crossAxisCount = 2;
      } else if (options.length <= 6) {
        crossAxisCount = screenWidth > 400 ? 3 : 2;
      } else if (options.length == 9) {
        crossAxisCount = 3;
      } else {
        crossAxisCount = screenWidth > 400 ? 3 : 2;
      }

      const spacing = 12.0;
      final rowCount = (options.length / crossAxisCount).ceil();

      // Use LayoutBuilder to compute card height from actual available space
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth - 32; // horizontal padding

          // Total vertical spacing between rows
          final totalVerticalSpacing = spacing * (rowCount - 1);
          // Height per card = (available - spacing) / rows
          final cardHeight = ((availableHeight - totalVerticalSpacing) / rowCount)
              .clamp(36.0, 120.0);

          // Width per card
          final totalHorizontalSpacing = spacing * (crossAxisCount - 1);
          final cardWidth = (availableWidth - totalHorizontalSpacing) / crossAxisCount;

          // Aspect ratio derived from actual available space
          final aspectRatio = cardWidth / cardHeight;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return Obx(() {
                    final isWrong = controller.hasRetried.value && option == controller.lastWrongAnswer.value;
                    return ChoiceCard(
                      option: option,
                      colorIndex: index,
                      onTap: () => controller.submitMultipleChoice(option),
                      isWrong: isWrong,
                    );
                  });
                },
              ),
            ),
          );
        },
      );
    });
  }

  // ── Drag-and-Drop Input ────────────────────────────────────────────
  Widget _buildDragAndDropInput(BuildContext context) {
    return Obx(() {
      final sources = controller.currentDragPairs;
      final targets = controller.shuffledDragTargets;
      final selectedSrc = controller.selectedDragSource.value;
      final wrongTarget = controller.hasRetried.value ? controller.lastWrongAnswer.value : '';

      if (sources.isEmpty) return const SizedBox();

      // Dynamic labels based on display type
      final displayType = controller.currentMiniGame.value?.displayType ?? 'character';
      String leftLabel;
      String rightLabel;
      switch (displayType) {
        case 'object_count':
          leftLabel = 'digits'.tr;
          rightLabel = 'objects'.tr;
          break;
        case 'missing_character':
          leftLabel = 'pictures'.tr;
          rightLabel = 'letters'.tr;
          break;
        default:
          leftLabel = 'pictures'.tr;
          rightLabel = 'letters'.tr;
          break;
      }

      final validSources = sources.where((p) => p.source.isNotEmpty).toList();
      final itemCount = validSources.length;
      final double cardScale = itemCount <= 3 ? 1.5 : (itemCount <= 4 ? 1.2 : 1.0);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── LEFT COLUMN: Source pictures (in order) ──
            Expanded(
              child: Column(
                children: [
                  Text(
                    leftLabel,
                    style: TextStyle(color: GameColors.textDark.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: validSources.asMap().entries.map((entry) {
                        final index = entry.key;
                        final pair = entry.value;
                        final isMatched = pair.matched;
                        final isSelected = selectedSrc == pair.source;
                        final state = isMatched ? 'matched' : (isSelected ? 'selected' : 'normal');

                        final card = MatchCard(
                          key: ValueKey('match_card_source_${pair.id}'),
                          content: pair.source,
                          state: state,
                          scale: cardScale,
                          colorIndex: index,
                          onTap: () => controller.selectDragSource(pair.source),
                        );

                        if (isMatched) {
                          return Flexible(
                            key: ValueKey('source_flex_matched_${pair.id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: card,
                            ),
                          );
                        }

                        return Flexible(
                          key: ValueKey('source_flex_draggable_${pair.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: LongPressDraggable<String>(
                              key: ValueKey('draggable_source_${pair.id}'),
                              data: pair.source,
                              delay: const Duration(milliseconds: 100),
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    child: MatchCard(
                                      key: ValueKey('match_card_feedback_${pair.id}'),
                                      content: pair.source,
                                      state: 'selected',
                                      scale: cardScale,
                                      onTap: () {},
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: card,
                              ),
                              onDragStarted: () => controller.selectDragSource(pair.source),
                              child: card,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── RIGHT COLUMN: Target answers (randomized) ──
            Expanded(
              child: Column(
                children: [
                  Text(
                    rightLabel,
                    style: TextStyle(color: GameColors.textDark.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: targets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final pair = entry.value;
                        final isMatched = pair.matched;
                        final isWrong = wrongTarget == pair.target;
                        final state = isMatched ? 'matched' : (isWrong ? 'wrong' : 'normal');

                        return Flexible(
                          key: ValueKey('target_flex_${pair.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: DragTarget<String>(
                              key: ValueKey('drag_target_${pair.id}'),
                              onWillAcceptWithDetails: (details) => !isMatched,
                              onAcceptWithDetails: (details) {
                                controller.submitDragDrop(details.data, pair);
                              },
                              builder: (context, candidateData, rejectedData) {
                                final isHovering = candidateData.isNotEmpty;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isHovering && !isMatched
                                        ? [
                                            BoxShadow(color: GameColors.teal.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
                                          ]
                                        : const [],
                                  ),
                                  child: MatchCard(
                                    key: ValueKey('match_card_target_${pair.id}'),
                                    content: pair.target,
                                    state: isHovering && !isMatched ? 'selected' : state,
                                    scale: cardScale,
                                    colorIndex: index + 5,
                                    onTap: () => controller.selectDragTarget(pair),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }


  // ── Top Bar ────────────────────────────────────────────────────────
  Widget _buildGameTopBar(BuildContext context) {
    return Row(
      children: [
        Obx(() => CoinChip(coins: controller.earnedCoins.value)),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => AnimatedScoreChip(score: controller.score.value)),
        ),
        const SizedBox(width: 12),
        PillIconButton(
          icon: Icons.pause_rounded,
          onTap: () {
            if (controller.isGameActive.value && !controller.isGameOver.value) {
              _showPauseDialog(context);
            } else {
              Get.back();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Obx(() {
      final inputType = controller.currentInputType.value;
      if (inputType != 'drawing_board') {
        return const SizedBox.shrink();
      }

      return Row(
        children: [
          Expanded(
            child: GameActionButton(
              label: 'clear'.tr,
              icon: Icons.delete_outline_rounded,
              color: GameColors.softRed,
              onTap: () => controller.clearBoard(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GameActionButton(
              label: 'submit'.tr,
              icon: Icons.check_rounded,
              color: GameColors.teal,
              onTap: () => controller.forceSubmit(),
            ),
          ),
        ],
      );
    });
  }

}

// ── Pause Dialog ──────────────────────────────────────────────────────
class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return GamePauseDialog(onResume: onResume, onQuit: onQuit);
  }
}

// ── Memory Objects Display ────────────────────────────────────────────
class MemoryObjectsDisplay extends StatefulWidget {
  const MemoryObjectsDisplay({
    super.key,
    required this.emojis,
    required this.memoryVisible,
    required this.duration,
  });

  final List<String> emojis;
  final bool memoryVisible;
  final Duration duration;

  @override
  State<MemoryObjectsDisplay> createState() => _MemoryObjectsDisplayState();
}

class _MemoryObjectsDisplayState extends State<MemoryObjectsDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timerCtrl;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.memoryVisible) {
      _timerCtrl.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant MemoryObjectsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.memoryVisible && !oldWidget.memoryVisible) {
      _timerCtrl.forward(from: 0.0);
    } else if (!widget.memoryVisible) {
      _timerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.memoryVisible) {
      return const SizedBox(height: 80);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: widget.emojis
                .map((e) => Text(
                      e,
                      style: const TextStyle(fontSize: 48),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 180,
          height: 8,
          decoration: BoxDecoration(
            color: GameColors.cardBorder,
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _timerCtrl,
            builder: (context, _) {
              final progress = 1.0 - _timerCtrl.value;
              Color barColor = GameColors.teal;
              if (progress < 0.3) {
                barColor = GameColors.softRed;
              } else if (progress < 0.6) {
                barColor = GameColors.orange;
              }
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

