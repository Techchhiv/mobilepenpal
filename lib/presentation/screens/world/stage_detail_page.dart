
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class StageDetailPage extends GetView<StageController> {
  const StageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => LoadingOverlay(
          isLoading: controller.isSubmitting.value,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2B7A78),
                  Color(0xFF6B9F8E),
                  Color(0xFF8FB99F),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(context),
                  const SizedBox(height: 20),
                  _buildIllustration(),
                  const SizedBox(height: 30),
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
        ),
      ),
    );
  }

  // ───────────────── Top bar ─────────────────

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

          // ───── Pause button with modal ─────
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

  // ───────────────── Bird illustration ─────────────────

  Widget _buildIllustration() {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 60,
            child: Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade300.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.flutter_dash,
              size: 60,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Drawing board ─────────────────
  Widget _buildDrawingBoard() {
    return Center(
      child: Obx(() {
        final feedbackState = controller.feedback.value;
        final dx = feedbackState == DrawFeedback.wrong
            ? controller.shakeOffset.value
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
                    child: DrawingBoard(
                      controller: controller.drawingController,
                      background: Obx(() {
                        return Container(
                          width: controller.boardWidth,
                          height: controller.boardHeight,
                          color: Colors.white,
                          child: Stack(
                            children: [
                              Center(
                                child: Opacity(
                                  opacity: 0.15,
                                  child: Text(
                                    controller
                                            .selectedCharacter
                                            .value
                                            .isNotEmpty
                                        ? controller.selectedCharacter.value
                                        : "ក",
                                    style: TextStyle(
                                      fontSize: controller.fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      showDefaultTools: false,
                      onPointerDown: (_) => controller.onPointerDown(),
                      onPointerUp: (_) async => await controller.onPointerUp(),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: controller.confettiController,
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

                Obx(() {
                  final feedbackState = controller.feedback.value;
                  final praise = controller.praiseText.value;

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() {
        final forms = controller.characterVowelFormsList;
        if (forms.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: forms.map((char) {
            return SizedBox(
              width: 40,
              height: 30,
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
        );
      }),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: controller.clearBoard,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.pink.shade200, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.pink.shade300),
                    SizedBox(width: 8),
                    Text(
                      "delete".tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: controller.skipCurrentExercise,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.skip_next, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "skip".tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
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
                // Mascot / icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets, // placeholder mascot
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
                        onPressed: () {
                          Navigator.of(ctx).pop();

                          controller.clearBoard();
                          controller.attempts.clear();

                          final worldRoute = RouteBuilder.build(
                            AppRoutes.world,
                            {'id': controller.worldId.toString()},
                          );
                          Get.offAllNamed(worldRoute);
                        },
                        child: const Icon(Icons.home, size: 32),
                      ),
                    ),

                    const SizedBox(width: 12),
                    // Resume
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
