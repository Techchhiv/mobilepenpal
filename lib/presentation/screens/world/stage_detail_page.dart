import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/board_grid_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/letter_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/morph_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_top_bar.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_pause_dialog.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_variant_bar.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/mascot_board_illustration.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_floating_action_buttons.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_attempts_indicator.dart';

class StageDetailPage extends GetView<StageController> {
  const StageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (Get.isDialogOpen == true) return;

        _showPauseDialog(context);
      },
      child: Scaffold(
        body: Obx(
          () => LoadingOverlay(
            isLoading: controller.isSubmitting.value,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/backgrounds/bg_writting.png",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFFCF7F2)),
                  ),
                ),

                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.globalMaxWidth,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            // Top Bar: Mascot Pencil Icon + Star Rating Pill + Pause Button
                            Obx(
                              () => StageTopBar(
                                totalExercises: controller.totalExercises,
                                completedExercises:
                                    controller.completedExercises,
                                exerciseDotStates: controller.exerciseDotStates
                                    .toList(),
                                onActionTap: () =>
                                    _showPauseDialog(Get.context!),
                                actionIcon: Icons.pause,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Top Variant Bar: Variant Characters (e.g. ឆ, ឆា, ឆិ, ឆី) + Audio Speaker
                            Obx(() {
                              final variants =
                                  controller.characterVowelFormsList;
                              final currentSelected =
                                  controller.selectedCharacter.value;
                              final activeIndex = variants
                                  .indexOf(currentSelected)
                                  .clamp(
                                    0,
                                    variants.isEmpty ? 0 : variants.length - 1,
                                  );

                              return StageVariantBar(
                                variants: variants,
                                currentIndex: activeIndex,
                                onVariantSelected: (index) {
                                  // Variant selection disabled since variant audio files are currently missing.
                                  // Always play the dynamic exercise character audio (consonant, vowel, or number).
                                  controller.playCurrentCharacterAudio();

                                  /*
                                  if (index >= 0 && index < variants.length) {
                                    controller.selectedCharacter.value =
                                        variants[index];
                                    controller.playCurrentCharacterAudio();
                                  }
                                  */
                                },
                                onSpeakerTap: () {
                                  controller.playCurrentCharacterAudio();
                                },
                              );
                            }),

                            const SizedBox(height: 8),

                            // 1:1 Aspect Ratio Drawing Grid
                            _buildDrawingBoard(
                              showShadowGuide: !controller.isMathCurrent,
                            ),

                            const SizedBox(height: 12),

                            // Bottom Area: Bottom-Left Mascot Board + Bottom-Right Action Buttons
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 0,
                                right: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Bottom-Left Mascot Board framing dynamic character image
                                  Obx(
                                    () => MascotBoardIllustration(
                                      illustrationWidget:
                                          _buildIllustrationContent(),
                                      height: 230,
                                    ),
                                  ),

                                  const Spacer(),

                                  // Bottom-Right Action Controls (Delete & Skip/Next)
                                  Obx(
                                    () => StageFloatingActionButtons(
                                      onClear: controller.clearBoard,
                                      onSubmitOrSkip:
                                          controller.skipCurrentExercise,
                                      isSubmitting:
                                          controller.isSubmitting.value,
                                      submitIcon: Icons.skip_next_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationContent() {
    if (controller.isMathCurrent) {
      final raw = controller.mathPrompt.value;
      final km = NumberFormatUtils.digitsByLocale(raw, forceKhmer: true);

      return Text(
        km,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2B7A6B),
        ),
      );
    }

    final path = controller.anim.illustrationAssetPath.value;
    if (path.isNotEmpty) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          controller.selectedCharacter.value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2B7A6B),
          ),
        ),
      );
    }

    return Text(
      controller.selectedCharacter.value,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: Color(0xFF2B7A6B),
      ),
    );
  }

  Widget _buildAttemptsIndicator() {
    return Obx(() {
      return StageAttemptsIndicator(
        attemptLeft: controller.attemptLeft.value,
        maxAttempts: StageController.maxAttemptsPerExercise,
      );
    });
  }

  Widget _buildDrawingBoard({bool showShadowGuide = true}) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Obx(() {
              final boardsNum = controller.activeBoardCount;
              return LayoutBuilder(
                builder: (context, constraints) {
                  const maxFeedbackScale = 1.06;
                  final gap = 0.0;
                  final totalGap = (boardsNum > 1)
                      ? gap * (boardsNum - 1)
                      : 0.0;
                  final maxBoardWidth =
                      (constraints.maxWidth - totalGap) / boardsNum;
                  final width = maxBoardWidth / maxFeedbackScale;
                  final height = (boardsNum > 1)
                      ? (constraints.maxHeight * 0.75 / maxFeedbackScale)
                      : (width < constraints.maxHeight
                            ? width
                            : constraints.maxHeight);

                  if (controller.boardWidth.value != width ||
                      controller.boardHeight.value != height) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.updateBoardSize(width, height: height);
                    });
                  }

                  return Center(
                    child: Obx(() {
                      final feedbackState = controller.anim.feedback.value;
                      final dx = feedbackState == DrawFeedback.wrong
                          ? controller.anim.shakeOffset.value
                          : 0.0;

                      double scale;
                      switch (feedbackState) {
                        case DrawFeedback.correct:
                          scale = 1.05;
                          break;
                        case DrawFeedback.wrong:
                          scale = 1.06;
                          break;
                        default:
                          scale = 1.0;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            child: Transform.translate(
                              offset: Offset(dx, 0),
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    bottom: -30,
                                    right: 12,
                                    child: IgnorePointer(
                                      child: _buildAttemptsIndicator(),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(boardsNum, (index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: index < boardsNum - 1
                                              ? 6.0
                                              : 0,
                                        ),
                                        child: _buildSingleBoard(
                                          width,
                                          height,
                                          index,
                                          showShadowGuide: showShadowGuide,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: ConfettiWidget(
                                confettiController:
                                    controller.anim.confettiController,
                                blastDirectionality:
                                    BlastDirectionality.explosive,
                                emissionFrequency: 0.01,
                                numberOfParticles: 25,
                                maxBlastForce: 30,
                                minBlastForce: 10,
                                gravity: 0.25,
                                shouldLoop: false,
                              ),
                            ),
                          ),
                          Obx(() {
                            final praise = controller.anim.praiseText.value;
                            final isWrong = feedbackState == DrawFeedback.wrong;
                            final isVisible =
                                feedbackState != DrawFeedback.none &&
                                praise.isNotEmpty;

                            return Positioned(
                              top: 50,
                              child: AnimatedScale(
                                scale: isVisible ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.elasticOut,
                                child: AnimatedOpacity(
                                  opacity: isVisible ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isWrong
                                          ? Colors.redAccent
                                          : Colors.yellow.shade700,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.20,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isWrong
                                              ? Icons.info_outline
                                              : Icons.star,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          praise,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBoard(
    double width,
    double height,
    int boardIndex, {
    bool showShadowGuide = true,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Obx(() {
          final showMorph = controller.anim.showMorph.value;
          final morphProgress = controller.anim.morphProgress.value;
          final userMorphStrokes = controller.anim.userMorphStrokes;
          final templateMorphStrokes = controller.anim.templateMorphStrokes;
          final stampImage = controller.currentStampImage;
          final s = controller.scale;

          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: showMorph ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) =>
                        controller.onRawPointerDown(e, boardIndex),
                    onPointerMove: (e) =>
                        controller.onRawPointerMove(e, boardIndex),
                    onPointerUp: (e) =>
                        controller.onRawPointerUp(e, boardIndex),
                    child: DrawingBoard(
                      boardPanEnabled: false,
                      boardScaleEnabled: false,
                      controller: controller.drawingControllers[boardIndex],
                      background: Obx(() {
                        final letter = controller.letterSubpathsNorm;
                        final p = controller.anim.guideCirclePx.value;
                        final guiding = controller.anim.isGuiding.value;
                        final r = 11.0 * s;

                        return SizedBox(
                          width: width,
                          height: height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: BoardGridPainter(),
                                  ),
                                ),
                              ),
                              if (showShadowGuide &&
                                  letter.isNotEmpty &&
                                  boardIndex == 0)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: LetterPointsPainter(
                                        letterSubpathsNorm: letter,
                                        toBoardPx: (o) => o,
                                        fillEnabled: true,
                                        strokeEnabled: true,
                                        fillOpacity: 0.15,
                                        strokeOpacity: 0.25,
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                              if (showShadowGuide &&
                                  guiding &&
                                  p != null &&
                                  boardIndex == 0)
                                Positioned(
                                  left: p.dx - r,
                                  top: p.dy - r,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: r * 2,
                                      height: r * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          width: 4 * s,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      showDefaultActions: false,
                      showDefaultTools: false,
                    ),
                  ),
                ),
              ),
              if (boardIndex == 0)
                Positioned.fill(
                  child: Visibility(
                    visible: showMorph,
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: BoardGridPainter()),
                          ),
                          if (showShadowGuide &&
                              controller.letterSubpathsNorm.isNotEmpty)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LetterPointsPainter(
                                  letterSubpathsNorm:
                                      controller.letterSubpathsNorm,
                                  toBoardPx: (o) => o,
                                  fillEnabled: true,
                                  strokeEnabled: true,
                                  fillOpacity: 0.15,
                                  strokeOpacity: 0.25,
                                  strokeWidth: 2.0,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: MorphPainter(
                                userStrokes: userMorphStrokes,
                                templateStrokes: templateMorphStrokes,
                                progress: morphProgress,
                                strokeWidth: 6.0 * s,
                                stampImage: stampImage,
                                stampSize: 24.0 * s,
                                spacing: 16.0 * s,
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
        }),
      ),
    );
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return StagePauseDialog(
          onHome: () async {
            controller.isSubmitting.value = true;
            try {
              Navigator.of(ctx).pop();
              if (Get.isRegistered<LevelController>()) {
                final lc = Get.find<LevelController>();
                await lc.fetchLevelDetail();
              }

              bool hitLevel = false;
              Get.until((route) {
                final name = route.settings.name ?? '';
                final isLevelOnly =
                    name.contains('/level/') && !name.contains('/stage/');
                if (isLevelOnly) hitLevel = true;
                return isLevelOnly;
              });

              if (!hitLevel) {
                final levelRoute = RouteBuilder.build(AppRoutes.level, {
                  'worldId': controller.worldId.toString(),
                  'levelId': controller.levelId.toString(),
                });
                Get.offNamed(levelRoute);
              }
            } finally {
              controller.isSubmitting.value = false;
            }
          },
          onRestart: () async {
            Navigator.of(ctx).pop();
            await controller.resetForRetry();
          },
          onResume: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}
