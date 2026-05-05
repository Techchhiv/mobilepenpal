import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/models/mini_game/challenge_generator.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/dynamic_game_widgets.dart';
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

    return _buildDefaultDisplay(challenge, displayType);
  }

  // ── Drag & Drop Display ──────────────────────────────────────────
  Widget _buildDragAndDropDisplay() {
    return AnimatedBuilder(
      animation: controller.promptBounceCtrl,
      builder: (_, child) {
        final dy = -3 * controller.promptBounceCtrl.value;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Text(
          'Match the pairs 🔀',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
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
                                  'Tap to listen again',
                                  style: TextStyle(
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
                    'How many were there? 🤔',
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
                        'Tap to listen',
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
                  // Easy & Medium: show word with blank
                  RichText(
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
                  if (hint == 'with_image') ...
                    [
                      // Easy: show an image or text hint
                      controller.currentChallenge.value?.imagePath != null
                          ? Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.asset(
                                controller.currentChallenge.value!.imagePath!,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🖼️ Hint: $fullWord',
                                style: const TextStyle(
                                  color: Color(0xFF4ECDC4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ],
                ],
            ],
          ),
        ),
      );
    });
  }

  List<TextSpan> _buildBlankWordSpans(String blankWord) {
    // Replace the '_' placeholder with a styled underline
    final spans = <TextSpan>[];
    for (int i = 0; i < blankWord.length; i++) {
      if (blankWord[i] == '_') {
        spans.add(const TextSpan(
          text: ' __ ',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 42,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFFFFD700),
            decorationThickness: 3,
          ),
        ));
      } else {
        spans.add(TextSpan(text: blankWord[i]));
      }
    }
    return spans;
  }

  // ── Input Module ──────────────────────────────────────────────────
  Widget _buildInputModule(BuildContext context) {
    return Obx(() {
      switch (controller.currentInputType.value) {
        case 'drawing_board':
          return _buildDrawingBoardInput();
        case 'multiple_choice':
          return _buildMultipleChoiceInput();
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
        showGuiding: displayType != 'math_equation' && showGuide,
        activeBoardCount: 1,
        useExpanded: false,
      );
    });
  }

  Widget _buildMultipleChoiceInput() {
    return Obx(() {
      final options = controller.currentOptions;
      if (options.isEmpty) return const SizedBox();

      // Adapt grid layout based on option count
      final crossAxisCount = options.length <= 4 ? 2 : (options.length <= 6 ? 3 : 4);
      final aspectRatio = options.length <= 4 ? 1.5 : 1.2;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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
      String topLabel;
      String bottomLabel;
      switch (displayType) {
        case 'object_count':
          topLabel = 'Digits';
          bottomLabel = 'Objects';
          break;
        case 'missing_character':
          topLabel = 'Pictures';
          bottomLabel = 'Letters';
          break;
        default:
          topLabel = 'Pictures';
          bottomLabel = 'Letters';
          break;
      }

      final validSources = sources.where((p) => p.source.isNotEmpty).toList();

      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Exact calculation: available width minus the Wrap spacing (12), divided by 2.
                final cardWidth = (constraints.maxWidth - 12) / 2;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top section label ──
                Text(
                  topLabel,
                  style: TextStyle(color: GameColors.textDark.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                // ── Top: sources stacked vertically (Draggable) ──
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: validSources.map((pair) {
                    final isMatched = pair.matched;
                    final isSelected = selectedSrc == pair.source;
                    final state = isMatched ? 'matched' : (isSelected ? 'selected' : 'normal');

                    final card = MatchCard(
                      content: pair.source,
                      state: state,
                      onTap: () => controller.selectDragSource(pair.source),
                    );

                    if (isMatched) {
                      return SizedBox(width: cardWidth, child: card);
                    }

                    return LongPressDraggable<String>(
                      data: pair.source,
                      delay: const Duration(milliseconds: 100),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.85,
                          child: SizedBox(
                            width: cardWidth,
                            child: MatchCard(
                              content: pair.source,
                              state: 'selected',
                              onTap: () {},
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: SizedBox(
                        width: cardWidth,
                        child: Opacity(
                          opacity: 0.3,
                          child: card,
                        ),
                      ),
                      onDragStarted: () => controller.selectDragSource(pair.source),
                      child: SizedBox(width: cardWidth, child: card),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                // ── Divider ──
                Row(
                  children: [
                    const Expanded(child: Divider(color: GameColors.cardBorder, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Match to', style: TextStyle(color: GameColors.textDark.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const Expanded(child: Divider(color: GameColors.cardBorder, thickness: 1.5)),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Bottom section label ──
                Text(
                  bottomLabel,
                  style: TextStyle(color: GameColors.textDark.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                // ── Bottom: targets stacked vertically (DragTarget) ──
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: targets.map((pair) {
                    final isMatched = pair.matched;
                    final isWrong = wrongTarget == pair.target;
                    final state = isMatched ? 'matched' : (isWrong ? 'wrong' : 'normal');

                    return SizedBox(
                      width: cardWidth,
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
                              onTap: () => controller.selectDragTarget(pair),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
});
  }

  // ── Top Bar ────────────────────────────────────────────────────────
  Widget _buildGameTopBar(BuildContext context) {
    return Row(
      children: [
        Obx(() => DifficultyChip(
          difficulty: controller.difficulty.value,
          onTap: () {
            final current = controller.difficulty.value;
            if (current == MiniGameDifficulty.easy) {
              controller.forceDifficultyForShowcase(MiniGameDifficulty.medium);
            } else if (current == MiniGameDifficulty.medium) {
              controller.forceDifficultyForShowcase(MiniGameDifficulty.hard);
            } else {
              controller.forceDifficultyForShowcase(MiniGameDifficulty.easy);
            }
          },
        )),
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
              label: 'Clear',
              icon: Icons.delete_outline_rounded,
              color: GameColors.softRed,
              onTap: () => controller.clearBoard(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GameActionButton(
              label: 'Submit',
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
      color: GameColors.card,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: GameColors.gold, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Great Job!',
                    style: TextStyle(color: GameColors.textDark, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You practiced Khmer letters!',
                    style: TextStyle(color: GameColors.textMuted, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),
                  StatRow(label: 'Score', value: '${controller.score.value}', color: GameColors.gold),
                  StatRow(label: 'Best Combo', value: '${controller.bestCombo.value}x', color: GameColors.orange),
                  StatRow(label: 'Accuracy', value: '${controller.accuracy.toStringAsFixed(1)}%', color: GameColors.teal),
                  StatRow(label: 'Answered', value: '${controller.correctCount.value}/${controller.totalAnswered.value}', color: GameColors.green),
                  
                  if (controller.score.value >= controller.highScore.value && controller.score.value > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('NEW HIGH SCORE!', style: TextStyle(color: GameColors.pink, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    )
                  else
                    const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: GameActionButton(
                          label: 'Home', icon: Icons.home_rounded,
                          color: GameColors.pink, onTap: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GameActionButton(
                          label: 'Play Again', icon: Icons.play_arrow_rounded,
                          color: GameColors.teal,
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
