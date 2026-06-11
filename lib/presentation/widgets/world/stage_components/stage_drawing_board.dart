import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/widgets/world/board_grid_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/letter_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/morph_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_attempts_indicator.dart';

typedef BoardPointerDown = void Function(PointerDownEvent e, int boardIndex);
typedef BoardPointerMove = void Function(PointerMoveEvent e, int boardIndex);
typedef BoardPointerUp = void Function(PointerUpEvent e, int boardIndex);

/// A reusable drawing-board area.
///
/// Passive widget: Does not manage its own high-level Obx.
/// Caller provides all state.
class StageDrawingBoard extends StatelessWidget {
  const StageDrawingBoard({
    super.key,
    required this.boardWidth,
    required this.boardHeight,
    required this.onUpdateBoardSize,
    required this.drawingControllers,
    required this.letterSubpathsNorm,
    required this.scale,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.attemptLeft,
    required this.maxAttempts,
    required this.feedbackState,
    required this.praiseFeedbackState,
    required this.shakeOffset,
    required this.praiseText,
    required this.confettiController,
    required this.guideCirclePx,
    required this.isGuiding,
    this.showGuiding = true,
    this.activeBoardCount = 1,
    this.topLeadingOverlay,
    this.useExpanded = true,
    this.showMorph = false,
    this.morphProgress = 0.0,
    this.userMorphStrokes = const [],
    this.templateMorphStrokes = const [],
    this.stampImage,
  });

  final double boardWidth;
  final double boardHeight;
  final void Function(double width, {double? height}) onUpdateBoardSize;
  final List<DrawingController> drawingControllers;
  final List<List<Offset>> letterSubpathsNorm;
  final double scale;
  final BoardPointerDown onPointerDown;
  final BoardPointerMove onPointerMove;
  final BoardPointerUp onPointerUp;
  final int attemptLeft;
  final int maxAttempts;

  // Animation values
  final DrawFeedback feedbackState;
  final DrawFeedback praiseFeedbackState;
  final double shakeOffset;
  final String praiseText;
  final ConfettiController confettiController;
  final Offset? guideCirclePx;
  final bool isGuiding;
  final bool showGuiding;

  final int activeBoardCount;
  final Widget? topLeadingOverlay;
  final bool useExpanded;

  // Morph parameters
  final bool showMorph;
  final double morphProgress;
  final List<List<Offset>> userMorphStrokes;
  final List<List<Offset>> templateMorphStrokes;
  final ui.Image? stampImage;

  @override
  Widget build(BuildContext context) {
    if (useExpanded) return Expanded(child: _buildBoards());
    return _buildBoards();
  }

  Widget _buildBoards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxFeedbackScale = 1.06;
        final boardsNum = activeBoardCount;
        final gap = 6.0;
        final totalGap = (boardsNum > 1) ? gap * (boardsNum - 1) : 0.0;
        final maxBoardWidth = (constraints.maxWidth - totalGap) / boardsNum;
        final width = maxBoardWidth / maxFeedbackScale;
        final height = (boardsNum > 1)
            ? (constraints.maxHeight * 0.75 / maxFeedbackScale)
            : (width < constraints.maxHeight ? width : constraints.maxHeight);

        if (boardWidth != width || boardHeight != height) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onUpdateBoardSize(width, height: height);
          });
        }

        final dx = feedbackState == DrawFeedback.wrong ? shakeOffset : 0.0;

        double scaleVal;
        switch (feedbackState) {
          case DrawFeedback.correct:
            scaleVal = 1.05;
            break;
          case DrawFeedback.wrong:
            scaleVal = 1.06;
            break;
          default:
            scaleVal = 1.0;
        }

        final blockWidth = boardsNum > 1
            ? (width * boardsNum + totalGap)
            : width;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: blockWidth,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedScale(
                    scale: scaleVal,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          boardsNum > 1
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(boardsNum, (index) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index < boardsNum - 1 ? 6.0 : 0,
                                      ),
                                      child: _buildSingleBoard(
                                        width,
                                        height,
                                        index,
                                      ),
                                    );
                                  }),
                                )
                              : _buildSingleBoard(width, height, 0),

                          // Confetti
                          Align(
                            alignment: Alignment.center,
                            child: ConfettiWidget(
                              confettiController: confettiController,
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

                          // Praise text overlay
                          _buildPraiseText(
                            feedbackState,
                            praiseFeedbackState,
                            praiseText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (topLeadingOverlay != null)
                  Positioned(
                    top: -46,
                    left: 8,
                    child: IgnorePointer(child: topLeadingOverlay!),
                  ),
                Positioned(
                  top: -36,
                  right: 8,
                  child: IgnorePointer(
                    child: StageAttemptsIndicator(
                      attemptLeft: attemptLeft,
                      maxAttempts: maxAttempts,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleBoard(double width, double height, int boardIndex) {
    final s = scale;
    final r = 11.0 * s;

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
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: showMorph ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => onPointerDown(e, boardIndex),
                  onPointerMove: (e) => onPointerMove(e, boardIndex),
                  onPointerUp: (e) => onPointerUp(e, boardIndex),
                  child: DrawingBoard(
                    boardPanEnabled: false,
                    boardScaleEnabled: false,
                    controller: drawingControllers[boardIndex],
                    background: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(painter: BoardGridPainter()),
                            ),
                          ),
                          if (showGuiding &&
                              letterSubpathsNorm.isNotEmpty &&
                              boardIndex == 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: LetterPointsPainter(
                                    letterSubpathsNorm: letterSubpathsNorm,
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
                          if (showGuiding &&
                              isGuiding &&
                              guideCirclePx != null &&
                              boardIndex == 0)
                            Positioned(
                              left: guideCirclePx!.dx - r,
                              top: guideCirclePx!.dy - r,
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
                    ),
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
                        if (showGuiding && letterSubpathsNorm.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: LetterPointsPainter(
                                letterSubpathsNorm: letterSubpathsNorm,
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
        ),
      ),
    );
  }

  Widget _buildPraiseText(
    DrawFeedback feedback,
    DrawFeedback praiseFeedback,
    String text,
  ) {
    final isWrong = praiseFeedback == DrawFeedback.wrong;
    final isVisible = feedback != DrawFeedback.none && text.isNotEmpty;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isWrong ? Colors.redAccent : Colors.yellow.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWrong ? Icons.info_outline : Icons.star,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
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
  }
}
