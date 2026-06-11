import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/board_grid_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/letter_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/morph_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_drawing_board.dart';

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
                          Color(0xFF2B7A78).withValues(alpha: 1),
                          Color(0xFF6B9F8E).withValues(alpha: 0.0),
                          // Color(0xFF8FB99F).withValues(alpha: 0.0),
                        ],
                        stops: [0.15, 0.45],
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
                            _buildTopBar(Get.context!),
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
                                          _buildIllustration(),
                                          SizedBox(height: 0),
                                        ],
                                      )
                                    : const SizedBox(key: ValueKey('no_illus')),
                              );
                            }),
                            Obx(
                              () => controller.showIllustration
                                  ? const SizedBox.shrink()
                                  : const SizedBox(height: 20),
                            ),
                            _buildDrawingBoard(showShadowGuide: !controller.isMathCurrent),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Obx(() {
              Widget avatarContent = Image.asset(
                'assets/images/illustrations/pencil.png',
                fit: BoxFit.contain,
              );

              if (Get.isRegistered<HomeController>()) {
                final homeController = Get.find<HomeController>();
                final shopAvatar = homeController.currentShopAvatar;

                if (shopAvatar != null && shopAvatar.id != 'default') {
                  if (shopAvatar.assetPath != null) {
                    avatarContent = Padding(
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        shopAvatar.assetPath!,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    avatarContent = Icon(
                      shopAvatar.icon ?? Icons.person,
                      size: 28,
                      color: Colors.white,
                    );
                  }
                }
              }

              return avatarContent;
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Obx(() {
                  final total = controller.totalExercises;
                  final dotStates = controller.exerciseDotStates;
                  final reqs = <int>[];
                  if (total >= 3) {
                    reqs.add((total / 3).ceil());
                    reqs.add((total * 2 / 3).ceil());
                    reqs.add(total);
                  } else {
                    for (int i = 1; i <= total; i++) {
                      reqs.add(i);
                    }
                  }

                  int correctCount = 0;
                  final starPositions = <int>{};

                  for (int i = 0; i < controller.completedExercises; i++) {
                    if (dotStates[i] == StarState.correct) {
                      correctCount++;
                      if (reqs.contains(correctCount)) {
                        starPositions.add(i);
                      }
                    }
                  }

                  for (final r in reqs) {
                    if (r > correctCount) {
                      final needed = r - correctCount;
                      final pos = controller.completedExercises + needed - 1;
                      if (pos < total) {
                        starPositions.add(pos);
                      }
                    }
                  }

                  return LayoutBuilder(
                    builder: (context, cst) {
                      final w = cst.maxWidth;
                      final h = cst.maxHeight;

                      const barHeight = 12.0;
                      const dotSize = 18.0;
                      const starSize = 38.0;

                      final barTop = (h - barHeight) / 2;
                      final dotTop = barTop + (barHeight / 2) - (dotSize / 2);
                      final starTop = barTop + (barHeight / 2) - (starSize / 2);

                      // Position items evenly across the bar.
                      final positions = <double>[];
                      if (total > 0) {
                        for (int i = 0; i < total; i++) {
                          final t = (i + 0.5) / total;
                          positions.add(t * w);
                        }
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Items (dots or stars).
                          for (int i = 0; i < total; i++)
                            () {
                              final isStar = starPositions.contains(i);

                              // Determine exercise state.
                              final state = i < dotStates.length
                                  ? dotStates[i]
                                  : StarState.pending;

                              // Star position: show Lottie star if pending or correct.
                              if (isStar && state != StarState.wrong) {
                                final asset = state == StarState.correct
                                    ? 'assets/animated/star.json'
                                    : 'assets/animated/star_border.json';

                                return Positioned(
                                  left: (positions[i] - starSize / 2).clamp(
                                    0.0,
                                    w - starSize,
                                  ),
                                  top: starTop,
                                  child: SizedBox(
                                    width: starSize,
                                    height: starSize,
                                    child: Lottie.asset(
                                      asset,
                                      repeat: false,
                                      animate: state == StarState.correct,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              }

                              // Regular dot.
                              Color fill;
                              Color border;
                              switch (state) {
                                case StarState.correct:
                                  fill = AppColors.buttonPrimary;
                                  border = Colors.white;
                                  break;
                                case StarState.wrong:
                                  fill = Colors.redAccent;
                                  border = Colors.white;
                                  break;
                                default:
                                  fill = Colors.grey.shade300;
                                  border = Colors.grey.shade400;
                              }

                              return Positioned(
                                left: (positions[i] - dotSize / 2).clamp(
                                  0.0,
                                  w - dotSize,
                                ),
                                top: dotTop,
                                child: Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: fill,
                                    border: Border.all(color: border, width: 2),
                                  ),
                                ),
                              );
                            }(),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: () => _showPauseDialog(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white60,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause,
                color: AppColors.buttonPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isMathCurrent) {
                final raw = controller.mathPrompt.value;
                final km = NumberFormatUtils.digitsByLocale(
                  raw,
                  forceKhmer: true,
                );

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        km,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final path = controller.anim.illustrationAssetPath.value;
              final ch = controller.selectedCharacter.value;
              final digit = NumberFormatUtils.parseSingleDigitAny(ch);

              if (digit != null) {
                final count = digit == 0 ? 1 : digit;

                double itemSize;
                if (count <= 4) {
                  itemSize = 64;
                } else {
                  itemSize = 52;
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
                                child: Container(
                                  width: itemSize,
                                  height: itemSize,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: path.isEmpty
                                        ? const SizedBox.shrink()
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
                                  child: Container(
                                    width: itemSize,
                                    height: itemSize,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: path.isEmpty
                                          ? const SizedBox.shrink()
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: path.isEmpty
                        ? const SizedBox.shrink()
                        : Image.asset(
                            path,
                            fit: BoxFit.contain,
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
            if (controller.isMathCurrent) return const SizedBox.shrink();

            final ch = controller.selectedCharacter.value;
            final digit = NumberFormatUtils.parseSingleDigitAny(ch);
            if (digit != null) return const SizedBox.shrink();

            final label = controller.anim.illustrationLabel.value;
            if (label.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildDrawingBoard({bool showShadowGuide = true}) {
    return Obx(() {
      final showGuide = showShadowGuide && !controller.isMathCurrent;
      return StageDrawingBoard(
        boardWidth: controller.boardWidth.value,
        boardHeight: controller.boardHeight.value,
        onUpdateBoardSize: controller.updateBoardSize,
        drawingControllers: controller.drawingControllers,
        letterSubpathsNorm: controller.letterSubpathsNorm,
        scale: controller.scale,
        onPointerDown: controller.onRawPointerDown,
        onPointerMove: controller.onRawPointerMove,
        onPointerUp: controller.onRawPointerUp,
        attemptLeft: controller.attemptLeft.value,
        maxAttempts: StageController.maxAttemptsPerExercise,
        feedbackState: controller.anim.feedback.value,
        praiseFeedbackState: controller.anim.praiseFeedback.value,
        shakeOffset: controller.anim.shakeOffset.value,
        praiseText: controller.anim.praiseText.value,
        confettiController: controller.anim.confettiController,
        guideCirclePx: controller.anim.guideCirclePx.value,
        isGuiding: controller.anim.isGuiding.value && showGuide,
        showGuiding: showGuide,
        activeBoardCount: controller.activeBoardCount,
        showMorph: controller.anim.showMorph.value,
        morphProgress: controller.anim.morphProgress.value,
        userMorphStrokes: controller.anim.userMorphStrokes,
        templateMorphStrokes: controller.anim.templateMorphStrokes,
        stampImage: controller.currentStampImage,
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
                            duration: Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isPlaying)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.9, end: 1.2),
                                    duration: Duration(milliseconds: 500),
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
                                      color: AppColors.buttonSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap:
                                          controller.playCurrentCharacterAudio,
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: Duration(milliseconds: 200),
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
          onTap: onTap, // ✅ null disables taps
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
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFFFFBF3), const Color(0xFFFFF4E1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade200,
                          Colors.orange.shade500,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 22),

                  Container(
                    width: 56,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  SizedBox(height: 22),

                  Row(
                    children: [
                      // Home Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(
                                color: Colors.blue.shade100,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();

                            controller.isSubmitting.value = true;

                            try {
                              controller.clearBoard();
                              controller.attempts.clear();

                              final levelController =
                                  Get.find<LevelController>();
                              await levelController.fetchLevelDetail();

                              final level = levelController.currentLevel.value;

                              if (level == null ||
                                  level.id != controller.levelId) {
                                AppSnackbar.show(
                                  title: 'error'.tr,
                                  'Failed to load level'.tr,
                                  backgroundColor: Colors.red,
                                );
                                return;
                              }

                              final levelRoute =
                                  RouteBuilder.build(AppRoutes.level, {
                                    'worldId': controller.worldId.toString(),
                                    'levelId': controller.levelId.toString(),
                                  });

                              Get.offAllNamed(levelRoute);
                            } finally {
                              controller.isSubmitting.value = false;
                            }
                          },
                          child: const Icon(Icons.home_rounded, size: 34),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(
                                color: Colors.orange.shade200,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await controller.resetForRetry();
                          },
                          child: const Icon(Icons.refresh_rounded, size: 34),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Resume Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: const Icon(Icons.play_arrow_rounded, size: 34),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
