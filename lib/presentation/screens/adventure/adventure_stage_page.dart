import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_stage_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/math_fruit_display.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_drawing_board.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_illustration.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_top_bar.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_pause_dialog.dart';

class AdventureStagePage extends GetView<AdventureStageController> {
  const AdventureStagePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<AdventureStageController>()) {
        return;
      }
      Get.find<AdventureStageController>().playDeferredInitialAudioIfNeeded();
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Get.isDialogOpen == true) return;
        _showPauseDialog(context);
      },
      child: Scaffold(
        body: Obx(
          () {
            if (!Get.isRegistered<AdventureStageController>()) {
              return const SizedBox.shrink();
            }
            return LoadingOverlay(
            isLoading:
                controller.isLoading.value || controller.isSubmitting.value,
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
                            Obx(() {
                              Widget? avatarWidget;
                              if (Get.isRegistered<HomeController>()) {
                                final homeController = Get.find<HomeController>();
                                final ShopAvatar? shopAvatar =
                                    homeController.currentShopAvatar;

                                if (shopAvatar != null &&
                                    shopAvatar.id != 'default') {
                                  if (shopAvatar.assetPath != null) {
                                    avatarWidget = Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        shopAvatar.assetPath!,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  } else {
                                    avatarWidget = Icon(
                                      shopAvatar.icon ?? Icons.person,
                                      size: 28,
                                      color: Colors.white,
                                    );
                                  }
                                } else {
                                  avatarWidget = const Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.white,
                                  );
                                }
                              }

                              return StageTopBar(
                                totalExercises: controller.totalExercises,
                                completedExercises:
                                    controller.completedExercises,
                                exerciseDotStates: controller.exerciseDotStates
                                    .toList(),
                                onActionTap: () => _showPauseDialog(context),
                                actionIcon: Icons.pause,
                                avatarWidget: avatarWidget,
                              );
                            }),
                            const SizedBox(height: 24),
                            Obx(() {
                              if (!controller.showIllustration) {
                                return const SizedBox(
                                  key: ValueKey('no_illus'),
                                  height: 20,
                                );
                              }
                              return Column(
                                key: const ValueKey('illus'),
                                children: [
                                  Builder(
                                    builder: (_) {
                                      Widget? mathWidget;
                                      if (controller.isMathCurrent) {
                                        mathWidget = MathFruitDisplay(
                                          prompt: controller.mathPrompt.value,
                                        );
                                      }
                                      return StageIllustration(
                                        illustrationAssetPath: controller
                                            .anim
                                            .illustrationAssetPath
                                            .value,
                                        illustrationLabel: controller
                                            .anim
                                            .illustrationLabel
                                            .value,
                                        selectedCharacter:
                                            controller.selectedCharacter.value,
                                        mathPromptWidget: mathWidget,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 0),
                                ],
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
                                    AdventureStageController
                                        .maxAttemptsPerExercise,
                                feedbackState:
                                    controller.anim.feedback.value,
                                praiseFeedbackState:
                                    controller.anim.praiseFeedback.value,
                                shakeOffset:
                                    controller.anim.shakeOffset.value,
                                praiseText: controller.anim.praiseText.value,
                                confettiController:
                                    controller.anim.confettiController,
                                guideCirclePx:
                                    controller.anim.guideCirclePx.value,
                                isGuiding:
                                    controller.anim.isGuiding.value,
                                showGuiding: true,
                                activeBoardCount:
                                    controller.activeBoardCount,
                                topLeadingOverlay:
                                    _buildBoardRewardOverlay(),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildCharacterOptions(),
                            const SizedBox(height: 24),
                            _buildBottomButtons(),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildCharacterOptions() {
    return Obx(() {
      if (controller.isMathCurrent) return const SizedBox.shrink();
      final forms = controller.characterVowelFormsList;
      if (forms.isEmpty) return const SizedBox.shrink();
      const sideSlotWidth = 54.0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: sideSlotWidth),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 10),
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
              const SizedBox(width: 12),
              SizedBox(
                width: sideSlotWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildAudioButton(),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBoardRewardOverlay() {
    return Obx(() {
      if (controller.isAlreadyCompleted.value) {
        return const SizedBox.shrink();
      }
      return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color:  Color(0xFFF9F3E7).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFFFD79A).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildXpCounter(),
          const SizedBox(width: 6),
          _buildCoinCounter(),
        ],
      ),
    );
    });
  }

  Widget _buildAudioButton() {
    return Obx(() {
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
                              border: Border.all(color: Colors.white, width: 2),
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
                      onTap: controller.playCurrentCharacterAudio,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (c, anim) =>
                              ScaleTransition(scale: anim, child: c),
                          child: Icon(
                            isPlaying ? Icons.graphic_eq : Icons.volume_up,
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

  Widget _buildCoinCounter() {
    return _buildRewardStatChip(
      accentColor: Color(0xFFF4B400),
      value: Obx(
        () => Text(
          NumberFormatUtils.intText(controller.earnedCoins.value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade900,
          ),
        ),
      ),
      icon: Obx(() {
        final trigger = controller.triggerCoinAnim.value;
        return _FloatingCoinAnimation(trigger: trigger);
      }),
    );
  }

  Widget _buildXpCounter() {
    return _buildRewardStatChip(
      accentColor: Color(0xFFFF8A3D),
      value: Obx(
        () => Text(
          NumberFormatUtils.intText(controller.earnedXp.value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade900,
          ),
        ),
      ),
      icon: Obx(() {
        final trigger = controller.triggerXpAnim.value;
        return _PulseXpAnimation(trigger: trigger);
      }),
    );
  }

  Widget _buildRewardStatChip({
    required Color accentColor,
    required Widget value,
    required Widget icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 25),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          value,
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
          onHome: () {
            Get.back();
            Get.back();
          },
          onResume: () => Get.back(),
        );
      },
    );
  }
}

class _FloatingCoinAnimation extends StatefulWidget {
  final int trigger;
  const _FloatingCoinAnimation({super.key, required this.trigger});

  @override
  State<_FloatingCoinAnimation> createState() => _FloatingCoinAnimationState();
}

class _FloatingCoinAnimationState extends State<_FloatingCoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _yAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -14,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -14,
          end: 0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_ctrl);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0),
        weight: 50,
      ),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_FloatingCoinAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yAnim.value),
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle, color: Colors.yellow.shade700, size: 20),
          const Icon(Icons.attach_money, color: Colors.white, size: 13),
        ],
      ),
    );
  }
}

class _PulseXpAnimation extends StatefulWidget {
  final int trigger;

  const _PulseXpAnimation({super.key, required this.trigger});

  @override
  State<_PulseXpAnimation> createState() => _PulseXpAnimationState();
}

class _PulseXpAnimationState extends State<_PulseXpAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.24,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.24,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_PulseXpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFC46B), Color(0xFFFF8A3D)],
          ),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
      ),
    );
  }
}
