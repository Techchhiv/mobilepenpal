import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/math_fruit_display.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_drawing_board.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_illustration.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_top_bar.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_pause_dialog.dart';

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
                    "assets/images/backgrounds/stage_background.png",
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2B7A78).withValues(alpha: 1),
                          const Color(0xFF6B9F8E).withValues(alpha: 0.0),
                        ],
                        stops: const [0.15, 0.45],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: Env.globalMaxWidth,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            Obx(
                              () {
                                Widget? avatarWidget;
                                if (Get.isRegistered<HomeController>()) {
                                  final homeController = Get.find<HomeController>();
                                  final ShopAvatar? shopAvatar = homeController.currentShopAvatar;
                                  
                                  if (shopAvatar != null && shopAvatar.id != 'default') {
                                    if (shopAvatar.assetPath != null) {
                                      avatarWidget = Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Image.asset(shopAvatar.assetPath!, fit: BoxFit.contain),
                                      );
                                    } else {
                                      avatarWidget = Icon(
                                        shopAvatar.icon ?? Icons.person,
                                        size: 28,
                                        color: Colors.white,
                                      );
                                    }
                                  } else {
                                    avatarWidget = const Icon(Icons.person, size: 28, color: Colors.white);
                                  }
                                }

                                return StageTopBar(
                                  totalExercises: controller.totalExercises,
                                  completedExercises:
                                      controller.completedExercises,
                                  exerciseDotStates: controller.exerciseDotStates
                                      .toList(),
                                  onActionTap: () =>
                                      _showPauseDialog(Get.context!),
                                  actionIcon: Icons.pause,
                                  avatarWidget: avatarWidget,
                                );
                              }
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final show = controller.showIllustration;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, anim) =>
                                    SizeTransition(
                                      sizeFactor: anim,
                                      axisAlignment: -1.0,
                                      child: child,
                                    ),
                                child: show
                                    ? Column(
                                        key: const ValueKey('illus'),
                                        children: [
                                          _buildIllustrationWrapper(),
                                          const SizedBox(height: 0),
                                        ],
                                      )
                                    : const SizedBox(
                                        key: ValueKey('no_illus'),
                                        height: 20,
                                      ),
                              );
                            }),
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
                                maxAttempts:
                                    StageController.maxAttemptsPerExercise,
                                feedbackState: controller.anim.feedback.value,
                                praiseFeedbackState:
                                    controller.anim.praiseFeedback.value,
                                shakeOffset: controller.anim.shakeOffset.value,
                                praiseText: controller.anim.praiseText.value,
                                confettiController:
                                    controller.anim.confettiController,
                                guideCirclePx:
                                    controller.anim.guideCirclePx.value,
                                isGuiding: controller.anim.isGuiding.value,
                                showGuiding:
                                    true, // TODO: Link to a setting if needed
                                activeBoardCount: controller.activeBoardCount,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCharacterOptions(),
                            const SizedBox(height: 24),
                            _buildBottomButtons(),
                            const SizedBox(height: 8),
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

  /// Wraps the shared [StageIllustration] and provides values from controller.
  Widget _buildIllustrationWrapper() {
    return Obx(() {
      Widget? mathWidget;
      if (controller.isMathCurrent) {
        final raw = controller.mathPrompt.value;
        mathWidget = MathFruitDisplay(prompt: raw);
      }

      return StageIllustration(
        illustrationAssetPath: controller.anim.illustrationAssetPath.value,
        illustrationLabel: controller.anim.illustrationLabel.value,
        selectedCharacter: controller.selectedCharacter.value,
        mathPromptWidget: mathWidget,
      );
    });
  }

  Widget _buildCharacterOptions() {
    return Obx(() {
      if (controller.isMathCurrent) return const SizedBox.shrink();
      final forms = controller.characterVowelFormsList;
      if (forms.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double padH = 12;
              const double audioBtnW = 140;
              const double gapToAudio = 12;

              final availableW = (constraints.maxWidth - audioBtnW - gapToAudio)
                  .clamp(0.0, constraints.maxWidth);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: availableW),
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: padH,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: forms.map((char) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      char,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
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
                                    decoration: const BoxDecoration(
                                      color: AppColors.buttonSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap:
                                          controller.playCurrentCharacterAudio,
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
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildBottomButtons() {
    Widget buildActionButton({
      required VoidCallback? onTap,
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
              fg: Colors.red.shade400,
              icon: Icons.delete,
              label: "delete".tr,
              borderColor: Colors.pink.shade200,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final enabled = controller.canSkip;
              return buildActionButton(
                onTap: enabled ? controller.skipCurrentExercise : null,
                bg: enabled
                    ? AppColors.buttonPrimary
                    : AppColors.buttonPrimary.withValues(alpha: 0.55),
                fg: Colors.white.withValues(alpha: enabled ? 1.0 : 0.65),
                icon: Icons.skip_next,
                label: "skip".tr,
              );
            }),
          ),
        ],
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
            controller.isSubmitting.value = true;
            try {
              controller.clearBoard();
              controller.attempts.clear();
              final levelController = Get.find<LevelController>();
              await levelController.fetchLevelDetail();
              final level = levelController.currentLevel.value;
              if (level == null || level.id != controller.levelId) {
                AppSnackbar.show(
                  title: 'error'.tr,
                  'Failed to load level'.tr,
                  backgroundColor: Colors.red,
                );
                return;
              }
              final levelRoute = RouteBuilder.build(AppRoutes.level, {
                'worldId': controller.worldId.toString(),
                'levelId': controller.levelId.toString(),
              });
              Get.offAllNamed(levelRoute);
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
