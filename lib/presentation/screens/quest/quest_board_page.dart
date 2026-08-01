import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_board_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_drawing_board.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_top_bar.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_pause_dialog.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_variant_bar.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/mascot_board_illustration.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_floating_action_buttons.dart';
import 'package:mobilepenpal/data/controllers/dashboard/navigation_controller.dart';

class QuestBoardPage extends GetView<QuestBoardController> {
  const QuestBoardPage({super.key});

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
            isLoading:
                controller.isLoading.value || controller.isSubmitting.value,
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
                            // Top Navigation Header
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

                            // Top Variant Bar: Character Options + Audio Speaker
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

                            // 1:1 Aspect Ratio Drawing Grid Board
                            if (!controller.isLoading.value &&
                                controller.exercises.isNotEmpty)
                              Obx(
                                () => StageDrawingBoard(
                                  boardWidth: controller.boardWidth.value,
                                  boardHeight: controller.boardHeight.value,
                                  onUpdateBoardSize: controller.updateBoardSize,
                                  drawingControllers:
                                      controller.drawingControllers,
                                  letterSubpathsNorm:
                                      controller.letterSubpathsNorm,
                                  scale: controller.scale,
                                  onPointerDown: controller.onRawPointerDown,
                                  onPointerMove: controller.onRawPointerMove,
                                  onPointerUp: controller.onRawPointerUp,
                                  attemptLeft: controller.attemptLeft.value,
                                  maxAttempts: QuestBoardController
                                      .maxAttemptsPerExercise,
                                  feedbackState: controller.anim.feedback.value,
                                  praiseFeedbackState:
                                      controller.anim.praiseFeedback.value,
                                  shakeOffset:
                                      controller.anim.shakeOffset.value,
                                  praiseText: controller.anim.praiseText.value,
                                  confettiController:
                                      controller.anim.confettiController,
                                  guideCirclePx:
                                      controller.anim.guideCirclePx.value,
                                  isGuiding: controller.anim.isGuiding.value,
                                  showMorph: controller.anim.showMorph.value,
                                  morphProgress:
                                      controller.anim.morphProgress.value,
                                  userMorphStrokes:
                                      controller.anim.userMorphStrokes,
                                  templateMorphStrokes:
                                      controller.anim.templateMorphStrokes,
                                  stampImage: controller.currentStampImage,
                                  showGuiding: true,
                                  activeBoardCount: controller.activeBoardCount,
                                ),
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
                                  // Bottom-Left Mascot Board framing dynamic quest exercise image
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

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return StagePauseDialog(
          onHome: () async {
            Navigator.of(ctx).pop();
            bool hitDashboard = false;
            Get.until((route) {
              if (route.settings.name == AppRoutes.dashboard) {
                hitDashboard = true;
                return true;
              }
              return route.isFirst;
            });
            if (!hitDashboard) {
              Get.offAllNamed(AppRoutes.dashboard);
            }
            if (Get.isRegistered<NavigationController>()) {
              Get.find<NavigationController>().changePage(2);
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
