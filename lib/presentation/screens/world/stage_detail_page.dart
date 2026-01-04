import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/letter_painter.dart';

class StageDetailPage extends GetView<StageController> {
  const StageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => LoadingOverlay(
          isLoading: controller.isSubmitting.value,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/images/backgrounds/stage_background.png",
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.25)),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF2B7A78).withValues(alpha: 0.55),
                        Color(0xFF6B9F8E).withValues(alpha: 0.35),
                        Color(0xFF8FB99F).withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTopBar(Get.context!),
                      const SizedBox(height: 20),
                      _buildIllustration(),
                      const SizedBox(height: 10),
                      _buildDrawingBoard(),
                      const SizedBox(height: 16),
                      _buildCharacterOptions(),
                      const Spacer(),
                      _buildBottomButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange.shade300,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Obx(() {
                final total = controller.exercises.length;
                final currentIndex = controller.currentExerciseIndex.value;

                if (total == 0) {
                  return const SizedBox.shrink();
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (index) {
                    final isCompleted = index < currentIndex;
                    final isCurrent = index == currentIndex;

                    IconData icon;
                    Color color;

                    if (isCompleted) {
                      icon = Icons.circle;
                      color = Colors.green.shade400;
                    } else if (isCurrent) {
                      icon = Icons.circle;
                      color = Colors.pink.shade300;
                    } else {
                      icon = Icons.circle_outlined;
                      color = Colors.grey.shade400;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(icon, color: color, size: 18),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: () => _showPauseDialog(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pause, color: Colors.blue, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    int? parseKhmerDigit(String raw) {
      final s = raw.trim();
      if (s.isEmpty) return null;

      final ascii = int.tryParse(s);
      if (ascii != null) return ascii;

      const map = {
        '០': 0,
        '១': 1,
        '២': 2,
        '៣': 3,
        '៤': 4,
        '៥': 5,
        '៦': 6,
        '៧': 7,
        '៨': 8,
        '៩': 9,
      };
      if (s.length == 1) return map[s];
      return null;
    }

    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Obx(() {
              final path = controller.anim.illustrationAssetPath.value;
              final ch = controller.selectedCharacter.value;
              final digit = parseKhmerDigit(ch);

              if (digit != null) {
                final count = digit == 0 ? 1 : digit;

                double itemSize;
                if (count <= 3) {
                  itemSize = 54;
                } else if (count <= 5) {
                  itemSize = 42;
                } else {
                  itemSize = 32;
                }

                final spacing = count > 5 ? 6.0 : 8.0;

                final List<int> row1;
                final List<int> row2;

                if (count <= 5) {
                  row1 = List.generate(count, (i) => i);
                  row2 = const [];
                } else {
                  final firstRowCount = (count / 2).ceil();
                  row1 = List.generate(firstRowCount, (i) => i);
                  row2 = List.generate(count - firstRowCount, (i) => i);
                }

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row1
                            .map(
                              (_) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing / 2,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: itemSize,
                                    height: itemSize,
                                    color: Colors.white.withValues(alpha: 0.10),
                                    child: path.isEmpty
                                        ? Icon(
                                            Icons.image_outlined,
                                            color: Colors.grey.shade300,
                                          )
                                        : Image.asset(
                                            path,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (row2.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row2
                              .map(
                                (_) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing / 2,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: itemSize,
                                      height: itemSize,
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                      child: path.isEmpty
                                          ? Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey.shade300,
                                            )
                                          : Image.asset(
                                              path,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: path.isEmpty
                        ? Icon(
                            Icons.image_outlined,
                            size: 44,
                            color: Colors.grey.shade600,
                          )
                        : Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported_outlined,
                              size: 44,
                              color: Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),

          Obx(() {
            final ch = controller.selectedCharacter.value;
            final digit = parseKhmerDigit(ch);
            if (digit != null) return const SizedBox.shrink();

            final label = controller.anim.illustrationLabel.value;
            if (label.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawingBoard() {
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

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: controller.boardWidth,
                  height: controller.boardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: controller.onRawPointerDown,
                      onPointerMove: controller.onRawPointerMove,
                      onPointerUp: controller.onRawPointerUp,
                      child: DrawingBoard(
                        controller: controller.drawingController,
                        background: Obx(() {
                          final letter = controller.letterSubpathsNorm;

                          final p = controller.anim.guideCirclePx.value;
                          final guiding = controller.anim.isGuiding.value;

                          return Container(
                            width: controller.boardWidth,
                            height: controller.boardHeight,
                            color: Colors.white,
                            child: Stack(
                              children: [
                                if (letter.isNotEmpty)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: LetterPointsPainter(
                                          letterSubpathsNorm: letter,
                                          toBoardPx: (p) => p,
                                          fillEnabled: true,
                                          strokeEnabled: false,
                                          fillOpacity: 0.15,
                                        ),
                                      ),
                                    ),
                                  ),

                                if (guiding && p != null)
                                  Positioned(
                                    left: p.dx - 11,
                                    top: p.dy - 11,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: 4,
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

                        showDefaultTools: false,
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: controller.anim.confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.01,
                    numberOfParticles: 25,
                    maxBlastForce: 30,
                    minBlastForce: 10,
                    gravity: 0.25,
                    shouldLoop: false,
                  ),
                ),

                Obx(() {
                  final praise = controller.anim.praiseText.value;

                  final isVisible =
                      feedbackState == DrawFeedback.correct &&
                      praise.isNotEmpty;

                  return Positioned(
                    top: 10,
                    child: AnimatedScale(
                      scale: isVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      child: AnimatedOpacity(
                        opacity: isVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade700,
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
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
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
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCharacterOptions() {
    return Obx(() {
      final forms = controller.characterVowelFormsList;
      if (forms.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: forms.map((char) {
                      return SizedBox(
                        width: 40,
                        height: 37,
                        child: Center(
                          child: Text(
                            char,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Obx(() {
                  final isPlaying = controller.audio.isPlaying.value;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: isPlaying ? 1.15 : 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 90),
                        curve: Curves.easeOut,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isPlaying)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.9, end: 1.2),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                                builder: (_, ringScale, __) {
                                  return Opacity(
                                    opacity: 0.35,
                                    child: Transform.scale(
                                      scale: ringScale,
                                      child: Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: Ink(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: controller.playCurrentCharacterAudio,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (c, anim) =>
                                          ScaleTransition(
                                            scale: anim,
                                            child: c,
                                          ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.graphic_eq
                                            : Icons.volume_up,
                                        key: ValueKey(isPlaying),
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBottomButtons() {
    Widget buildActionButton({
      required VoidCallback onTap,
      required Color bg,
      required Color fg,
      required IconData icon,
      required String label,
      Color? borderColor,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: buildActionButton(
              onTap: controller.clearBoard,
              bg: Colors.white,
              fg: Colors.pink,
              icon: Icons.delete,
              label: "delete".tr,
              borderColor: Colors.pink.shade200,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: buildActionButton(
              onTap: controller.skipCurrentExercise,
              bg: Colors.orange.shade400,
              fg: Colors.white,
              icon: Icons.skip_next,
              label: "skip".tr,
            ),
          ),
        ],
      ),
    );
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 56,
                    color: Colors.orange.shade700,
                  ),
                ),

                const SizedBox(height: 48),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();

                          controller.isSubmitting.value = true;

                          try {
                            controller.clearBoard();
                            controller.attempts.clear();

                            final levelController = Get.find<LevelController>();

                            await levelController.fetchLevelDetail();

                            final level = levelController.currentLevel.value;

                            if (level == null ||
                                level.id != controller.levelId) {
                              Get.snackbar(
                                'Error',
                                'Failed to load level'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            final levelRoute =
                                RouteBuilder.build(AppRoutes.level, {
                                  'worldId': controller.worldId.toString(),
                                  'levelId': controller.levelId.toString(),
                                });

                            Get.offNamed(levelRoute);
                          } finally {
                            controller.isSubmitting.value = false;
                          }
                        },
                        child: const Icon(Icons.home, size: 32),
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Icon(Icons.play_arrow, size: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
