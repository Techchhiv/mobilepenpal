import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/ai_writing/ai_writing_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/widgets/world/board_grid_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/letter_painter.dart';

class AiWritingPracticePage extends StatefulWidget {
  const AiWritingPracticePage({
    super.key,
    required this.characters,
    required this.repeatCount,
  });

  final List<String> characters;
  final int repeatCount;

  @override
  State<AiWritingPracticePage> createState() => _AiWritingPracticePageState();
}

class _AiWritingPracticePageState extends State<AiWritingPracticePage> {
  late final AiWritingController _controller;
  late final ConfettiController _confettiCtrl;

  // ── Theme helpers ──────────────────────────────────────────────────────
  bool get _isStudent {
    try {
      final h = Get.find<HomeController>();
      return h.currentMode.value == 'student';
    } catch (_) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _controller = Get.put(
      AiWritingController(
        characters: widget.characters,
        repeatCount: widget.repeatCount,
      ),
    );
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    Get.delete<AiWritingController>();
    super.dispose();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              'great_job'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Text(
          'You practiced ${widget.characters.length} character(s) × ${widget.repeatCount} time(s)!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Get.back(); // back to selection page
            },
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text(
              'Done',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('leave_practice'.tr),
        content: Text('leave_practice_desc'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('leave'.tr,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final isStudent = _isStudent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isStudent
                  ? const [
                      Color(0xFFF3FBFF),
                      Color(0xFFF7F8FF),
                      Color(0xFFFFF7F2),
                    ]
                  : const [
                      AppColors.primary,
                      Color(0xFF1e8c79),
                      Color(0xFF49aa7c),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopHeaderRow(homeController, isStudent),
                    _buildInstructionAndGuideRow(),
                    const SizedBox(height: 8),
                    _buildDrawingArea(isStudent),
                    _buildHintRow(isStudent),
                    const SizedBox(height: 8),
                    _buildActionButtons(isStudent),
                    const SizedBox(height: 20),
                  ],
                ),

                // Confetti overlay
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiCtrl,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    numberOfParticles: 30,
                    gravity: 0.15,
                    emissionFrequency: 0.06,
                    colors: const [
                      Color(0xFF2EC4B6),
                      Color(0xFFF59E0B),
                      Color(0xFFEF4444),
                      Color(0xFF8B5CF6),
                      Color(0xFF10B981),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header Row ─────────────────────────────────────────────────────────
  Widget _buildTopHeaderRow(HomeController homeController, bool isStudent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircularAvatar(homeController),
          _buildProgressCapsule(),
          _buildPauseButton(isStudent),
        ],
      ),
    );
  }

  Widget _buildCircularAvatar(HomeController homeController) {
    return Obx(() {
      final ShopAvatar? shopAvatar = homeController.currentShopAvatar;
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: shopAvatar != null && shopAvatar.id != 'default' && shopAvatar.assetPath != null
              ? Image.asset(shopAvatar.assetPath!, fit: BoxFit.cover)
              : const Icon(Icons.person, size: 28, color: Colors.grey),
        ),
      );
    });
  }

  Widget _buildProgressCapsule() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _controller.currentChar,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${'repetition'.tr} ${_controller.rep.value + 1}/${widget.repeatCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (_controller.rep.value + 1) / widget.repeatCount,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildPauseButton(bool isStudent) {
    return IconButton(
      onPressed: () async {
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Get.back();
      },
      icon: Icon(
        Icons.pause_rounded,
        color: isStudent ? const Color(0xFF1E293B) : Colors.white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: isStudent ? Colors.white : Colors.white.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(12),
        shape: const CircleBorder(),
        shadowColor: Colors.black.withValues(alpha: 0.1),
        elevation: isStudent ? 2 : 0,
      ),
    );
  }

  // ── Instruction & Guide Row ────────────────────────────────────────────
  Widget _buildInstructionAndGuideRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'writing_practice_instruction'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'draw_carefully'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: BoardGridPainter(),
                      ),
                    ),
                  ),
                  Obx(() {
                    final paths = _controller.miniGuidePaths;
                    if (paths.isEmpty) return const SizedBox.shrink();
                    final guideCircle = _controller.guideCirclePx.value;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: LetterPointsPainter(
                                letterSubpathsNorm: paths,
                                toBoardPx: (o) => o,
                                fillEnabled: true,
                                strokeEnabled: true,
                                fillOpacity: 0.2,
                                strokeOpacity: 0.35,
                                strokeWidth: 4.0,
                              ),
                            ),
                          ),
                        ),
                        if (guideCircle != null)
                          Positioned(
                            left: guideCircle.dx - 6,
                            top: guideCircle.dy - 6,
                            child: IgnorePointer(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Blank Canvas ───────────────────────────────────────────────────────
  Widget _buildDrawingArea(bool isStudent) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Expanded(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight;

              if ((_controller.canvasSize - size).abs() > 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.canvasSize = size;
                });
              }

              final feedback = _controller.feedbackState.value;
              final shakeOffset = _controller.shakeOffset.value;

              double scaleVal = 1.0;
              if (feedback == DrawFeedback.correct) {
                scaleVal = 1.05;
              } else if (feedback == DrawFeedback.wrong) {
                scaleVal = 1.06;
              }

              return Center(
                child: AnimatedScale(
                  scale: scaleVal,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Transform.translate(
                    offset: Offset(feedback == DrawFeedback.wrong ? shakeOffset : 0, 0),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: BoardGridPainter(),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Obx(() => AbsorbPointer(
                                absorbing: _controller.isSubmitting.value ||
                                    _controller.feedbackState.value != DrawFeedback.none,
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: _controller.onPointerDown,
                                  onPointerMove: _controller.onPointerMove,
                                  onPointerUp: _controller.onPointerUp,
                                  child: DrawingBoard(
                                    boardPanEnabled: false,
                                    boardScaleEnabled: false,
                                    controller: _controller.drawingController,
                                    background: SizedBox(
                                      width: size,
                                      height: size,
                                    ),
                                  ),
                                ),
                              )),
                            ),

                            // Overlay Lottie + Praise Bubble for children feedback
                            Obx(() {
                              final f = _controller.feedbackState.value;
                              final txt = _controller.praiseText.value;
                              if (f == DrawFeedback.none || txt.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final isCorrect = f == DrawFeedback.correct;

                              return Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          height: 140,
                                          child: Lottie.asset(
                                            isCorrect
                                                ? 'assets/animated/star.json'
                                                : 'assets/animated/star_red.json',
                                            repeat: false,
                                            animate: true,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        AnimatedScale(
                                          scale: 1.0,
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.elasticOut,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCorrect
                                                  ? Colors.yellow.shade700
                                                  : Colors.redAccent,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              txt,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // ── Hint Row ───────────────────────────────────────────────────────────
  Widget _buildHintRow(bool isStudent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              Get.snackbar(
                'hint'.tr,
                'hint_coming_soon'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                colorText: const Color(0xFF1E293B),
                boxShadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              );
            },
            icon: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.amber,
              size: 20,
            ),
            label: Text(
              'hint'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer Row ─────────────────────────────────────────────────────────
  Widget _buildActionButtons(bool isStudent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              label: 'clear'.tr,
              icon: Icons.delete_outline_rounded,
              isStudent: isStudent,
              isPrimary: false,
              onTap: _controller.clearBoard,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() => _ActionBtn(
              label: (_controller.charIndex.value == widget.characters.length - 1 &&
                      _controller.rep.value == widget.repeatCount - 1)
                  ? 'finish'.tr
                  : 'next'.tr,
              icon: (_controller.charIndex.value == widget.characters.length - 1 &&
                      _controller.rep.value == widget.repeatCount - 1)
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              isStudent: isStudent,
              isPrimary: true,
              isLoading: _controller.isSubmitting.value,
              onTap: _controller.isSubmitting.value
                  ? () {}
                  : () => _controller.checkDrawingAndSubmit(() {
                        _confettiCtrl.play();
                        _showCompletionDialog();
                      }),
            )),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.isStudent,
    required this.isPrimary,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final bool isStudent;
  final bool isPrimary;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (isPrimary) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else {
      bg = isStudent
          ? Colors.white
          : Colors.white.withValues(alpha: 0.12);
      fg = isStudent ? const Color(0xFF475569) : Colors.white;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      elevation: isPrimary ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isLoading
                ? [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ]
                : [
                    Icon(icon, color: fg, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
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
}
