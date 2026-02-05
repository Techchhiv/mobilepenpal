import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
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
                      Obx(() {
                        final show = controller.showIllustration;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => SizeTransition(
                            sizeFactor: anim,
                            axisAlignment: -1.0,
                            child: child,
                          ),
                          child: show
                              ? Column(
                                  key: const ValueKey('illus'),
                                  children: [
                                    _buildIllustration(),
                                    const SizedBox(height: 30),
                                  ],
                                )
                              : const SizedBox(key: ValueKey('no_illus')),
                        );
                      }),
                      Obx(
                        () => controller.showIllustration
                            ? const SizedBox.shrink()
                            : const Spacer(),
                      ),
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
      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
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
                  final progress = (total <= 0)
                      ? 0.0
                      : controller.stageProgress.value.clamp(0.0, 1.0);

                  final starStates = controller.progressStarStates;
                  final animIndex = controller.progressAnimatingStarIndex.value;
                  final scale = controller.progressStarScale.value;

                  return LayoutBuilder(
                    builder: (context, cst) {
                      final w = cst.maxWidth;
                      final h = cst.maxHeight;

                      const starSize = 48.0;
                      const barHeight = 12.0;

                      final barTop = (h - barHeight) / 2;
                      final starTop = barTop + (barHeight / 2) - (starSize / 2);

                      const thresholds = <double>[0.33, 0.66, 1.0];

                      // ✅ Use "usable width" so star centers align with progress fill
                      final usable = (w - starSize).clamp(0.0, w);
                      final centers = thresholds
                          .map((t) => (starSize / 2) + t * usable)
                          .toList();

                      String assetFor(StarState st) {
                        switch (st) {
                          case StarState.correct:
                            return 'assets/animated/star.json';
                          case StarState.wrong:
                            return 'assets/animated/star_red.json';
                          case StarState.pending:
                          default:
                            return 'assets/animated/star_border.json';
                        }
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: barTop,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: barHeight,
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.buttonPrimary,
                                ),
                              ),
                            ),
                          ),

                          for (int i = 0; i < 3; i++)
                            Positioned(
                              left: (centers[i] - starSize / 2).clamp(
                                0.0,
                                w - starSize,
                              ),
                              top: starTop,
                              child: AnimatedScale(
                                scale: (animIndex == i) ? scale : 1.0,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutBack,
                                child: SizedBox(
                                  width: starSize,
                                  height: starSize,
                                  child: Lottie.asset(
                                    assetFor(starStates[i]),
                                    repeat: false,
                                    // ✅ Prevent pending from auto-playing into a "yellow" frame
                                    animate:
                                        (animIndex == i) ||
                                        (starStates[i] != StarState.pending),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
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
              width: 40,
              height: 40,
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: itemSize,
                                    height: itemSize,
                                    child: path.isEmpty
                                        ? SizedBox.shrink()
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
                                    child: SizedBox(
                                      width: itemSize,
                                      height: itemSize,
                                      child: path.isEmpty
                                          ? SizedBox.shrink()
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
                    color: AppColors.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: path.isEmpty
                        ? SizedBox.shrink()
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
            final ch = controller.selectedCharacter.value;
            final digit = NumberFormatUtils.parseSingleDigitAny(ch);
            if (digit != null) return const SizedBox.shrink();

            final label = controller.anim.illustrationLabel.value;
            if (label.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
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

                          return SizedBox(
                            width: controller.boardWidth,
                            height: controller.boardHeight,
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
              fg: Colors.red.shade400,
              icon: Icons.delete,
              label: "delete".tr,
              borderColor: Colors.pink.shade200,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: buildActionButton(
              onTap: controller.skipCurrentExercise,
              bg: AppColors.buttonPrimary,
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

                              Get.offNamed(levelRoute);
                            } finally {
                              controller.isSubmitting.value = false;
                            }
                          },
                          child: const Icon(Icons.home_rounded, size: 34),
                        ),
                      ),
                      const SizedBox(width: 12),
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
