import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/data/models/mini_game/challenge_generator.dart';
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
              constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
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
                    Obx(() => _buildDisplayModule()),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          return LinearProgressIndicator(
                            value: controller.mediumTimerCtrl.value,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
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
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    secondChild: diff == MiniGameDifficulty.medium
                        ? const Text(
                            '?',
                            style: TextStyle(
                              color: GameColors.textMuted,
                              fontSize: 64,
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
              AnimatedOpacity(
                opacity: (layout == 'memory' && !memoryVisible) ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 600),
                child: layout == 'scattered'
                    ? _buildScatteredEmojis(emojis)
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: emojis
                            .map((e) => Text(e, style: const TextStyle(fontSize: 36)))
                            .toList(),
                      ),
              ),
              if (layout == 'memory' && !memoryVisible)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'how_many_were_there'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildScatteredEmojis(List<String> emojis) {
    // Build a small container with randomly placed emojis
    final rng = math.Random(emojis.length); // seeded so positions are stable
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: emojis.asMap().entries.map((e) {
          final dx = rng.nextDouble() * 200 - 100;
          final dy = rng.nextDouble() * 40 - 10;
          final rotation = (rng.nextDouble() - 0.5) * 0.4;
          return Positioned(
            left: 80 + dx,
            top: 10 + dy,
            child: Transform.rotate(
              angle: rotation,
              child: Text(e.value, style: const TextStyle(fontSize: 32)),
            ),
          );
        }).toList(),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: GameColors.teal.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                controller.currentChallenge.value!.imagePath!,
                                height: 90, // Reduced size based on feedback
                                fit: BoxFit.contain,
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.only(bottom: 24),
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
                        fontSize: 64, // Slightly larger font for children
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
      );
    });
  }

  Widget _buildMultipleChoiceInput(BuildContext context) {
    return Obx(() {
      final options = controller.currentOptions;
      if (options.isEmpty) return const SizedBox();

      final screenHeight = MediaQuery.of(context).size.height;
      final isTallScreen = screenHeight > 800;

      // Adapt grid layout based on option count and screen height
      final int crossAxisCount;
      final double aspectRatio;

      if (options.length <= 4) {
        crossAxisCount = 2;
        aspectRatio = 1.15;
      } else if (options.length <= 6) {
        if (isTallScreen) {
          crossAxisCount = 2; // Renders 3 rows
          aspectRatio = 1.2;
        } else {
          crossAxisCount = 3; // Renders 2 rows
          aspectRatio = 1.0;
        }
      } else {
        // More than 6 options (typically 8)
        if (isTallScreen) {
          crossAxisCount = 2; // Renders 4 rows (large cards)
          aspectRatio = 1.4;
        } else {
          crossAxisCount = 3; // Renders 3 rows (3, 3, 2)
          aspectRatio = 1.0;
        }
      }

      final spacing = isTallScreen ? 18.0 : 16.0;

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
                      children: validSources.map((pair) {
                        final isMatched = pair.matched;
                        final isSelected = selectedSrc == pair.source;
                        final state = isMatched ? 'matched' : (isSelected ? 'selected' : 'normal');

                        final card = MatchCard(
                          content: pair.source,
                          state: state,
                          scale: cardScale,
                          onTap: () => controller.selectDragSource(pair.source),
                        );

                        if (isMatched) {
                          return Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: card,
                            ),
                          );
                        }

                        return Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: LongPressDraggable<String>(
                              data: pair.source,
                              delay: const Duration(milliseconds: 100),
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    child: MatchCard(
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
                      children: targets.map((pair) {
                        final isMatched = pair.matched;
                        final isWrong = wrongTarget == pair.target;
                        final state = isMatched ? 'matched' : (isWrong ? 'wrong' : 'normal');

                        return Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: DragTarget<String>(
                              onWillAcceptWithDetails: (details) => !isMatched,
                              onAcceptWithDetails: (details) {
                                controller.submitDragDrop(details.data, pair);
                              },
                              builder: (context, candidateData, rejectedData) {
                                final isHovering = candidateData.isNotEmpty;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: isHovering && !isMatched
                                      ? BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(color: GameColors.teal.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
                                          ],
                                        )
                                      : null,
                                  child: MatchCard(
                                    content: pair.target,
                                    state: isHovering && !isMatched ? 'selected' : state,
                                    scale: cardScale,
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

  // ── Game Over ─────────────────────────────────────────────────────
  Widget _buildGameOverScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C5364), Color(0xFF1B2838)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'game_over'.tr,
                    style: TextStyle(
                      color: GameColors.softRed,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Large gradient score ──
                  Text(
                    'score'.tr.toUpperCase(),
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

                  // ── High score badge ──
                  if (controller.score.value >= controller.highScore.value && controller.score.value > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: GameColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GameColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: GameColors.gold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'new_high_score'.tr.toUpperCase(),
                            style: TextStyle(
                              color: GameColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 1,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 8),

                  const SizedBox(height: 24),

                  // ── Stats grid ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _resultStat('🏆', 'best_score'.tr, '${controller.highScore.value}'),
                            ),
                            Expanded(
                              child: _resultStat('🪙', 'coins_earned'.tr, '${controller.earnedCoins.value}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _resultStat('🔥', 'best_combo'.tr, '${controller.bestCombo.value}x'),
                            ),
                            Expanded(
                              child: _resultStat('🎯', 'accuracy'.tr, '${controller.accuracy.toStringAsFixed(0)}%'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Answered breakdown
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

                  const SizedBox(height: 28),

                  // ── Action buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: _gameOverButton(
                          label: 'home'.tr,
                          icon: Icons.home_rounded,
                          color: Colors.white.withValues(alpha: 0.08),
                          textColor: Colors.white70,
                          onTap: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _gameOverButton(
                          label: 'play_again'.tr,
                          icon: Icons.replay_rounded,
                          color: GameColors.teal,
                          textColor: Colors.white,
                          onTap: () {
                            controller.startGame();
                            controller.pauseGame();
                            controller.startCountdown();
                          },
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
