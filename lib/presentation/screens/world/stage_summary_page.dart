import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/controllers/world/stage_summary_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class StageSummaryPage extends StatefulWidget {
  const StageSummaryPage({super.key});

  @override
  State<StageSummaryPage> createState() => _StageSummaryPageState();
}

class _StageSummaryPageState extends State<StageSummaryPage>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _waveController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _scaleAnimation;

  final StageSummaryController controller = Get.find<StageSummaryController>();

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _floatAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (controller.isContinuing.value) return;

          controller.goBackToLevel();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: LoadingOverlay(
            isLoading: controller.isContinuing.value,
            child: Stack(
              children: [
                // 1. Mascot Image in background (behind wave)
                Positioned.fill(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Expanded(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Image.asset(
                              'assets/images/illustrations/summary_page_bg.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 160),
                    ],
                  ),
                ),

                // 2. Main foreground animated wave layer (in front of image)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return ClipPath(
                        clipper: AnimatedStageWaveClipper(
                          waveProgress: _waveController.value,
                          frequency: 1.0,
                          amplitudeFactor: 0.06,
                          baseHeightFactor: 0.35,
                        ),
                        child: Container(color: const Color(0xFF0C7365)),
                      );
                    },
                  ),
                ),

                // 4. Main Foreground UI Layout (Header, Stars, Buttons)
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.globalMaxWidth,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildHeaderTitle(),
                          const Spacer(),
                          _buildStarDisplay(),
                          const SizedBox(height: 32),
                          _buildBottomButtons(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderTitle() {
    final msgKey = _encouragementKey(
      stars: controller.starsEarned,
      correct: controller.correctAnswers,
      total: controller.totalQuestions,
    );

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          msgKey.tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C7365),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(StageSummaryController.maxStars, (index) {
        final isEarned = index < controller.starsEarned;
        final isMiddle = index == 1;

        final dy = isMiddle ? -24.0 : 0.0;
        final starSize = isMiddle ? 105.0 : 85.0;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: starSize,
              height: starSize,
              child: Lottie.asset(
                isEarned
                    ? 'assets/animated/star.json'
                    : 'assets/animated/star_border.json',
                controller: isEarned ? controller.starControllers[index] : null,
                onLoaded: isEarned
                    ? (composition) {
                        controller.starControllers[index].duration =
                            composition.duration;
                      }
                    : null,
                repeat: false,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // Retry circular pill button
          GestureDetector(
            onTap: controller.retryStage,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.rotate_left_rounded,
                  color: Color(0xFF4B5563),
                  size: 32,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Primary Continue pill button
          Expanded(
            child: GestureDetector(
              onTap: controller.continueNext,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'continue'.tr,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF1F2937),
                      size: 28,
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

  String _encouragementKey({
    required int stars,
    required int correct,
    required int total,
  }) {
    if (total <= 0) return 'summary_good_try';
    final accuracy = correct / total;
    if (stars >= 3 || accuracy >= 0.999) return 'summary_perfect';
    if (stars == 2 || accuracy >= 0.50) return 'summary_great';
    return 'summary_good_try';
  }
}

class AnimatedStageWaveClipper extends CustomClipper<Path> {
  final double waveProgress;
  final double frequency;
  final double amplitudeFactor;
  final double baseHeightFactor;

  AnimatedStageWaveClipper({
    required this.waveProgress,
    this.frequency = 1.0,
    this.amplitudeFactor = 0.06,
    this.baseHeightFactor = 0.25,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    final baseHeight = h * baseHeightFactor;
    final amplitude = h * amplitudeFactor;

    path.moveTo(
      0,
      baseHeight + amplitude * math.sin(waveProgress * 2 * math.pi),
    );

    for (double x = 0; x <= w; x += 4) {
      final relativeX = x / w;
      final y =
          baseHeight +
          amplitude *
              math.sin(
                (relativeX * frequency * 2 * math.pi) +
                    (waveProgress * 2 * math.pi),
              );
      path.lineTo(x, y);
    }

    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(AnimatedStageWaveClipper oldClipper) =>
      oldClipper.waveProgress != waveProgress ||
      oldClipper.frequency != frequency ||
      oldClipper.amplitudeFactor != amplitudeFactor ||
      oldClipper.baseHeightFactor != baseHeightFactor;
}
